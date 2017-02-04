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
  echo -n
}

option_command() {
  command="$1"
  directory="`create_new_mount_directory`"
  mount_persistent "$directory"
  execute_command "$directory" "$command"
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

find_filesystem() {
  (
    cd "$iso_mount"
    find -name filesystem.squashfs
  )
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
  relative_filesystem_squashfs="`find_filesystem`"
  [ -n "$relative_filesystem_squashfs" ] || \
    error "did not find filesystem.squashfs in $iso_mount"
  fs_squash="$iso_mount/$relative_filesystem_squashfs"

  log "Mounting $fs_squash"
  log "      to $fs_mount"
  mount "$fs_squash" "$fs_mount" || \
    error "Could not mount filesystem."
}

setup_root_filesystem() {
  host_copy="$base/host"
  mkdir "$host_copy"
  log "Copying environment from host."
  # see https://github.com/fossasia/meilix/blob/master/build.sh
  # and https://help.ubuntu.com/community/LiveCDCustomizationFromScratch
  mkdir "$host_copy/etc" || \
    error "Could not create sub directory for host."
  cp -vr "/etc/resolvconf" "$host_copy/etc/resolvconf" || \
    error "Could not copy resolvconf"
  cp -v "/etc/resolv.conf" "$host_copy/etc/resolv.conf" || \
    error "Could not copy resolv.conf"
  cp -v "/etc/hosts" "$host_copy/hosts"
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

initialize_mount_order() {
  empty="$base/empty"
  mkdir "$empty" || \
    error "Could not create empty directory for addon files"
  [ -n "$host_copy" ] || \
    error "host_copy not initialized."
  [ -n "$fs_mount" ] || \
    error "fs_mount not initialized."
  mount_order="$host_copy=ro:$fs_mount=rr"
  mount_order_addon="$empty=ro"
}

_number_of_mounts=0

create_new_mount_directory() {
  _number_of_mounts=$((_number_of_mounts + 1))
  directory="$base/step-${_number_of_mounts}-mount"
  1>&2 mkdir "$directory" || \
    1>&2 error "Could not create directory for step $_number_of_mounts"
  echo -n "$directory"
}

mount_directory_to_data_directory() {
  directory="`echo -n \"$1\" | sed 's/mount$/data/'`"
  mkdir "$directory" ||
    error "Could not create data directory $directory"
  echo -n "$directory"
}

mount_into() {
  order="$1"
  directory="$2"
  mkdir -p "$directory"
  mount -t aufs -o "br=$order" none "$directory" || \
    error "Could not mount \"$order\" to \"$directory\""
}

mount_persistent() {
  mount_volatile "$1"
  mount_order_addon="$data_directory=ro:$mount_order_addon"
}

mount_volatile() {
  mount_directory="$1"
  data_directory="`mount_directory_to_data_directory \"$mount_directory\"`"
  mount_order="$data_directory:$mount_order"
  mount_into "$mount_order" "$mount_directory"
}

execute_command() {
  directory="$1"
  command="$2"
  chroot "$directory" bash -c "$command"
}

write_addon() {
  data="$base/addon"
  type="${addon##*.}"
  mount_into "$mount_order_addon" "$data"
  log "Creating $type file $addon"
  if [ "$type" == "squashfs" ]; then
    if [ -z "`which mksquashfs`" ]; then
      apt -y install squashfs-tools
    fi
    mksquashfs "$data" "$addon" -noappend -no-progress || \
      error "Could not squash to $addon"
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
  umount "$fs_mount"
  umount "$data"
  umount "$iso_mount"
  umount "$host_copy/sys"
  umount "$host_copy/dev"
  umount "$host_copy/proc"
  (
    cd "$base"
    if [ "`echo step-*`" != "step-*" ]; then
      for dir in step-*; do
        umount "$dir"
      done
    fi
  )
}


log_call parse_required_parameters "$1" "$2"; shift; shift
log_call verify_parameters
log_call mount_root_filesystem
log_call setup_root_filesystem
log_call initialize_mount_order
log_call parse_options "$@"
log_call write_addon
log_call clean_up

exit 0
