# NixOS installation readiness

Production installation is intentionally disabled for both x86 hosts until
their physical storage and trust facts are enrolled in `config/hosts.nix`.
The ARM Linux output is evaluation-only and can never be an installation
target.

## Storage contract

Every enrolled host must name one whole disk using a stable
`/dev/disk/by-id/...` path. The declarative Disko layout is:

- GPT;
- 1 GiB FAT32 ESP mounted at `/boot`;
- one Btrfs root partition;
- flat `@root`, `@home`, `@nix`, and `@log` subvolumes;
- `compress=zstd:3` and `noatime` on every Btrfs mount;
- monthly Btrfs scrub and periodic trim;
- no swap, encryption, hibernation, or automatic snapshot service; and
- ten retained systemd-boot configurations.

The repository contains no `%DISK%`, `/dev/sdX`, or architecture-wide disk
default. When `installable = false` or storage is pending, Disko exports no
destructive device graph.

## Enrolling a host

From the live installer, identify the internal whole disk and record its stable
by-id path. Do not select the installer USB or a partition:

```bash
lsblk -d -o NAME,MODEL,SERIAL,SIZE,TRAN,TYPE
find -L /dev/disk/by-id -maxdepth 1 -type b -printf '%p -> %l\n'
```

Update only the matching named record (`nixos-laptop` or
`nixos-x86-qualifier`) after independently checking the physical machine:

```nix
installable = true;
storage = {
  state = "enrolled";
  diskById = "/dev/disk/by-id/<exact-whole-disk-id>";
};
```

Review the diff on the target machine and evaluate the named configuration
before any installer is allowed to erase media. Remote no-kexec installation
remains experimental; the supported production lane is verified direct media
with an attended erase confirmation. A pending declaration is a deliberate
`NOT VERIFIED` result, not a failed or silently generic configuration.

Installed SSH is key-only and has no public-tree authorized key. Enroll the
permanent login key through the private host-intake path before depending on
remote access.
