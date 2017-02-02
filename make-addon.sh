#!/bin/bash

help() {
  echo "

   make-addon.sh ISO OUTPUT-FILE COMMAND [ARG]...

   - ISO
     is the iso image to create the addon for.
   - OUTPUT-FILE
     Is the file to which the addon should be saved.
     It must have either ending 'ext2' or 'squashfs'.
   - COMMAND
     is a command to run. It will be executed as root.
     It can have optional arguments ARG
  "
}

log() {
  echo "$0 - $@"
}

error() {
  log "$@"
  exit 1
}

# input
iso="$1"
shift
output="$1"
shift
script="$1"

log "verifying parameters"
if [ -z "$iso" ] || [ -z "$script" ] || [ -z "$output" ]
then
  help
  exit 1
fi

log "Deriving parameters."
root="/tmp/`basename \"$script\"`-`basename \"$output\"`-`date +%N`"
iso_mount="${root}-iso"
fs_mount="${root}-fs"
data="${root}-data"

log "Creating directories $root and $data"
mkdir -p "$root"
for dir in "$data" "$iso_mount" "$fs_mount"; do
  mkdir "$dir" || error "$dir exists."
done

mount "$iso" "$iso_mount"

exit


mount -t aufs -o "br=$data:$fs=rr" none "$root/" || \
  error "Could not mount."

chroot "$root" "$@"

umount "$root"


