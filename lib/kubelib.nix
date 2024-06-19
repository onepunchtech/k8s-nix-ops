{kubelib}:

let fromHelmRaw = opts:
      let
        yamls = kubelib.fromHelm opts;
      in {
        crds = builtins.filter (x: x.kind == "CustomResourceDefinition") yamls;
        templates = builtins.filter (x: x.kind != "CustomResourceDefinition") yamls;
      };

    fromHelm = opts:
      let
        res = fromHelmRaw opts;
      in {
        crds = kubelib.toYAMLStreamFile res.crds;
        templates = kubelib.toYAMLStreamFile res.templates;
      };

in  {
  inherit fromHelmRaw fromHelm;
  toYAMLStreamFile = kubelib.toYAMLStreamFile;
  toYAMLFile = kubelib.toYAMLFile;
}
