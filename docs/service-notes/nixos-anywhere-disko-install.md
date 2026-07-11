# Fresh NixOS install with nixos-anywhere + Disko

Use this when installing this repo's NixOS config onto a fresh laptop/PC from
another working computer over SSH. This avoids typing long install commands on
the target machine and makes disk selection easier to inspect from a normal
terminal.

## Why this needs a temporary local clone

This repo's Disko config currently uses a placeholder disk path:

```nix
device = "/dev/%DISK%";
```

`disko-install` can override that directly with `--disk vdb /dev/disk/by-id/...`.
`nixos-anywhere` does not expose the same disk override, so for remote installs
make a temporary local clone and replace `/dev/%DISK%` with the target machine's
real stable disk ID before running `nixos-anywhere`.

Do not commit that temporary disk-specific edit unless you intentionally want to
pin this repo to one machine's disk.

## 1. Boot the target laptop into a NixOS ISO

On the target laptop/PC:

```bash
sudo -i
```

Connect networking if needed:

```bash
nmtui
```

Enable SSH for the installer session:

```bash
passwd root
systemctl start sshd
ip -4 addr
```

Record the target IP, for example `192.168.1.123`.

## 2. Verify SSH from the working computer

On the working computer:

```bash
TARGET=192.168.1.123
ssh root@$TARGET
```

If login works, exit back to the working computer:

```bash
exit
```

## 3. Identify the target disk over SSH

Run this from the working computer:

```bash
ssh root@$TARGET '
for d in /sys/block/*; do
  name=${d##*/}
  case "$name" in loop*|ram*|zram*) continue ;; esac
  [ -e "$d/device" ] || continue
  printf "\nDEVICE: /dev/%s\n" "$name"
  lsblk -dn -o NAME,MODEL,SERIAL,SIZE,TRAN,TYPE "/dev/$name"
  find /dev/disk/by-id -maxdepth 1 -type l ! -name "*-part*" \
    -exec sh -c '\''for x; do [ "$(readlink -f "$x")" = "/dev/'"$name"'" ] && echo "  ID: $x"; done'\'' sh {} +
done
'
```

Pick the internal disk, not the installer USB.

Typical signs:

- `TRAN=usb` and a small size usually means the installer USB.
- `TRAN=nvme` or `TRAN=sata` with a large size usually means the internal disk.
- Use a `/dev/disk/by-id/...` path, not `/dev/nvme0n1` or `/dev/sda`, when possible.

Set the chosen disk on the working computer:

```bash
DISK=/dev/disk/by-id/nvme-YOUR_INTERNAL_DISK_ID
```

Verify it against the target:

```bash
ssh root@$TARGET "lsblk '$DISK'"
```

## 4. Create a temporary patched clone

On the working computer:

```bash
WORK=$(mktemp -d)
git clone https://github.com/Meillaya/nix-config.git "$WORK/nix-config"
cd "$WORK/nix-config"
```

Replace the placeholder with the target disk ID:

```bash
export DISK
python3 - <<'PY'
from pathlib import Path
import os

path = Path("modules/nixos/disk-config.nix")
text = path.read_text()
needle = "/dev/%DISK%"
if needle not in text:
    raise SystemExit(f"missing placeholder: {needle}")
path.write_text(text.replace(needle, os.environ["DISK"]))
PY
```

Confirm the patched device:

```bash
grep -n 'device =' modules/nixos/disk-config.nix
```

## 5. Run nixos-anywhere

For a normal Intel/AMD laptop:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake ".#x86_64-linux" \
  --target-host root@$TARGET \
  --build-on local \
  --option max-jobs 1 \
  --option cores 1
```

This will wipe the selected disk, run Disko, install the flake, and reboot the
target.

For ARM hardware, use:

```bash
--flake ".#aarch64-linux"
```

## 6. First login and password note

This repo creates the `mei` user but does not declare an initial password.
After install, prefer SSH key access if your key was included. If password login
is needed and no password was set, boot the ISO again and mount the installed
system manually. This repo's Disko layout does not declare filesystem labels, so
identify the root and EFI partitions first:

```bash
lsblk -f
```

For the default Disko layout, the small `vfat` partition is `/boot` and the large
`ext4` partition is `/`. Example for an NVMe target:

```bash
mount /dev/nvme0n1p2 /mnt
mount /dev/nvme0n1p1 /mnt/boot
nixos-enter --root /mnt -c 'passwd mei'
reboot
```

## References

- Disko install docs: <https://github.com/nix-community/disko/blob/master/docs/disko-install.md>
- nixos-anywhere quickstart: <https://nix-community.github.io/nixos-anywhere/quickstart.html>
- NixOS manual: <https://nixos.org/manual/nixos/stable/>
