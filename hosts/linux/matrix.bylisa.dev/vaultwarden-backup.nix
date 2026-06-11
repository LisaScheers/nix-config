let
  backupUser = "vaultwarden-backup";
  backupRoot = "/srv/backups/home-server/vaultwarden";
in {
  users.groups.${backupUser} = {};
  users.users.${backupUser} = {
    isSystemUser = true;
    group = backupUser;
    home = backupRoot;
    createHome = false;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0eCDvNT5lXqxITF43d8pF4481MavFbSnCE3DDMrMUp home-server vaultwarden restic backup"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${backupRoot} 0700 ${backupUser} ${backupUser} -"
  ];
}
