{ inputs, ... }:
{
  imports = [
    inputs.den.flakeModule
    inputs.den.flakeModules.strict
    (inputs.import-tree ../entities)
    (inputs.import-tree ../aspects)
  ];
}
