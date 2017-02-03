#!/bin/bash

CLEAN=true

parse_required_parameters() {
  iso="$1"
  shift
  addon="$1"
  shift
}


help() {
  echo "

   make-addon.sh ISO ADDON [OPTIONS]

   ISO
     is the iso image to create the addon for.

   ADDON
     Is the file to which the addon should be saved.
     It must have either ending 'ext2' or 'squashfs'.

   -a --add FILE-OR-DIRECTORY DESTINATION
     FILE-OR-DIRECTORY will be at the path DESTINATION after this.
     Directories may be mounted and files hard-linked to save space.
     The copied files and folders are included in the addon.

   -m --map DIRECTORY LOCATION
     Mount a directory to a specific location in the file system.

   -C --map-command COMMAND
     The COMMAND is executed but the result is not included in the addon.
     Example: cd /opt && wget https://example.com

   -c --command COMMAND
     The COMMAND is executed as root and the result is included in the addon.

   -s --startup-command
     The COMMAND is added to the startup routine of the image.
     It is executed as root when the system boots.

   -n --no-clean
     Do not clean the files and directories used for this.

   Each option is executed in the order it is passed to the script.
   If you do --map and then --command, you can use what you mapped.
   If you do --command and then --map, what you want to map is not
   available for the command.
  "
}

log() {
  echo -n "$0 - "
  if [ -n "$in_function" ]; then
    echo -n "$in_function - "
  fi
  echo "$@"
}

error() {
  log "ERROR:" "$@"
  exit 1
}

option_add() {
  error "TODO"
}

option_map() {
  error "TODO"
}

option_map_command() {
  error "TODO"
}

option_command() {
  error "TODO"
}

option_startup_command() {
  error "TODO"
}

verify_parameters() {
  if [ -z "$iso" ] || [ -z "$addon" ]; then
    help
    error "Did not find required parameters."
  fi
}

mount_root_filesystem() {
  base="/tmp/`basename \"$iso\"`-`basename \"$addon\"`-`date +%N`"
  iso_mount="$base/iso"
  fs_mount="$base/fs"
  mkdir "$base" || \
    error "Temporary failure: temporary name already taken."

  log "Mounting $iso"
  log "      to $iso_mount"
  mkdir "$iso_mount" "$fs_mount" || \
    error "Could not create directory."
  mount "$iso" "$iso_mount" || \
    error "Could not mount iso."

  log "Searching for filesystem"
  relative_filesystem_squashfs="`( cd \"$iso_mount\" && find -name filesystem.squashfs$
  [ -n "$relative_filesystem_squashfs" ] || \
    error "did not find filesystem.squashfs in $iso_mount"
  fs_squash="$iso_mount/$relative_filesystem_squashfs"

  log "Mounting $fs_squash"
  log "      to $fs_mount"
  mount "$fs_squash" "$fs_mount" || \
    error "Could not mount filesystem."
}

setup_root_filesystem() {
  host_copy="${root}/host"
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
  mount_special_file_systems "$host_copy"
}

mount_special_file_systems() {
  mkdir "$1/sys" "$1/proc" "$1/dev" || \
    error "Could not create sub directories for $1."
  sudo mount --rbind "/sys" "$1/sys" || \
    error "Could not mount sys."
  sudo mount --rbind "/dev" "$1/dev" || \
    error "Could not mount dev."
  sudo mount -t proc none "$1/proc"  || \
    error "Could not mount proc."
}

write_addon() {
  type="${addon##*.}"
  log "Creating $type file $addon"
  if [ "$type" == "squashfs" ]; then
    if [ -z "`which mksquashfs`" ]; then
      apt -y install squashfs-tools
    fi
    mksquashfs "$data" "$addon" -noappend -no-progress || \
      error "Could not squash to $addon"
#  elif [ "$type" == "ext2" ]; then
#    umount "$addon" 2>/dev/null
#    bytes="`du -s --block-size=1 | grep -oE '^\S+'`"
#    # multiplying bytes to not just trust the computation
#    bytes="$((bytes * 2 + 100000))"
#    log "Bytes: $bytes"
#    yes | head -c "$bytes" > "$addon"
#    mkfs.ext2 "$addon"
#    ext_mount="${base}/ext2"
#    mkdir "$ext_mount" || \
#      error "$ext_mount exists."
#    mount "$output" "$ext_mount"
#    mv "$data/"* "$ext_mount" || \
#      error "Could not copy files to $output"
#    umount "$ext_mount"
  else
    error "Unrecognized type \"$type\"."
  fi
  log "Output: $output"
}

log_call() {
  in_function=""
  log "$@"
  in_function="$1"
  "$@"
}

parse_options() {
  while [ -n "$1" ]; do
    option="$1"
    shift
    case $option in
      -a|--add)
        log_call option_add "$1" "$2"
        shift; shift ;;
      -m|--map)
        log_call option_map "$1" "$2"
        shift; shift ;;
      -C|--map-command)
        log_call option_map_command "$1"
        shift ;;
      -c|--command)
        log_call option_command "$1"
        shift ;;
      -s|--startup-command)
        log_call option_startup_command "$1"
        shift ;;
      -n|--no-clean)
        log "No cleanup"
        CLEAN=false ;;
      *)
        help
        error "Invalid option \"$option\"." ;;
    esac
  done
}

clean_up() {
  if [ "$CLEAN" == "false" ]; then
    log "Skipping clean up."
    return
  fi
  error "TODO"
}


log_call parse_required_parameters "$1" "$2"; shift; shift
log_call verify_parameters
log_call mount_root_filesystem
log_call setup_root_filesystem
log_call parse_options "$@"
log_call write_addon
log_call clean_up
