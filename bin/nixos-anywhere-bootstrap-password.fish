#!/usr/bin/env fish

set script_dir (path dirname (status filename))
exec "$script_dir/nixos-anywhere-bootstrap-password.sh" $argv
