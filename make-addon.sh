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

log "Creating directories."
mkdir -p "$root"
for dir in "$data" "$iso_mount" "$fs_mount"; do
  mkdir "$dir" || error "$dir exists."
done

log "Mounting $iso to $iso_mount"
mount "$iso" "$iso_mount" || \
  error "Could not mount iso."

log "Searching for filesystem"
relative_filesystem_squashfs="`( cd \"$iso_mount\" && find -name filesystem.squashfs )`"
[ -z "$relative_filesystem_squashfs" ] && \
  error "did not find filesystem.squashfs in $iso_mount"
fs_squash="$iso_mount/$relative_filesystem_squashfs"

log "Mounting $fs_squash to $fs_mount"
mount "$fs_squash" "$fs_mount" || \
  error "Could not mount filesystem."

log "Mounting aufs to $root"
mount -t aufs -o "br=$data:$fs_mount=rr" none "$root/" || \
  error "Could not mount."

log "Executing in $root $@"
chroot "$root" "$@" || \
  error "Error in command."

umount "$root"
umount "$fs_mount"
umount "$iso_mount"

log "Result in $data: "`ls "$data"`


