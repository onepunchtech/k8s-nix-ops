{lib, ...}:
with lib; let
  certManager = {
    options = {
      issuerEmail = {
        description = "email used to register acme certs";
        type = types.str;
      };
    };
  };

  externalDNS = {
    options = {

    };
  };
in {
  options = {
    features.certManager = {
      enabled = mkEnableOption "Cert Manager";
      issuerEmail = {
        description = "email used to register acme certs";
        type = types.submodule certManager;
      };
    };
  };

  config = mkIf config.features.certManager.enabled {
    helmCharts = {
      crds.templates = { certManager = "certManager: fooCrd";};
      infra.templates = { certManager = "certManager: fooService";};
    };
  };
}
