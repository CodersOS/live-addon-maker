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
sources="$base/sources/"
mount_order=""

mkdir -p "$sources"

log "Mounting addons."

i=0
for addon in "$@"; do
  # from http://superuser.com/a/196655
  ! [ -f "$output" ] || \
    [ "`stat -c '%d:%i' \"$addon\"`" != "`stat -c '%d:%i' \"$output\"`" ] || {
    error "Can not use $addon as input because it is also the output."
  }
  i=$((i + 1))
  number="`printf '%0*d\n' 3 $i`"
  dir="$sources/$number-`basename \"$addon\"`"
  log "preparing addon $addon"
  mkdir -p "$dir"
  mount "$addon" "$dir" || \
    error "Could not mount to $dir"
  mount_order="$dir=ro:$mount_order"
done

mount_order="${mount_order%:}"

target="$base/output"
mkdir -p "$target"

mount -t aufs -o dirs="$mount_order" none "$target"

if [ -z "`which mksquashfs`" ]; then
  apt-get -y install squashfs-tools
fi

mksquashfs "$target" "$output" -noappend || \
  error "Could not squash to $output"


