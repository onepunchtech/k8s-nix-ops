{config, lib, charts, kubelib, ...}:
let
  certManager = kubelib.fromHelm {
    name = "cert-manager";
    chart = charts.jetstack.cert-manager;
    namespace = "default";
    includeCRDs = false;
    values = {crds.enabled = true;};
  };

  externalDns = kubelib.fromHelm {
    name = "external-dns";
    chart = charts.external-dns.external-dns;
    namespace = "default";
    includeCRDs = true;
  };

  ingressNginx =  kubelib.fromHelm {
    name = "ingress-nginx";
    chart = charts.kubernetes.ingress-nginx;
    namespace = "default";
    includeCRDs = true;
  };

  mkIssuer = cfg: {
    apiVersion = "cert-manager.io/v1";
    kind = "Issuer";
    metadata.name = cfg.features.certManager.issuerName;
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory";
        email = cfg.features.certManager.issuerEmail;
        privateKeySecretRef.name = "letsencrypt-prod";
        solvers = [
          {http01.ingress.ingressClassName = cfg.features.ingress.className;}
        ];
      };
    };

  };

in {
  options = {
    features.ingress = {
      enabled = lib.mkEnableOption "Ingress";
      className = lib.mkOption {
        description = "Name of the ingress class";
        type = lib.types.str;
        default = "nginx";
      };
    };

    features.certManager = {
      enabled = lib.mkEnableOption "Cert Manager";
      issuerEmail = lib.mkOption {
        description = "email used to register acme certs";
        type = lib.types.str;
      };
      issuerName = lib.mkOption {
        description = "Name of cert manager issuer";
        type = lib.types.str;
      };
    };

    features.externalDns = {
      enabled = lib.mkEnableOption "External DNS";
      linodeToken = lib.mkOption {
        description = "path to secret in secrets.yaml";
        type = lib.types.str;
      };
    };
  };

  config = {
    helmCharts = lib.mkMerge [
      (lib.mkIf config.features.certManager.enabled {
        crds.templates.certManager = certManager.crds;
        infra.templates.certManager = certManager.templates;
        infra.templates.certManagerIssuer = kubelib.toYAMLFile (mkIssuer config);
      })

      (lib.mkIf config.features.externalDns.enabled {
        crds.templates.externalDns = externalDns.crds;
        infra.templates.externalDns = externalDns.templates;
      })

      (lib.mkIf config.features.ingress.enabled {
        crds.templates.ingress = ingressNginx.crds;
        infra.templates.ingress = ingressNginx.templates;
      })
    ];
  };
}
