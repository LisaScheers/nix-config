{
  config,
  lib,
  pkgs,
  ...
}: let
  domains = import ./domains.nix;
  accountMetadata = import ./accounts.nix;
  sanitize = value: lib.replaceStrings ["@" "."] ["-" "-"] value;
  secretName = address: "password-${sanitize address}";
  dkimSecretName = domain: "dkim-${sanitize domain}";

  loginAccounts =
    lib.mapAttrs (address: metadata: {
      hashedPasswordFile = config.age.secrets.${secretName address}.path;
      aliases = metadata.aliases or [];
      catchAll = metadata.catchAll or [];
      quota = metadata.quota or null;
    })
    accountMetadata;

  passwordSecrets =
    lib.mapAttrs' (address: _: {
      name = secretName address;
      value = {
        file = ../../agenix/secrets/mail/${secretName address}.age;
        owner = "root";
        group = "mail-secrets";
        mode = "0440";
      };
    })
    accountMetadata;

  dkimSecrets = lib.genAttrs (map dkimSecretName domains) (name: {
    file = ../../agenix/secrets/mail/${name}.age;
    owner = "rspamd";
    group = "rspamd";
    mode = "0400";
  });

  dkimDomains = lib.genAttrs domains (domain: {
    selectors.dkim.keyFile = config.age.secrets.${dkimSecretName domain}.path;
  });

  senderOwners = lib.flatten (lib.mapAttrsToList (owner: metadata:
    map (sender: {
      inherit owner sender;
    }) ([owner] ++ (metadata.aliases or [])))
  accountMetadata);
  privilegedSender = "lisa@scheers.tech";
  exactSenderLines = map ({
    owner,
    sender,
  }: "/^${lib.escapeRegex sender}$/ ${lib.concatStringsSep "," (lib.unique [owner privilegedSender])}")
  senderOwners;
  senderLoginMap = pkgs.writeText "mail-sender-login-map" (lib.concatLines (
    exactSenderLines
    ++ [
      "/^.*@clovercri\\.com$/ info@clovercri.com,${privilegedSender}"
      "/^.*$/ ${privilegedSender}"
    ]
  ));
in {
  users.groups.mail-secrets = {};

  age.secrets =
    passwordSecrets
    // dkimSecrets
    // {
      app-passwords = {
        file = ../../agenix/secrets/mail/app-passwords.age;
        owner = "root";
        group = "dovecot2";
        mode = "0440";
      };
    };

  mailserver = {
    enable = true;
    stateVersion = 5;
    fqdn = "m.scheers.tech";
    sendingFqdn = "m.scheers.tech";
    systemDomain = "scheers.tech";
    systemName = "Scheers mail system";
    systemContact = "postmaster@scheers.tech";
    inherit domains;

    accounts = loginAccounts;
    quota.defaults.perUser = null;
    messageSizeLimit = 104857600;

    x509.useACMEHost = "m.scheers.tech";

    enableImap = true;
    enableImapSsl = true;
    enableSubmission = true;
    enableSubmissionSsl = true;
    enablePop3 = true;
    enablePop3Ssl = true;
    enableManageSieve = true;

    virusScanning = true;
    fullTextSearch = {
      enable = true;
      memoryLimit = 768;
      languages = ["en"];
    };
    indexDir = "/var/lib/dovecot/indices";

    dkim.domains = dkimDomains;
    dmarcReporting.enable = true;
    tlsrpt.enable = true;
    srs = {
      enable = true;
      domain = "scheers.tech";
    };
  };

  services.postfix = {
    mapFiles."sender-login-access" = senderLoginMap;
    submissionOptions.smtpd_sender_login_maps = lib.mkForce "pcre:/etc/postfix/sender-login-access";
    submissionsOptions.smtpd_sender_login_maps = lib.mkForce "pcre:/etc/postfix/sender-login-access";
  };

  services.rspamd.overrides."ratelimit.conf".text = ''
    whitelisted_rcpts = "postmaster,mailer-daemon";
    max_rcpt = 25;
    info_symbol = "RATELIMITED";
  '';

  environment.etc."dovecot/app-passwords.lua".text = ''
    local database = "${config.age.secrets.app-passwords.path}"

    local function access_allowed(request, imap, smtp, pop3, sieve)
      local service = request.service or ""
      if service == "imap" then return imap == "1" end
      if service == "smtp" or service == "submission" then return smtp == "1" end
      if service == "pop3" then return pop3 == "1" end
      if service == "sieve" or service == "managesieve" then return sieve == "1" end
      return false
    end

    function auth_password_verify(request, password)
      for line in io.lines(database) do
        local user, name, hash, imap, smtp, pop3, sieve =
          string.match(line, "^([^\t]+)\t([^\t]+)\t([^\t]+)\t([01])\t([01])\t([01])\t([01])$")

        if user == request.user and access_allowed(request, imap, smtp, pop3, sieve) then
          if request:password_verify(hash, password) then
            return dovecot.auth.PASSDB_RESULT_OK, {}
          end
        end
      end

      return dovecot.auth.PASSDB_RESULT_NEXT, {}
    end
  '';

  services.dovecot2.settings."passdb app-passwords" = {
    driver = "lua";
    lua_file = "/etc/dovecot/app-passwords.lua";
    use_worker = true;
    result_failure = "continue";
    result_internalfail = "continue";
    result_success = "return-ok";
  };

  services.fail2ban = {
    enable = true;
    bantime = "1h";
    maxretry = 5;
    bantime-increment = {
      enable = true;
      maxtime = "1w";
    };
    jails = {
      dovecot = {
        enabled = true;
        filter = "dovecot";
        settings = {
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=dovecot2.service";
          port = "pop3,pop3s,imap,imaps,submission,465,sieve";
        };
      };
      postfix-sasl = {
        enabled = true;
        filter = "postfix[mode=auth]";
        settings = {
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=postfix.service";
          port = "smtp,submission,465";
        };
      };
    };
  };
}
