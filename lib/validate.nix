{lib, config} :
let
  checkEnabledClusters = config:
    let
      enabledHardware =
        builtins.filter (isEnabled: isEnabled)
          (lib.attrsets.mapAttrsToList (_: v: v.enabled) config.hardware);
    in
      if builtins.length enabledHardware > 1
      then throw "Can only enable one k8s hardware module at a time"
      else config;
in checkEnabledClusters config
