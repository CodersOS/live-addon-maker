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
type="${output##*.}"

log "Creating directories."
mkdir -p "$root"
for dir in "$data" "$iso_mount" "$fs_mount"; do
  mkdir "$dir" || error "$dir exists."
done

log "Mounting $iso"
log "      to $iso_mount"
mount "$iso" "$iso_mount" || \
  error "Could not mount iso."

log "Searching for filesystem"
relative_filesystem_squashfs="`( cd \"$iso_mount\" && find -name filesystem.squashfs )`"
[ -z "$relative_filesystem_squashfs" ] && \
  error "did not find filesystem.squashfs in $iso_mount"
fs_squash="$iso_mount/$relative_filesystem_squashfs"

log "Mounting $fs_squash"
log "      to $fs_mount"
mount "$fs_squash" "$fs_mount" || \
  error "Could not mount filesystem."

log "Mounting aufs to $root"
mount -t aufs -o "br=$data:$fs_mount=rr" none "$root/" || \
  error "Could not mount."

log "Executing in $root:"
log "  $@"
chroot "$root" "$@" || \
  error "Error in command."

umount "$root"
umount "$fs_mount"
umount "$iso_mount"

log "Result in $data: "`ls "$data"`

log "Creating $type file $output"
if [ "$type" == "squashfs" ]
then
  if [ -z"`which mksquashfs`" ]; then
    apt -y install squashfs-tools
  fi
  mksquashfs "$data" "$output"
elif [ "$type" == "ext2" ]
then
  bytes="`du -s --block-size=1 | grep -oE '^\S+'`"
  bytes="$((bytes + 100000))"
  log "Bytes: $bytes"
  yes | head -c "$bytes" > "$output"
  mkfs.ext2 "$output"
  ext_mount="${data}-ext2"
  mkdir "$ext_mount" || \
    error "$ext_mount exists."
  mount "$output" "$ext_mount"
  mv -t "$ext_mount" "$data"
  ummount "$ext_mount"
else
  error "Unrecognized type \"$type\"."
fi

log "Output: $output"

