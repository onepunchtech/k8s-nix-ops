{ pkgs, helmChartsConfig }:

with pkgs;

let
  writeChartTemplate = name: templateFile:
    writeTextDir ("templates/${name}.yaml") templateFile;

  mkChartDerivation = name: chartConfig:
    let
      templateFiles = lib.attrsets.mapAttrsToList writeChartTemplate chartConfig.templates;
      chartDecl = {};

    in symlinkJoin { name = "${name}Chart"; paths = templateFiles;};

  builtCharts = lib.attrsets.mapAttrs mkChartDerivation helmChartsConfig;

in pkgs.stdenv.mkDerivation {
  name = "helmChartsOut";
  phases = ["installPhase"];
  installPhase = ''
    mkdir $out
    ln -s ${builtCharts.crds} $out/crds
    ln -s ${builtCharts.infra} $out/infra
  '';
}
