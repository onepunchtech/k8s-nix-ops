{ pkgs, helmChartsConfig }:

with pkgs;

let
  writeChartTemplate = name: templateFile:
    writeTextDir ("templates/${name}.yaml") templateFile;

  mkChartDerivation = name: chartConfig:
    let
      templateFiles = lib.mapAttrsToList writeChartTemplate chartConfig.templates;
      chartDecl = {};

    in lib.symlinkJoin { name = "${name}Chart"; paths = templateFiles;};

  builtCharts = lib.mapAttrs mkChartDerivation helmChartsConfig;
in {
  helmChartsOut = pkgs.stdenv.mkDerivation {
    name = "helmChartsOut";
    phases = ["installPhase"];
    installPhase = ''
      mkdir $out
      ln -s ${builtCharts.crds} $out/crds
      ln -s ${builtCharts.infra} $out/infra
    '';
  };
}
