# Calibre declarative boundary

This repo now manages the following Calibre preference files:

- `~/.config/calibre/gui.json`
- `~/.config/calibre/tweaks.json`
- `~/.config/calibre/save_to_disk.py.json`
- `~/.config/calibre/metadata_sources/global.json`
- `~/.config/calibre/conversion/page_setup.py`

## Why these files were chosen

These files express durable user preferences such as:

- save-to-disk templates
- metadata-source behavior
- conversion defaults
- UI/tweak preferences

They are comparatively stable and portable across machines.

## Intentionally not managed yet

The following Calibre files remain outside declarative management for now:

- `global.py.json`
- `gui.py.json`
- `customize.py.json`
- plugin ZIP payloads under `~/.config/calibre/plugins/`
- caches/history/runtime data

## Why they are excluded

Those files currently contain one or more of:

- machine-specific library paths
- Windows-specific historical paths
- installation UUIDs
- search history / recently opened files
- plugin payload references that are not yet packaged declaratively

## Future migration direction

If you want deeper Calibre migration later, the next reasonable step is to
create **sanitized templates** for:

- `global.py.json`
- `gui.py.json`
- `customize.py.json`

with machine-specific paths, installation identifiers, and history removed.
