{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.clatd;

  settingsFormat = pkgs.formats.keyValue { };

  configFile = settingsFormat.generate "clatd.conf" cfg.settings;
in
{
  options = {
    services.clatd = {
      enable = lib.mkEnableOption "clatd";

      package = lib.mkPackageOption pkgs "clatd" { };

      enableNetworkManagerIntegration = lib.mkEnableOption "NetworkManager integration" // {
        default = config.networking.networkmanager.enable;
        defaultText = "config.networking.networkmanager.enable";
      };

      settings = lib.mkOption {
        type = lib.types.submodule (
          { name, ... }:
          {
            freeformType = settingsFormat.type;
          }
        );
        default = { };
        example = lib.literalExpression ''
          {
            plat-prefix = "64:ff9b::/96";
          }
        '';
        description = ''
          Configuration of clatd. See [clatd Documentation](https://github.com/toreanderson/clatd/blob/master/README.pod#configuration).
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.clatd = {
      description = "464XLAT CLAT daemon";
      documentation = [ "man:clatd(8)" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitIntervalSec = 0;

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/clatd -c ${configFile}";

        # Hardening
        CapabilityBoundingSet = [
          "CAP_NET_ADMIN"
        ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectProc = "invisible";
        ProtectSystem = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@network-io"
          "@system-service"
          "~@privileged"
          "~@resources"
        ];
      };
    };

    networking.networkmanager.dispatcherScripts = lib.optionals cfg.enableNetworkManagerIntegration [
      {
        type = "basic";
        # https://github.com/toreanderson/clatd/blob/master/scripts/clatd.networkmanager
        source = pkgs.writeShellScript "restart-clatd" ''
          [ "$DEVICE_IFACE" = "${cfg.settings.clat-dev or "clat"}" ] && exit 0
          [ "$2" != "up" ] && [ "$2" != "down" ] && exit 0
          ${pkgs.systemd}/bin/systemctl restart clatd.service
        '';
      }
    ];
  };
}
