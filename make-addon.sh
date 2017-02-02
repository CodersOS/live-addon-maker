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
host_copy="${root}-host"
data="${root}-data"
type="${output##*.}"

log "Creating directories."
mkdir -p "$root"
for dir in "$data" "$iso_mount" "$fs_mount" "$host_copy"; do
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

log "Copying environment from host."
# see https://github.com/fossasia/meilix/blob/master/build.sh
mkdir "$host_copy/sys" "host_copy/proc" "$host_copy/dev" "host_copy/etc" || \
  error "Could not create sub directories for host."
cp -vr /etc/resolvconf "$host_copy/etc/resolvconf" || \
  error "Could not copy resolvconf"
sudo mount --rbind "/sys" "$host_copy/sys" || error "Could not mount sys."
sudo mount --rbind "/dev" "$host_copy/dev" || error "Could not mount dev."
sudo mount -t proc none "$host_copy/proc"  || error "Could not mount proc."

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
  mksquashfs "$data" "$output" -noappend -no-progress || \
    error "Could not squash to $output"
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
  mv "$data/"* "$ext_mount" || \
    error "Could not copy files to $output"
  umount "$ext_mount"
else
  error "Unrecognized type \"$type\"."
fi

log "Output: $output"

