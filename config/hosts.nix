{
  nixos-laptop = {
    hostId = "nixos-laptop";
    hostName = "nixos";
    system = "x86_64-linux";
    role = "workstation";
    installable = false;
    cpuVendor = "pending";
    storage = { state = "pending"; diskById = null; };
  };

  nixos-x86-qualifier = {
    hostId = "nixos-x86-qualifier";
    hostName = "nixos-x86-qualifier";
    system = "x86_64-linux";
    role = "qualifier";
    installable = false;
    cpuVendor = "pending";
    storage = { state = "pending"; diskById = null; };
  };

  aarch64-linux = {
    hostId = "aarch64-linux";
    hostName = "nixos-aarch64-evaluation";
    system = "aarch64-linux";
    role = "evaluation";
    installable = false;
    cpuVendor = "pending";
    storage = { state = "disabled"; diskById = null; };
  };

  aarch64-darwin = {
    hostId = "aarch64-darwin";
    hostName = "darwin";
    system = "aarch64-darwin";
    role = "workstation";
    installable = false;
    cpuVendor = "Apple";
    storage = { state = "disabled"; diskById = null; };
  };
}
