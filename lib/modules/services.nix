{ config, kubelib, lib, ... }:

let
  tlsOptsModule = {
    options = {
      duration = lib.mkOption {
        type = lib.types.str;
      };

      renewBefore = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  ingressModule = {
    options = {
      host = lib.mkOption {
        type = lib.types.str;
      };

      path = lib.mkOption {
        type = lib.types.str;
      };

      tlsOpts = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule tlsOptsModule);
      };
    };
  };

  serviceModule = {
    options = {
      image = lib.mkOption {
        description = "container image";
        type = lib.types.str;
      };

      replicas = lib.mkOption {
        type = lib.types.ints.positive;
      };

      registry = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
      };

      port = lib.mkOption {
        type = lib.types.ints.positive;
      };

      ingresses = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule ingressModule);
      };
    };
  };

  mkIngress = { name, issuerName, ingressClassName, host, path, serviceName, port }: {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = name;
      annotations = {
        "cert-manager.io/issuer" = issuerName;
      };
    };

    spec = {
      ingressClassName = ingressClassName;
      tls = [{ hosts = [ host ]; secretName = "${name}-tls"; }];
      rules = [
        {
          host = host;
          http.paths = [
            {
              path = path;
              pathType = "Prefix";
              backend =
                {
                  service = {
                    name = serviceName;
                    port = { number = port; };
                  };
                };
            }
          ];
        }
      ];
    };
  };

  serviceModuleToTemplate = config: name: serviceMod:
    let
      privateRegistry =
        if (builtins.hasAttr serviceMod.registry config.privateRegistries)
        then null
        else config.privateRegistries."${serviceMod.registry}";

      service = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = name;
        };
        spec = {
          seleector = {
            app = name;
          };
          ports = [
            {
              port = serviceMod.port;
              targetPort = serviceMod.port;
            }
          ];
        };
      };

      deployment = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          name = name;
          labels = { app = name; };
        };
        spec = {
          replicas = serviceMod.replicas;
          selector = {
            matchLabels = {
              app = name;
            };
          };
          template = {
            metadata.labels.app = name;
            spec = {
              container = {
                image = "${privateRegistry.registryUrl}/${serviceMod.image}";
                name = name;
                ports = {
                  containerPort = serviceMod.port;
                };
              };
              imagePullSecrets.name =
                if (builtins.null privateRegistry)
                then null
                else serviceMod.registry;
            };
          };
        };
      };
      yamls = [ service deployment ];
    in
    kubelib.toYAMLStreamFile yamls;



in
{
  options = {
    services = lib.mkOption {
      description = "attrset of services to deploy to k8s";
      type = lib.types.attrsOf (lib.types.submodule serviceModule);
      default = { };

    };
  };

  config = lib.mkIf (builtins.length (builtins.attrNames config.services) > 0) {
    helmCharts.apps.templates = lib.attrsets.mapAttrs serviceModuleToTemplate config.services;
  };
}
