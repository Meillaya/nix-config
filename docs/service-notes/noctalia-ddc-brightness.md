# Noctalia external monitor brightness on standalone Linux

Noctalia uses `brightnessctl` for internal backlights and `ddcutil` over
DDC/CI for external monitor brightness. On this machine the Noctalia settings
were already the right place to fix the UI, but the OS still had to expose the
I2C device nodes that `ddcutil` needs.

## Symptoms

- Noctalia Display settings showed monitor brightness sliders, but changing
  them did not change external monitor brightness.
- `~/.config/noctalia/settings.json` had DDC disabled originally:
  `brightness.enableDdcSupport = false`.
- `/sys/class/backlight` was empty, which is expected for external monitors.
- `ddcutil detect` failed with:

```text
No /dev/i2c devices exist.
ddcutil requires module i2c-dev.
```

## Fix in this repo

The Home Manager-managed Noctalia settings now enable DDC brightness and show
the brightness card:

- `modules/standalone-linux/config/noctalia/settings.json`
  - `brightness.enableDdcSupport = true`
  - `controlCenter.cards[].id == "brightness-card"` has `enabled = true`

The standalone Linux package set includes `ddcutil`:

- `modules/standalone-linux/packages.nix`

The NixOS host config also enables I2C access declaratively:

- `hosts/nixos/default.nix`
  - `hardware.i2c.enable = true`
  - user is in `i2c` and `video`

## One-time OS setup for existing non-NixOS Linux

Standalone Home Manager cannot safely own `/etc` kernel-module and udev files.
For an existing Arch/CachyOS-style install, run the helper installed by this
repo:

```bash
setup-ddc-brightness
```

That helper performs the root-level setup that made brightness work here:

```bash
sudo modprobe i2c-dev
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
sudo groupadd -f i2c
sudo usermod -aG i2c "$USER"
printf 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660", TAG+="uaccess"\n' \
  | sudo tee /etc/udev/rules.d/70-i2c.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Log out and back in if the helper adds your user to the `i2c` group.

## Verification

After setup, these commands should show I2C device nodes and detected displays:

```bash
ls /dev/i2c-*
ddcutil detect
```

If `ddcutil detect` reports that a display does not support DDC/CI, enable
DDC/CI in that monitor's physical on-screen menu.

Avoid restarting Niri or Noctalia just to verify DDC access. Once `ddcutil
detect` works, use Noctalia Display settings; if Noctalia needs a refresh,
toggle the external monitor brightness setting off and on from the UI.
