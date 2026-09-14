{ config, lib, pkgs, ... }:
let
  cfg = config.programs.genyconnect;
in
{
  options.programs.genyconnect = {
    enable = lib.mkEnableOption "GenyConnect with desktop TUN support";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "GenyConnect package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    security.polkit.enable = true;
    boot.kernelModules = [ "tun" ];

    # A reply arrives on the uplink while an unmarked reverse lookup selects
    # TUN. This applies to both the nftables and iptables firewall backends.
    # Loose mode retains source reachability checks without requiring symmetry.
    networking.firewall.checkReversePath = lib.mkDefault "loose";
  };
}
