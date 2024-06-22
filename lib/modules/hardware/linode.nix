{ config, lib, ... }:
{
  options = with lib; {
    hardware.linode = {

      enabled = mkEnableOption "linode";

      apiToken = mkOption {
        description = "path to secret in secrets.yaml";
        example = "foo.bar.baz";
        type = types.str;
      };

      region = mkOption {
        description = "region of linode cluster";
        example = "us-west";
        type = types.str;
      };

      tags = lib.mkOption {
        description = "tags for kubernetes cluster";
        example = [ "dev" ];
        default = [ ];
        type = types.listOf lib.types.str;
      };

      version = lib.mkOption {
        description = "kubernetes version";
        example = "1.29";
        type = types.str;
      };

      pools = lib.mkOption {
        description = "linode pool options";
        type = types.listOf (types.submodule {
          options = {
            count = lib.mkOption {
              description = "number of nodes";
              example = 3;
              type = types.int;
            };
            nodeType = lib.mkOption {
              description = "linode type of node";
              example = "g6-standard-2";
              type = types.str;
            };
          };
        });
      };
    };
  };

  config =
    let
      clusterName = config.clusterName;
      cfg = config.hardware.linode;
    in {
      terraformOutput.tfModule = lib.mkIf cfg.enabled {
        provider.sops = {};

        data.sops_file.secrets = {
          source_file = "./secrets.yaml";
        };

        terraform.required_providers.linode = {
          source = "linode/linode";
          version = "2.20.1";
        };

        terraform.required_providers.sops = {
          source = "carlpett/sops";
          version = "1.0.0";
        };

        provider.linode.token = "\${ data.sops_file.secrets.data[\"${config.hardware.linode.apiToken}\"] }";

        resource.linode_lke_cluster.${clusterName} = {
          label = clusterName;
          k8s_version = cfg.version;
          region = cfg.region;
          tags = cfg.tags;
          pool = map (poolCfg: { type = poolCfg.nodeType; count = poolCfg.count; }) cfg.pools;
        };

        output.kubeconfig = {
          value = "\${ resource.linode_lke_cluster.${clusterName}.kubeconfig }";
          sensitive = true;
        };
      };
    };
}
