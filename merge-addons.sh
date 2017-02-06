#!/bin/bash

output="$1"
shift

log() {
  echo "$0 - $@"
}

error() {
  log "$@"
  exit 1
}

help() {
  echo " $0 OUTPUT-ADDON ADDON [ADDON]..."
  echo ""
  echo "  Merge the ADDONs into the OUTPUT-ADDON."
}


if [ -z "$output" ] || [ -z "$1" ]; then
  help
  exit 1
fi

base="/tmp/`basename \"output\"`-`date '+%N'`"
source="$base/source/"

mkdir -p "$source"


if [ -z "`which mksquashfs`" ]; then
  log "Installing squashfs tools"
  apt-get -y install squashfs-tools
fi

log "Mounting addons."
for addon in "$@"; do
  [ -e "$addon" ] || \
    error "Addon not found: $addon"
  # from http://superuser.com/a/196655
  ! [ -f "$output" ] || \
    [ "`stat -c '%d:%i' \"$addon\"`" != "`stat -c '%d:%i' \"$output\"`" ] || {
    error "Can not use $addon as input because it is also the output."
  }
  log "Add loopback device http://unix.stackexchange.com/a/198637/27328"
  losetup -f
  mount "$addon" "$source" || \
    error "Could not mount to $source"
  mksquashfs "$source" "$output" || \
    error "Could not squash to $output"
  umount "$source"
done



