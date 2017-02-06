#!/bin/bash

iso="$1"
shift
output="$1"
shift

help() {
  echo " $0 SOURCE-ISO NEW-ISO ADDON [ADDON]..."
  echo ""
  echo "  Add ADDONs to the NEW-ISO basing it on SOURCE-ISO."
}

log() {
  echo "$0 - $@"
}

error() {
  log "$@"
  exit 1
}

find_filesystem() {
  (
    cd "$iso_mount"
    find -name filesystem.squashfs
  )
}

if [ -z "$iso" ] || [ -z "$output" ]; then
  help
  exit 1
fi

base="/tmp/`basename \"$output\"`-`date '+%N'`"
mkdir -p "$base"
iso_mount="$base/iso-mount"
mkdir "$iso_mount"
data="$base/data"
mkdir "$data"
new_iso="$base/new-iso"
mkdir "$new_iso"

log "Mounting iso to $iso_mount"
mount "$iso" "$iso_mount" || \
  error "Could not mount iso"

log "Looking for filesystem.squashfs"
relative_filesystem_squashfs="`find_filesystem`"
[ -n "$relative_filesystem_squashfs" ] || \
  error "did not find filesystem.squashfs in $iso_mount"

relative_addon_folder="`dirname \"$relative_filesystem_squashfs\"`"
log "Folder for addons: $relative_addon_folder"
addon_folder="$data/$relative_addon_folder"
mkdir -p "$addon_folder"

put_addons_into() {
  local folder="$1"
  shift
  for addon in "$@"; do
    log "Copy $addon"
    log "  to $addon_folder"
    log "Attempting hard link to save space"
    if ! ln -v -t "$addon_folder" "$addon"; then
      log "Hard link failed. Copying."
      cp -v -t "$addon_folder" "$addon" || \
        error "Could not copy file"
    fi
  done
}

if mount -t aufs -o "br=$data:$iso_mount=rr" none "$new_iso"; then
  log "Mounted filesystem to $iso_mount"
  put_addons_into "$data" "$@"
else
  log "Mount failed. Need to copy."
  cp -rPt "$new_iso" "$iso_mount"
  put_addons_into "$new_iso" "$@"
fi

(
  log "Creating md5 files"
  cd "$new_iso"
  find . -type f -print0 |xargs -0 sudo md5sum |grep -v "\./md5sum.txt" >md5sum.txt
)

if [ -z "`which mkisofs`" ]; then
  log "Installing iso image tools"
  apt-get -y install genisoimage
fi

log "Creating iso file $output"
log "             from $new_iso"
image_name="`basename \"${output%.*}\"`"

# see https://github.com/CodersOS/meilix/blob/2bf2f0914ac53a5dbf9a1012a8570988a5ccc4b3/build.sh#L277
mkisofs -r -V "$image_name" -cache-inodes -J -l \
        -allow-limited-size -udf \
        -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --publisher "CodersOS Packaging Team" \
        --volset "Ubuntu Linux http://www.ubuntu.com" \
        -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
        -A "$image_name" \
        -o "$output" "$new_iso" || \
  error "Could not create iso file"

umount "$new_iso"
umount "$iso_mount"

exit 0
