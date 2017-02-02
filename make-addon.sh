#!/bin/bash

help() {
  echo "

   make-addon.sh ISO OUTPUT-FILE [-b BEFORE-COMMAND] COMMAND [ARG]...

   - ISO
     is the iso image to create the addon for.
   - OUTPUT-FILE
     Is the file to which the addon should be saved.
     It must have either ending 'ext2' or 'squashfs'.
   - BEFORE-COMMAND
     This command is run and the changes are note recorded in the OUTPUT-FILE.
   - COMMAND
     is a command to run. It will be executed as root.
     It can have optional arguments ARG.
     The changes made by this command are recorded and written to OUTPUT-FILE.
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
if [ "$1" == "-b" ]
then
  shift
  before_command="$1"
  shift
else
  before_command=""
fi
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
# and https://help.ubuntu.com/community/LiveCDCustomizationFromScratch
mkdir "$host_copy/etc" || \
  error "Could not create sub directories for host."
cp -vr "/etc/resolvconf" "$host_copy/etc/resolvconf" || \
  error "Could not copy resolvconf"
cp "/etc/resolv.conf" "$host_copy/etc/resolv.conf" || \
  error "Could not copy resolv.conf"
cp "/etc/hosts" "$host_copy/hosts"
mount_special_file_systems() {
  mkdir "$1/sys" "$1/proc" "$1/dev" || \
    error "Could not create sub directories for $1."
  sudo mount --rbind "/sys" "$1/sys" || error "Could not mount sys."
  sudo mount --rbind "/dev" "$1/dev" || error "Could not mount dev."
  sudo mount -t proc none "$1/proc"  || error "Could not mount proc."
}
mount_special_file_systems "$host_copy"
#mount_special_file_systems "$data"

log "Mounting aufs for -b option to $root"
mount -t aufs -o "br=$host_copy:$fs_mount=rr" none "$root/" || \
  error "Could not mount."

log "Setting up change-root environment"
chroot "$root" <<EOF
  set -e
  # Set up several useful shell variables
  export HOME=/root
  export LANG=C
  export LC_ALL=C
  #  To allow a few apps using upstart to install correctly. JM 2011-02-21
  dpkg-divert --local --rename --add /sbin/initctl
  ln -s /bin/true /sbin/initctl
EOF
[ "$?" == 0 ] || error "Could not setup changeroot environment."

if [ -n "$before_command" ]
then
  log "Executing -b option: $before_command"
  chroot "$root" $before_command
  [ "$?" == 0 ] || error "-b failed."
fi

log "Mounting aufs for recording to $root"
umount "$root"
mount -t aufs -o "br=$data:$host_copy=ro:$fs_mount=rr" none "$root/" || \
  error "Could not mount."

log "Executing in $root:"
log "  $@"
chroot "$root" "$@" || \
  error "Error in command."

log "Unmounting"
for dir in "$root" "$fs_mount" "$iso_mount" "$host_copy/sys" "$host_copy/dev" "$host_copy/proc" "$data/proc" "$data/dev" "$data/sys"; do
  umount "$dir" &&  rm -rf "$dir"
done

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
  umount "$output"
  bytes="`du -s --block-size=1 | grep -oE '^\S+'`"
  # multiplying bytes to not just trust the computation
  bytes="$((bytes * 2 + 100000))"
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

