#!/bin/bash

help() {
  echo "

   make-addon.sh OUTPUT-FILE COMMAND [ARG]...

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
script="$1"
output="$2"

log "verifying parameters"
if [ -z "$script" ] || [ -z "$output" ]
then
  help
  exit 1
fi

log "Deriving parameters."
root="/tmp/`basename \"$script\"`-`basename \"$output\"`-`date +%N`"
data="${root}-data"

log "Creating directories $root and $data"
mkdir -p "$root"
mkdir "$data" || error "$data exists."

mount -t overlayfs -o "upperdir=$data,lowerdir=/" || \
  error "Could not mount the file system."

chroot "$root" "$script" || error "Could not execute $script"

umount "$root"


