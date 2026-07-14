{
  config,
  lib,
  pkgs,
  ...
}: let
  domains = import ./domains.nix;
  accounts = import ./accounts.nix;
  sanitize = value: lib.replaceStrings ["@" "."] ["-" "-"] value;
  passwordSecretName = address: "password-${sanitize address}";
  sqlEscape = value: lib.replaceStrings ["'"] ["''"] value;
  dbUrl = table: "mysql://sogo:SOGO_DB_PASSWORD@127.0.0.1:3306/sogo/${table}";

  accountRows = lib.concatStringsSep "\n" (lib.mapAttrsToList (address: metadata: let
      domain = lib.last (lib.splitString "@" address);
      aliases = lib.concatStringsSep " " (metadata.aliases or []);
    in ''
      INSERT INTO accounts (
        c_uid, domain, c_name, c_password, c_cn, mail, aliases,
        ad_aliases, ext_acl, kind, multiple_bookings
      ) VALUES (
        '${sqlEscape address}', '${sqlEscape domain}', '${sqlEscape address}', CONCAT(),
        '${sqlEscape metadata.displayName}', '${sqlEscape address}', '${sqlEscape aliases}',
        CONCAT(), CONCAT(), CONCAT(), -1
      ) ON DUPLICATE KEY UPDATE
        domain = VALUES(domain), c_name = VALUES(c_name), c_cn = VALUES(c_cn),
        mail = VALUES(mail), aliases = VALUES(aliases);
    '')
    accounts);

  passwordUpdates = lib.concatStringsSep "\n" (lib.mapAttrsToList (address: _: ''
      hash=$(head -n 1 ${lib.escapeShellArg config.age.secrets.${passwordSecretName address}.path})
      hash="''${hash#\{*\}}"
      printf '%s\n' "UPDATE accounts SET c_password='$hash' WHERE c_uid='${sqlEscape address}';" \
        | ${lib.getExe' pkgs.mariadb "mariadb"} -u mysql sogo
    '')
    accounts);

  mkDomainConfig = domain: let
    algorithm =
      if domain == "chiritsu.com"
      then "SSHA256"
      else "BLF-CRYPT";
  in ''
    ${domain} = {
      SOGoMailDomain = "${domain}";
      SOGoUserSources = (
        {
          type = sql;
          id = "${domain}";
          displayName = "GAL ${domain}";
          viewURL = "${dbUrl "accounts"}";
          canAuthenticate = YES;
          isAddressBook = YES;
          userPasswordAlgorithm = "${algorithm}";
          prependPasswordScheme = YES;
          DomainFieldName = domain;
          MailFieldNames = (aliases, ad_aliases, ext_acl);
          KindFieldName = kind;
          MultipleBookingsFieldName = multiple_bookings;
          listRequiresDot = NO;
        }
      );
    };
  '';

  thunderbirdConfig = ''
    default_type application/xml;
    return 200 '<?xml version="1.0" encoding="UTF-8"?>
    <clientConfig version="1.1">
      <emailProvider id="scheers-mail">
        <domain>scheers.tech</domain>
        <displayName>Scheers Mail</displayName>
        <displayShortName>Scheers</displayShortName>
        <incomingServer type="imap">
          <hostname>m.scheers.tech</hostname>
          <port>993</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>
        <outgoingServer type="smtp">
          <hostname>m.scheers.tech</hostname>
          <port>465</port>
          <socketType>SSL</socketType>
          <authentication>password-cleartext</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
      </emailProvider>
    </clientConfig>';
  '';

  autoconfigVhosts = lib.listToAttrs (map (domain:
    lib.nameValuePair "autoconfig.${domain}" {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
        {
          addr = "[::]";
          port = 80;
        }
      ];
      locations."/mail/config-v1.1.xml".extraConfig = thunderbirdConfig;
    })
  domains);
in {
  networking.firewall.allowedTCPPorts = [80 443];

  age.secrets = {
    sogo-db-password = {
      file = ../../agenix/secrets/mail/sogo-db-password.age;
      owner = "root";
      group = "mysql";
      mode = "0440";
    };
    sogo-encryption-key = {
      file = ../../agenix/secrets/mail/sogo-encryption-key.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureDatabases = ["sogo"];
    ensureUsers = [
      {
        name = "sogo";
        ensurePermissions."sogo.*" = "ALL PRIVILEGES";
      }
    ];
    settings.mysqld = {
      bind-address = "127.0.0.1";
      character-set-server = "utf8mb4";
      collation-server = "utf8mb4_unicode_ci";
    };
  };

  users.users.mysql.extraGroups = ["mail-secrets"];

  systemd.services.sogo-database-setup = {
    description = "Create and synchronize the declarative SOGo account database";
    after = ["mysql.service" "agenix.service"];
    requires = ["mysql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "mysql";
      Group = "mysql";
    };
    script = ''
      set -euo pipefail
      db_password=$(tr -d '\n' < ${config.age.secrets.sogo-db-password.path})

      ${lib.getExe' pkgs.mariadb "mariadb"} -u mysql <<SQL
      ALTER USER 'sogo'@'localhost' IDENTIFIED BY '$db_password';
      GRANT ALL PRIVILEGES ON sogo.* TO 'sogo'@'localhost';
      FLUSH PRIVILEGES;
      SQL

      ${lib.getExe' pkgs.mariadb "mariadb"} -u mysql sogo <<'SQL'
      CREATE TABLE IF NOT EXISTS accounts (
        c_uid varchar(255) NOT NULL PRIMARY KEY,
        domain varchar(255) NOT NULL,
        c_name varchar(255) NOT NULL,
        c_password varchar(255) NOT NULL,
        c_cn varchar(255) NULL,
        mail varchar(255) NOT NULL,
        aliases text NOT NULL,
        ad_aliases varchar(6144) NOT NULL,
        ext_acl varchar(6144) NOT NULL,
        kind varchar(100) NOT NULL,
        multiple_bookings int NOT NULL DEFAULT -1,
        c_l varchar(255) NULL,
        c_o varchar(255) NULL,
        c_ou varchar(255) NULL,
        c_telephonenumber varchar(255) NULL,
        INDEX accounts_domain_idx (domain)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
      ${accountRows}
      SQL

      ${passwordUpdates}
    '';
  };

  services.memcached.enable = true;

  services.sogo = {
    enable = true;
    vhostName = "m.scheers.tech";
    timezone = "Europe/Brussels";
    language = "English";
    configReplaces = {
      SOGO_DB_PASSWORD = config.age.secrets.sogo-db-password.path;
      SOGO_ENCRYPTION_KEY = config.age.secrets.sogo-encryption-key.path;
    };
    extraConfig = ''
      WOPort = "127.0.0.1:20000";
      WOWorkersCount = 10;
      SOGoMemcachedHost = "127.0.0.1";
      SOGoEncryptionKey = "SOGO_ENCRYPTION_KEY";

      OCSAclURL = "${dbUrl "sogo_acl"}";
      OCSAdminURL = "${dbUrl "sogo_admin"}";
      OCSCacheFolderURL = "${dbUrl "sogo_cache_folder"}";
      OCSEMailAlarmsFolderURL = "${dbUrl "sogo_alarms_folder"}";
      OCSFolderInfoURL = "${dbUrl "sogo_folder_info"}";
      OCSSessionsFolderURL = "${dbUrl "sogo_sessions_folder"}";
      OCSStoreURL = "${dbUrl "sogo_store"}";
      SOGoProfileURL = "${dbUrl "sogo_user_profile"}";

      SOGoIMAPServer = "imap://127.0.0.1:143/?TLS=YES&tlsVerifyMode=none";
      SOGoSieveServer = "sieve://127.0.0.1:4190/?TLS=YES&tlsVerifyMode=none";
      SOGoSMTPServer = "smtp://127.0.0.1:587/?TLS=YES&tlsVerifyMode=none";
      SOGoSMTPAuthenticationType = plain;
      SOGoMailingMechanism = smtp;
      SOGoTrustProxyAuthentication = NO;
      SOGoPasswordChangeEnabled = NO;

      SOGoEnableDomainBasedUID = YES;
      domains = {
        ${lib.concatMapStringsSep "\n" mkDomainConfig domains}
      };

      SOGoCalendarDefaultRoles = (PublicViewer, ConfidentialDAndTViewer, PrivateDAndTViewer);
      SOGoACLsSendEMailNotifications = YES;
      SOGoAppointmentSendEMailNotifications = YES;
      SOGoDraftsFolderName = "Drafts";
      SOGoJunkFolderName = "Junk";
      SOGoSentFolderName = "Sent";
      SOGoTrashFolderName = "Trash";
      SOGoEnableEMailAlarms = YES;
      SOGoEnableMailCleaning = YES;
      SOGoEnablePublicAccess = YES;
      SOGoForwardEnabled = YES;
      SOGoMailAuxiliaryUserAccountsEnabled = YES;
      SOGoMailCustomFromEnabled = YES;
      SOGoSieveScriptsEnabled = YES;
      SOGoVacationEnabled = YES;
      SOGoEASSearchInBody = YES;
      SOGoFirstDayOfWeek = 1;
      SOGoMaximumSyncResponseSize = 512;
    '';
  };

  systemd.services.sogo = {
    after = ["sogo-database-setup.service" "dovecot.service" "postfix.service"];
    requires = ["sogo-database-setup.service"];
  };

  security.acme.certs."m.scheers.tech" = {
    webroot = "/var/lib/acme/acme-challenge";
    group = "nginx";
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    statusPage = true;
    virtualHosts =
      autoconfigVhosts
      // {
        "m.scheers.tech" = {
          serverAliases = ["mail.scheers.tech"];
          forceSSL = true;
          useACMEHost = "m.scheers.tech";
          locations = {
            "/.well-known/acme-challenge/".root = "/var/lib/acme/acme-challenge";
            "/.well-known/caldav".return = "301 https://m.scheers.tech/SOGo/dav";
            "/.well-known/carddav".return = "301 https://m.scheers.tech/SOGo/dav";
            "/Microsoft-Server-ActiveSync".extraConfig = ''
              proxy_pass http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_connect_timeout 75;
              proxy_send_timeout 3600;
              proxy_read_timeout 3600;
              proxy_buffer_size 128k;
              proxy_buffers 64 512k;
              proxy_busy_buffers_size 512k;
              client_body_buffer_size 512k;
              client_max_body_size 0;
            '';
          };
        };
      };
  };
}
