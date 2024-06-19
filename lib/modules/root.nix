{ config, lib, charts, kubelib, ... }:
let
  templatesOption = lib.mkOption {
      description = "Attrset of yaml templates for helm chart";
      default = {};
      type = lib.types.attrsOf lib.types.package;
    };
in {
  imports = [
    ./hardware/linode.nix
    ./hardware/k0s.nix
    ./features.nix
    ./privateRegistries.nix
    ./services.nix
  ];

  options = with lib; {
    clusterName = lib.mkOption {
      description = "Name of cluster";
      type = types.str;
    };

    terraformOutput.tfModule = mkOption {
      description = "terraform config as a nix expression. This will be passed to terranix.";
      type = types.anything;
    };

    helmCharts = {
      crds.templates = templatesOption;
      infra.templates = templatesOption;
      apps.templates = templatesOption;
    };
  };
}
