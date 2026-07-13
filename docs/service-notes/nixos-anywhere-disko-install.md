# Fresh NixOS install with nixos-anywhere + Disko

Use this when installing this repo's NixOS config onto a fresh laptop/PC from
another working computer over SSH. This avoids typing long install commands on
the target machine and makes disk selection easier to inspect from a normal
terminal.

This procedure applies the complete `x86_64-linux` or `aarch64-linux` flake
configuration during installation. It does not install a generic desktop first:
the first boot is already this repository's NixOS system, including the `mei`
account and its per-install login password. Those architecture-oriented flake
output names are stable installation interfaces; Den's host entities set the
network hostnames to `nixos` and `nixos-aarch64`, respectively.

## Before starting

You need:

- A NixOS installer USB for the target machine. The minimal ISO is sufficient.
- A second Linux computer on the same network. The helper currently relies on
  Linux `findmnt` and a tmpfs-backed `XDG_RUNTIME_DIR`.
- `nix`, `git`, `ssh`, `fish`, `python3`, and either Bash or Nushell on the
  working computer.
- Internet access from the working computer and installer environment.
- A backup of anything valuable on the target disk.

Run this workflow only on an isolated, trusted network. The pinned
`nixos-anywhere` release disables strict SSH host-key checking for its internal
connections, so the initial SSH host-key prompt below does not protect later
installation traffic from an active network attacker.

Shell-sensitive commands in this guide are provided in separate **Bash** and
**Nushell** blocks. Commands shown only once work unchanged in either shell or
run on the NixOS installer, whose root terminal uses Bash. The password helper
is a Fish script, but it can be launched from either Bash or Nushell.

The Disko step is destructive. It erases the disk selected in step 3. Repeat the
disk-identification and patching steps independently for every new PC or laptop;
never reuse a disk ID from another machine.

## What the bootstrap-password workflow does

For each installation, the helper:

1. Prompts locally for a new password and generates a yescrypt verifier.
2. Stores only that verifier in a mode-0600 file under private runtime tmpfs.
3. Stages `$HOME/Pictures/Wallpapers` in the same private directory.
4. Transfers the verifier and wallpapers using `nixos-anywhere --extra-files`.
5. Makes NixOS validate the verifier before creating or updating `mei`.
6. Confirms that the verifier reached `/etc/shadow` after user creation.
7. Replaces the staged verifier with the exact locked sentinel `!\n`.

The plaintext password and reusable verifier are not committed to Git or copied
into the Nix store. Later rebuilds accept the sentinel only when `mei` already
has an unlocked password in `/etc/shadow`.

The wallpaper source defaults to `$HOME/Pictures/Wallpapers` on the computer
running the installer. Set `NIXOS_ANYWHERE_WALLPAPERS` to an alternate source
directory when needed. Use only a locally trusted, non-secret wallpaper tree.
The helper fails before prompting for a password if the
directory is missing, is a symlink, contains symlinks or special files, exceeds
4 GiB apparent size, or cannot fit in runtime tmpfs with a 64 MiB reserve.
Wallpaper files are copied to
`/home/mei/Pictures/Wallpapers`; the complete `Pictures` tree is assigned
ownership `1000:100`. The NixOS profile pins `mei` to UID 1000 so ownership is
deterministic on a fresh install.

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

The repository intentionally has no recursive `apply` template-rewrite app.
Patch only `modules/nixos/disk-config.nix` as shown below so an installation
cannot accidentally rewrite Git metadata, secrets, or unrelated configuration.

## 1. Boot the target laptop into a NixOS ISO

Disable Secure Boot in firmware if this machine cannot boot the standard NixOS
ISO. Boot the USB in UEFI mode, then open a terminal on the target laptop/PC:

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

Keep the installer booted and this terminal open. The root password is temporary
and exists only for this live installer session.

## 2. Verify SSH from the working computer

On the working computer:

**Bash:**

```bash
TARGET=192.168.1.123
ssh "root@$TARGET"
```

**Nushell:**

```nu
let target = "192.168.1.123"
ssh $"root@($target)"
```

If login works, exit back to the working computer:

```bash
exit
```

If SSH reports a changed host key because the address was previously used by
another installer session, verify that the IP is correct and remove only that
old entry:

**Bash:**

```bash
ssh-keygen -R "$TARGET"
```

**Nushell:**

```nu
ssh-keygen -R $target
```

## 3. Identify the target disk over SSH

Run this from the working computer:

**Bash:**

```bash
ssh "root@$TARGET" 'bash -s' <<'REMOTE_BASH'
for d in /sys/block/*; do
  name=${d##*/}
  case "$name" in loop*|ram*|zram*) continue ;; esac
  [ -e "$d/device" ] || continue
  printf "\nDEVICE: /dev/%s\n" "$name"
  lsblk -dn -o NAME,MODEL,SERIAL,SIZE,TRAN,TYPE "/dev/$name"
  for id in /dev/disk/by-id/*; do
    [ -L "$id" ] || continue
    case "$id" in *-part*) continue ;; esac
    [ "$(readlink -f -- "$id")" = "/dev/$name" ] && printf "  ID: %s\n" "$id"
  done
done
REMOTE_BASH
```

**Nushell:**

```nu
let disk_probe = r#'
for d in /sys/block/*; do
  name=${d##*/}
  case "$name" in loop*|ram*|zram*) continue ;; esac
  [ -e "$d/device" ] || continue
  printf "\nDEVICE: /dev/%s\n" "$name"
  lsblk -dn -o NAME,MODEL,SERIAL,SIZE,TRAN,TYPE "/dev/$name"
  for id in /dev/disk/by-id/*; do
    [ -L "$id" ] || continue
    case "$id" in *-part*) continue ;; esac
    [ "$(readlink -f -- "$id")" = "/dev/$name" ] && printf "  ID: %s\n" "$id"
  done
done
'#
$disk_probe | ssh $"root@($target)" "bash -s"
```

Pick the internal disk, not the installer USB.

Typical signs:

- `TRAN=usb` and a small size usually means the installer USB.
- `TRAN=nvme` or `TRAN=sata` with a large size usually means the internal disk.
- Use a `/dev/disk/by-id/...` path, not `/dev/nvme0n1` or `/dev/sda`, when possible.

Set the chosen disk on the working computer:

**Bash:**

```bash
DISK='/dev/disk/by-id/nvme-YOUR_INTERNAL_DISK_ID'
```

**Nushell:**

```nu
let disk = "/dev/disk/by-id/nvme-YOUR_INTERNAL_DISK_ID"
```

Verify it against the target:

**Bash:**

```bash
ssh "root@$TARGET" "lsblk '$DISK'"
```

**Nushell:**

```nu
ssh $"root@($target)" lsblk $disk
```

## 4. Create a temporary patched clone

On the working computer:

**Bash:**

```bash
WORK=$(mktemp -d)
git clone https://github.com/Meillaya/nix-config.git "$WORK/nix-config"
cd "$WORK/nix-config"
```

**Nushell:**

```nu
let work = (mktemp -d | str trim)
let repo = ($work | path join "nix-config")
git clone https://github.com/Meillaya/nix-config.git $repo
cd $repo
```

Replace the placeholder with the target disk ID:

**Bash:**

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

**Nushell:**

In the next block, replace only the value assigned to `disk_id`. Keep the
`literal_placeholder` value exactly as `/dev/%DISK%`; it describes the text
currently in the repository, not the selected disk. Nushell variable names are
case-sensitive.

```nu
let disk_id = "/dev/disk/by-id/nvme-YOUR_INTERNAL_DISK_ID"
let path = "modules/nixos/disk-config.nix"
let literal_placeholder = "/dev/%DISK%"
let text = (open --raw $path)
if not ($text | str contains $literal_placeholder) {
  error make {msg: $"missing placeholder: ($literal_placeholder)"}
}
$text | str replace $literal_placeholder $disk_id | save --force $path
```

Confirm the patched device:

```bash
grep -n 'device =' modules/nixos/disk-config.nix
```

The displayed value must exactly match the internal disk verified in step 3.
Stop here if it names the USB installer, an external drive, or an unexpected
device. This temporary checkout is intentionally dirty and machine-specific.

## 5. Run nixos-anywhere with a one-time bootstrap password

First confirm the helper's runtime staging directory is backed by tmpfs:

**Bash:**

```bash
findmnt -no TARGET,FSTYPE --target "$XDG_RUNTIME_DIR"
```

**Nushell:**

```nu
findmnt -no TARGET,FSTYPE --target $env.XDG_RUNTIME_DIR
```

The filesystem type must be `tmpfs`. The helper refuses to continue otherwise.

For a normal Intel/AMD laptop, run this from the patched checkout on the working
computer:

**Bash:**

```bash
./bin/nixos-anywhere-bootstrap-password.fish \
  "root@$TARGET" \
  ".#x86_64-linux"
```

**Nushell:**

```nu
./bin/nixos-anywhere-bootstrap-password.fish $"root@($target)" ".#x86_64-linux"
```

The helper prompts interactively for a unique password, generates a yescrypt verifier in
private runtime tmpfs, stages `$HOME/Pictures/Wallpapers`, and transfers both
with `nixos-anywhere --extra-files`. The
plaintext password is never placed in Git, the Nix store, an argument, or an
environment variable. Do not enable shell tracing, terminal recording, or
`nixos-anywhere --debug` while running it.

If the wallpapers are stored elsewhere, select the source explicitly:

**Bash:**

```bash
NIXOS_ANYWHERE_WALLPAPERS="$HOME/path/to/Wallpapers" \
  ./bin/nixos-anywhere-bootstrap-password.fish \
  "root@$TARGET" \
  ".#x86_64-linux"
```

**Nushell:**

```nu
with-env { NIXOS_ANYWHERE_WALLPAPERS: ($nu.home-path | path join "path/to/Wallpapers") } {
  ./bin/nixos-anywhere-bootstrap-password.fish $"root@($target)" ".#x86_64-linux"
}
```

After entering the new `mei` password, OpenSSH may also prompt for the temporary
root password set on the installer ISO. The helper keeps that prompt attached to
the terminal and disables local SSH-agent identities for the installer so
unrelated loaded keys cannot exhaust the target's authentication limit. It does
not modify the agent or persist the ISO root password.

Because the system is built locally, the helper uploads the complete closure
instead of asking the installer environment to substitute it again. It also
explicitly sets the transferred bootstrap directory to numeric ownership `0:0`
before activation; the NixOS validator still rejects loose modes, symlinks, and
malformed verifiers.

This deliberately disables destination substitution and propagation of the
configured machine substituters. Uploading may take longer when the installer
could have used a faster binary cache, but failed destination cache lookups
cannot obscure the local closure transfer and the installer does not inherit
additional substituter trust settings.

`mkpasswd` prompts once and does not ask for confirmation, so type the password
carefully. Do not reuse it on another installation.

The helper pins both `mkpasswd` and `nixos-anywhere` to reviewed Git revisions.
Update those revisions deliberately in
`bin/nixos-anywhere-bootstrap-password.sh` when refreshing installer tooling.

The install will wipe the selected disk, run Disko, install the flake, and reboot
the target. Installation activation applies the verifier to `mei` before first
boot and replaces the extra copy with a locked `!` sentinel. The real password
remains in `/etc/shadow` because this config uses mutable users.

For ARM hardware, use the ARM configuration below. Because the helper builds on
the working computer, that computer must be ARM too or have a working AArch64
builder/emulation setup:

**Bash:**

```bash
./bin/nixos-anywhere-bootstrap-password.fish \
  "root@$TARGET" \
  ".#aarch64-linux"
```

**Nushell:**

```nu
./bin/nixos-anywhere-bootstrap-password.fish $"root@($target)" ".#aarch64-linux"
```

Do not interrupt the command while Disko is partitioning the target. A successful
run finishes the install and normally reboots the machine. If it fails, read the
reported error before retrying; do not switch to a different disk path merely to
make the command proceed.

### Diagnose an activation failure before retrying

If activation fails after Disko has mounted the target, keep the installer ISO
running and inspect the failure before retrying. Run this in the target's root
console or root SSH session. It reports metadata and verifier shape without
printing the verifier:

```bash
root=/mnt
dir=$root/var/lib/nixos-bootstrap
hash=$dir/mei-password.hash

findmnt -R -o TARGET,SOURCE,FSTYPE,OPTIONS --target "$root" || true
stat -c 'path=%n type=%F mode=%a uid=%u gid=%g owner=%U group=%G' \
  "$dir" "$hash" || true

system=$(chroot "$root" /nix/var/nix/profiles/system/sw/bin/readlink -e \
  /nix/var/nix/profiles/system) || system=
printf 'target-system=%s\n' "$system"
case "$system" in
  /nix/store/*-nixos-system-*)
    grep -nE '^#### Activation script snippet (bootstrapPasswordHash|users|consumeBootstrapPassword):' \
      "$root$system/activate" || true
    chroot "$root" "$system/sw/bin/stat" -c \
      'path=%n type=%F mode=%a uid=%u gid=%g owner=%U group=%G' \
      /var/lib/nixos-bootstrap \
      /var/lib/nixos-bootstrap/mei-password.hash || true
    ;;
  *) echo 'target system profile is missing or unexpected' >&2 ;;
esac

if [ -f "$hash" ] && [ ! -L "$hash" ] \
  && grep -Eqx '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{1,86}\$[./A-Za-z0-9]{43}$' "$hash"; then
  echo 'bootstrap verifier shape=yescrypt'
else
  echo 'bootstrap verifier shape=missing-or-invalid'
fi
```

Do not substitute `nixos-enter` for the direct `chroot` command:
`nixos-enter` runs activation before executing its requested command. Expected
metadata is numeric owner `0:0`, mode `700` for the real directory, and mode
`600` for the real regular file. During the first activation, numeric `0:0` may
display as `UNKNOWN:UNKNOWN` inside the target because its passwd and group
databases have not been created yet. Repeating `chown 0:0` cannot change that
name-resolution result.

If `/mnt` is still correctly mounted and the existing verifier is valid, the
corrected checkout can reuse both without running Disko again. Run only the
install phase from the patched checkout on the working computer.

**Bash:**

```bash
NIXOS_ANYWHERE_REV=4dfb813db065afb0aba1f61658ef77993d382db1
env -u SSH_AUTH_SOCK \
  nix run "github:nix-community/nixos-anywhere/$NIXOS_ANYWHERE_REV" -- \
  --flake '.#x86_64-linux' \
  --target-host "root@$TARGET" \
  --ssh-option IdentityAgent=none \
  --build-on local \
  --phases install \
  --chown var/lib/nixos-bootstrap 0:0 \
  --no-substitute-on-destination \
  --option max-jobs 1 \
  --option cores 1
```

**Nushell:**

```nu
let target = "192.168.1.123"
let nixos_anywhere_rev = "4dfb813db065afb0aba1f61658ef77993d382db1"
let recovery_args = [
  "--flake" ".#x86_64-linux"
  "--target-host" $"root@($target)"
  "--ssh-option" "IdentityAgent=none"
  "--build-on" "local"
  "--phases" "install"
  "--chown" "var/lib/nixos-bootstrap" "0:0"
  "--no-substitute-on-destination"
  "--option" "max-jobs" "1"
  "--option" "cores" "1"
]
^env -u SSH_AUTH_SOCK nix run $"github:nix-community/nixos-anywhere/($nixos_anywhere_rev)" -- ...$recovery_args
```

Use `.#aarch64-linux` for ARM. The install-only command deliberately omits
`--extra-files`: it reuses the already-staged verifier and does not reboot. If
`/mnt` is no longer mounted, replace the `--phases install` pair with
`--disko-mode mount`; do not combine them. This pinned nixos-anywhere
[recovery mode](https://github.com/nix-community/nixos-anywhere/blob/4dfb813db065afb0aba1f61658ef77993d382db1/docs/howtos/disko-modes.md)
mounts existing filesystems without formatting, installs, and reboots. Do not
rerun the password helper unchanged as recovery: its normal invocation includes
the destructive Disko format phase.

## 6. First boot and login

Log in locally as `mei` with the unique password entered in step 5. SSH key access
is also available if the target contains the configured public key.

Confirm that the installed system and user are correct:

```bash
hostnamectl
id mei
sudo nixos-version
```

`hostnamectl` should report `nixos` for the `x86_64-linux` output and
`nixos-aarch64` for the `aarch64-linux` output. These values come from the Den
host entity through its `hostname` battery, not from architecture checks inside
the NixOS module.

The bootstrap file should now contain only the consumed sentinel, while the real
verifier remains protected in `/etc/shadow`:

```bash
sudo stat -c '%u:%g %U:%G %a %n' /var/lib/nixos-bootstrap/mei-password.hash
printf '!\n' | sudo cmp -s - /var/lib/nixos-bootstrap/mei-password.hash
```

Expected ownership/mode is `0:0 root:root 600`; `cmp` should succeed without
printing the sentinel. Do not print the bootstrap file or copy the `mei` entry
from `/etc/shadow`.

Confirm that the wallpaper transfer and Wi-Fi stack are available:

```bash
find "$HOME/Pictures/Wallpapers" -mindepth 1 -maxdepth 1 -type f -print -quit
nmcli radio wifi on
nmcli device status
nmcli --fields IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan yes
```

The first command should print one transferred wallpaper, and `nmcli` should
show a Wi-Fi device and nearby networks. This profile enables NetworkManager,
the wireless regulatory database, and redistributable device firmware. If no
Wi-Fi device appears after applying this configuration and rebooting, capture
the hardware and driver state without changing it:

```bash
rfkill list
lspci -nnk | grep -A3 -Ei 'network|wireless'
sudo journalctl -b -k --no-pager | grep -Ei 'firmware|wifi|wireless|wlan|iwl|ath|rtw|brcm'
```

## 7. Create the machine's working checkout

The installer evaluates the temporary checkout but does not create a normal Git
working tree in `mei`'s home directory. After logging in on the installed machine:

```bash
git clone https://github.com/Meillaya/nix-config.git ~/nix-config
cd ~/nix-config
```

Record and apply this machine's disk ID again if you want the checkout to remain
reinstall-ready. Keep the edit local unless the repository gains a dedicated
disk configuration for this machine:

**Bash:**

```bash
DISK='/dev/disk/by-id/nvme-THIS_MACHINES_DISK_ID'
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

**Nushell:**

Replace only the value assigned to `disk_id`; leave `literal_placeholder`
unchanged.

```nu
let disk_id = "/dev/disk/by-id/nvme-THIS_MACHINES_DISK_ID"
let path = "modules/nixos/disk-config.nix"
let literal_placeholder = "/dev/%DISK%"
let text = (open --raw $path)
if not ($text | str contains $literal_placeholder) {
  error make {msg: $"missing placeholder: ($literal_placeholder)"}
}
$text | str replace $literal_placeholder $disk_id | save --force $path
```

For routine configuration changes, build and switch from this checkout:

```bash
cd ~/nix-config
nix run .#build-switch
```

The consumed sentinel remains valid on subsequent rebuilds because `mei` already
has an unlocked password. The helper is only needed for a fresh installation or
a destructive reinstall.

Remove the temporary working-computer checkout when it is no longer needed:

**Bash:**

```bash
rm -rf -- "$WORK"
```

**Nushell:**

```nu
rm -rf $work
```

## 8. Recovery if first login fails

If the helper was not used or first login fails, boot the ISO again and mount the
installed system manually. This repo's Disko layout does not declare filesystem
labels, so identify the root and EFI partitions first:

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
