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
target="$base/addon"
temp_output="$base/output"

log "Operating in $base"

mkdir -p "$temp_output"

if [ -z "`which mksquashfs`" ]; then
  log "Installing squashfs tools"
  apt-get -y install squashfs-tools
fi

for addon in "$@"; do
  [ -e "$addon" ] || \
    error "Addon not found: $addon"
  # from http://superuser.com/a/196655
  ! [ -f "$output" ] || \
    [ "`stat -c '%d:%i' \"$addon\"`" != "`stat -c '%d:%i' \"$output\"`" ] || {
    error "Can not use $addon as input because it is also the output."
  }
  log "Working with $addon"
  mkdir -p "$target"
  unsquashfs -f -d "$target" "$addon" || \
    error "Could not unsquash"
  log "Copy $target"
  log "  to $temp_output"
  log "Attempting hard link to save space"
  cp -rflTP "$target" "$temp_output" || {
    log "Hard link failed. Falling back to copy."
    cp -rfuTP "$target" "$temp_output" || \
      error "Could not copy addon"
  }
  rm -r "$target" || \
    error "Could not remove previous addon."
done

log "squashing $temp_output"
log "       to $output"
log "Content: "`ls "$temp_output"`
mksquashfs "$temp_output" "$output" -noappend || \
  error "Could not squash"

rm -rf "$base"

exit 0



