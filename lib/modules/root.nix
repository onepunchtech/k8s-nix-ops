{ config, lib, ... }:
let
  templatesOption = lib.mkOption {
      description = "Attrset of yaml templates for helm chart";
      type = lib.types.attrsOf lib.types.str;
    };
in {
  imports = [
    ./hardware/linode.nix
    ./hardware/k0s.nix
    ./features.nix
  ];

  options = with lib; {
    clusterName = lib.mkOption {
      description = "Name of cluster";
      type = types.str;
    };

    # features = {
    #   description = "List of features for cluster";
    #   type = types.submodule ./features.nix;
    # };

    privateRegistries = {
      description = "private registries";
      type = types.submodule ./privateRegistry.nix;
    };

    services = {
      description = "Services";
      type = (types.listOf (types.submodule ./service.nix));
    };

    terraformOutput.tfModule = mkOption {
      description = "terraform config as a nix expression. This will be passed to terranix.";
      type = types.anything;
    };

    helmCharts = {
      crds.templates = templatesOption;
      infra.templates = templatesOption;
      services.templates = templatesOption;
    };
  };
}
