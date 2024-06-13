{
  description = "k8s-nix-ops";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators?ref=14dbd5e5b40615937900f71d9a9851b59b4d9a88";
    nixhelm.url = "github:farcaller/nixhelm?ref=785c1e2d9ab8bb0db049ff1ab983b7f73f073d51";
    flake-utils.url = "github:numtide/flake-utils";
    terranix.url = "github:terranix/terranix";
  };

  outputs = { self, flake-utils, nixpkgs, nix-kube-generators, nixhelm, terranix }:
    let
      system = "x86_64-linux";
      #pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      pkgs = nixpkgs.legacyPackages.${system};
      kubelib = nix-kube-generators.lib { inherit pkgs; };
      charts = nixhelm.charts { inherit pkgs; };
      #makeK8sConfigs = config: {
      #terraformConfig = import ./lib/hardware.nix {inherit system terranix; };
      #k8sConfig = import ./lib/k8s.nix { inherit pkgs nix-kube-generators nixhelm; };
      #};

      configuration = pkgs.lib.evalModules {
        modules = [{
          clusterName = "dev-cluster";
          hardware = {
            linode = {
              enabled = true;
              apiToken = "foo.bar";
              region = "us-west";
              version = "1.29";
              pools = [
                { nodeType = "foo"; count = 3; }
              ];
            };
          };
          features = {
            certManager = {
              enabled = true;
              issuerEmail = "whitehead@onepunchtech.xyz";
            };
          };
        }
                   ({ config, ... }: { config._module.args = { inherit pkgs charts kubelib; }; })
                   ./lib/modules/root.nix];
      };

      validatedConfiguration = import ./lib/validate.nix { lib = nixpkgs.lib; config = configuration.config; };

      tfConfig = terranix.lib.terranixConfiguration
        {
          inherit system;
          modules = [ validatedConfiguration.terraformOutput.tfModule ];
        };

      helm = import ./lib/chart-builder.nix {
        pkgs = pkgs;
        helmChartsConfig = validatedConfiguration.helmCharts;
      };

      testOut = pkgs.stdenv.mkDerivation
        {
          name = "testout";
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir $out
            mkdir $out/hardware
            cp  ${tfConfig} $out/hardware/tfconfig.json
            ln -s ${helm} $out/helm
          '';
        };
    in
      {
        packages.${system}.default = testOut;

        #inherit makeK8sConfigs;
      };
}
