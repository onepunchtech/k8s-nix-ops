{config, lib, kubelib, ...}:

let privateRegistryModule = {
      options = {
        registryUrl = lib.mkOption {
          description = "url of registry";
          type = lib.types.str;
        };
        secret = lib.mkOption {
          description = "path to secret in secrets.yaml";
          type = lib.types.str;
        };
      };
    };

    registryModuleToTemplate = name: regMod:
      let
        yaml = {
          apiVersion = "v1";
          kind = "Secret";
          metadata = {
            name = name;
            namespace = "default";
          };
          data = {
            ".dockerconfigjson" = regMod.secret;
          };
          type = "kubernetes.io/dockerconfigjson";
        };
      in kubelib.toYAMLFile yaml;
in

{
  options = {
    privateRegistries = lib.mkOption {
      description = "Attrset of private registries";
      type = lib.types.attrsOf (lib.types.submodule privateRegistryModule);
    };
  };

  config = lib.mkIf (builtins.length (builtins.attrNames config.privateRegistries) > 0) {
    helmCharts.infra.templates = lib.attrsets.mapAttrs registryModuleToTemplate config.privateRegistries;
  };
}
