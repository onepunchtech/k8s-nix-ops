{ pkgs, kubelib, helmChartsConfig }:

with pkgs;

let

  mkChartDerivation = name: chartConfig:
    let
      chartYaml = builtins.toFile "Chart.yaml" (builtins.toJSON {
        apiVersion = "v2";
        name = name;
        version = "0.0.1";
      });

      putInTemplateDir = name: template: pkgs.stdenv.mkDerivation {
        name = "${name}-template-isolate";
        phases = [ "installPhase" ];
        installPhase = ''
          mkdir $out
          ln -s ${template} $out/${name}.yaml
        '';
      };

      templateFiles = lib.attrsets.mapAttrsToList putInTemplateDir chartConfig.templates;


      templatesDir = symlinkJoin {
        name = "templates";
        paths = templateFiles;
      };

    in
    pkgs.stdenv.mkDerivation {
      name = "chart-${name}";
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir $out

        ln -s ${chartYaml} $out/Chart.yaml
        ln -s ${templatesDir} $out/templates
      '';
    };

  helmFile = kubelib.toYAMLFile {
    releases = [
      {
        name = "crds";
        chart = "./crds";
      }
      {
        name = "infra";
        chart = "./infra";
        needs = [ "crds" ];
      }
      {
        name = "apps";
        chart = "./apps";
        needs = [ "infra" ];
      }
    ];

  };


  builtCharts = lib.attrsets.mapAttrs mkChartDerivation helmChartsConfig;

in
pkgs.stdenv.mkDerivation {
  name = "helmChartsOut";
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir $out
    ln -s ${builtCharts.crds} $out/crds
    ln -s ${builtCharts.infra} $out/infra
    ln -s ${builtCharts.apps} $out/apps
    ln -s ${helmFile} $out/helmfile.yaml
  '';
}
