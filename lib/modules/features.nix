{config, lib, pkgs, charts, kubelib, ...}:
with lib; let
  externalDNS = {
    options = {

    };
  };
  certManager = (kubelib.buildHelmChart {
    name = "certificateManager";
    chart = charts.jetstack.cert-manager;
    namespace = "foo";
  });
in {
  options = {
    features.certManager = {
      enabled = mkEnableOption "Cert Manager";
      issuerEmail = mkOption {
        description = "email used to register acme certs";
        type = types.str;
      };
    };
  };

  config = mkIf config.features.certManager.enabled {
    helmCharts = {
      crds.templates = { certManager = builtins.trace certManager "foo";};
      infra.templates = { certManager = "certManager: fooService";};
    };
  };
}
