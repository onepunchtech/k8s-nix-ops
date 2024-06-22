{
  description = "k8s-nix-ops";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators?ref=14dbd5e5b40615937900f71d9a9851b59b4d9a88";
    nixhelm.url = "github:farcaller/nixhelm?ref=12136f5aece74f62356662f50904633c7c783418";
    flake-utils.url = "github:numtide/flake-utils";
    terranix.url = "github:terranix/terranix";
  };

  outputs = { self, flake-utils, nixpkgs, nix-kube-generators, nixhelm, terranix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { system = system; config.allowUnfree = true; };
      kubelib = import ./lib/kubelib.nix { kubelib = nix-kube-generators.lib { inherit pkgs; }; };
      charts = nixhelm.charts { inherit pkgs; };

      buildConfig = cfg:
        let
          configuration = pkgs.lib.evalModules {
            modules = [
              cfg
              ({ config, ... }: { config._module.args = { inherit charts kubelib; }; })
              ./lib/modules/root.nix
            ];
          };

          validatedConfiguration = import ./lib/validate.nix { lib = nixpkgs.lib; config = configuration.config; };

          tfConfig = terranix.lib.terranixConfiguration
            {
              inherit system;
              modules = [ validatedConfiguration.terraformOutput.tfModule ];
            };

          helm = import ./lib/chart-builder.nix {
            pkgs = pkgs;
            kubelib = kubelib;
            helmChartsConfig = validatedConfiguration.helmCharts;
          };

        in

        pkgs.stdenv.mkDerivation
          {
            name = "cluster-config";
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir $out
              mkdir $out/hardware
              cp  ${tfConfig} $out/hardware/tfconfig.json
              ln -s ${helm} $out/helm
            '';
          };

      mkTools = cfg:
        let
          builtConfig = buildConfig cfg;
        in
        {
          runTerraform = pkgs.writeScriptBin "runTerraform"
            ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${builtConfig}/hardware/tfconfig.json config.tf.json \
              && ${pkgs.terraform}/bin/terraform init \
              && ${pkgs.terraform}/bin/terraform apply
            '';
        };

    in
    {

      packages.x86_64-linux.default = pkgs.hello;

      lib = {
        buildConfig = buildConfig;
        buildTools = mkTools;
      };
    };
}
