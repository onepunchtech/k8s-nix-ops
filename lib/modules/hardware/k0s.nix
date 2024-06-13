{ config, lib, ... }:
{
  options = with lib; {
    hardware.k0s = {
      enabled = mkEnableOption "k0s";
    };
  };

  config = lib.mkIf config.hardware.k0s.enabled {
    terraformOutput.tfModule = {
      terraform.required_providers = {
        source = "";
        version = "";
      };
    };
  };
}
