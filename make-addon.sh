#!/bin/bash

CLEAN=true
HARDLINK=true

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
     Is the file to which the addon is saved.
     It should have the ending '.squashfs'.

   -a --add FILE-OR-DIRECTORY TARGET-DIRECTORY
     FILE-OR-DIRECTORY will be at the path DESTINATION after this.
     Directories may be mounted and files hard-linked to save space.
     The copied files and folders are included in the addon.

   -A --map DIRECTORY TARGET-DIRECTORY
     Mount a DIRECTORY to a specific TARGET-DIRECTORY in the file system.

   -c --command COMMAND
     The COMMAND is executed as root and the result is included in the addon.

   -C --map-command COMMAND
     The COMMAND is executed but the result is not included in the addon.
     Example: cd /opt && wget https://example.com

   -s --startup-command NAME COMMAND
     The COMMAND is added to the startup routine with a NAME.
     It is executed as root when the system boots.

   -n --no-clean
     Do not clean the files and directories used for this.

   -H --no-hardlink
     Do not hardlink files.

   Each option is executed in the order it is passed to the script.
   If you do --map and then --command, you can use what you mapped.
   If you do --command and then --map, what you want to map is not
   available for the command.

   The /tmp folder is excluded from the addon.
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
  add_with_persistence "$1" "$2" "mount_persistent"
}

add_with_persistence() {
  file_or_directory="$1"
  target="$2"
  persistence="$3"
  directory="`create_new_mount_directory`"
  "$persistence" "$directory" || \
    error "Could not do $persistence $directory"
  target_directory="`mount_directory_to_data_directory \"$directory\"`"
  add_to_directory "$file_or_directory" "$target_directory/$target"
}

add_to_directory() {
  source="$1"
  target="$2"
  [ -e "$target" ] || mkdir -p "$target"
  if [ -d "$source" ]; then
    if [ "$target" == "/" ] ; then
      log "Mounting $source"
      log "      to $target"
      mount --bind "$source" "$target" && \
        return
      log "Mount failed. Copying files."
    fi
    log "Copying content from $source"
    log "                  to $target"
    log "Attempting hard link to save space"
    [ "$HARDLINK" == "true" ] && cp -rlTP "$source" "$target" || {
      log "Hard link failed. Copying now"
      cp -ruTP "$source" "$target"
    } || \
      error "Could not copy files"
    log "Done copying"
  else
    log "Attempting hard link to save space"
    [ "$HARDLINK" == "true" ] && ln -v -t "$target" "$source" || {
      log "Hard link failed. Copying."
      cp -v -t "$target" "$source" || \
        error "Could not copy file"
    }
  fi
}

option_map() {
  add_with_persistence "$1" "$2" "mount_volatile"
}

option_map_command() {
  execute_command_with_persistence "$1" "mount_volatile"
}

option_command() {
  execute_command_with_persistence "$1" "mount_persistent"
}

execute_command_with_persistence() {
  command="$1"
  persistence="$2"
  directory="`create_new_mount_directory`"
  "$persistence" "$directory" || \
    error "Could not do $persistence $directory"
  execute_command "$directory" "$command"
}

systemd_script() {
  local name="$1"
  echo "[Unit]"
  echo "After=network.target"
  echo ""
  echo "[Service]"
  echo "ExecStart=$name"
  echo ""
  echo "[Install]"
  echo "WantedBy=default.target"
}

service_script() {
  local command="$1"
  echo "#!/bin/bash"
  echo -n "$command"
}


startup_added_to_mount_order="false"
option_startup_command() {
  local name="$1"
  local command="$2"
  [ -n "$name" ] && [ -n "$command" ] || \
    error "Missing parameter for startup option"
  echo "$name" | grep -vqE "[[:space:]]|'" || \
    error "The name \"$name\" contains spaces or '. Expected no space in name."
  local startup_dir="$base/startup"

  local root_bin_folder="/usr/local/bin"
  local root_service_folder="/etc/systemd/system"

  local absolute_bin_folder="$startup_dir$root_bin_folder"
  local absolute_service_folder="$startup_dir$root_service_folder"

  local bin_name="start-$name-service.sh"
  local service_name="$name.service"

  local absolute_bin_file="$absolute_bin_folder/$bin_name"
  local absolute_service_file="$absolute_service_folder/$service_name"

  local root_bin_file="$root_bin_folder/$bin_name"
  local root_service_file="$root_service_folder/$service_name"

  mkdir -p "$absolute_bin_folder" "$absolute_service_folder"
  systemd_script "$root_bin_file" > "$absolute_service_file"
  service_script "$command" > "$absolute_bin_file"
  chmod +x "$absolute_bin_file"
  chmod +x "$absolute_service_file"
  if [ "$startup_added_to_mount_order" == "false" ]; then
    mount_order="$startup_dir:$mount_order"
    mount_order_addon="$startup_dir:$mount_order_addon"
    startup_added_to_mount_order="true"
  fi
  linking="ln -s -t '/etc/systemd/system/default.target.wants/' '$root_service_file'"
  log "Executing $linking"
  execute_command_with_persistence "$linking" "mount_persistent"
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
  local addon_name="`basename \"$addon\"`"
  base="/tmp/${addon_name%.*}-`date +%N`"
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

create_new_mount_directory() {
  local i=0
  while true; do
    i=$((i + 1))
    local directory="$base/step-${i}-mount"
    [ -e "$directory" ] || break
  done
  1>&2 mkdir "$directory" || \
    1>&2 error "Could not create directory for step $i"
  echo -n "$directory"
}

mount_directory_to_data_directory() {
  directory="`echo -n \"$1\" | sed 's/mount$/data/'`"
  mkdir -p "$directory"
  echo -n "$directory"
}

mount_into() {
  order="$1"
  directory="$2"
  mkdir -p "$directory"
  log "Mounting aufs $order"
  log "           to $directory"
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
  log "In $directory"
  log "Executing $command"
  chroot "$directory" bash -c "$command" || \
    error "Error executing $command"
}

exclude() {
  echo "tmp"
}

write_addon() {
  data="$base/addon"
  exclude_file="$base/exclude.txt"
  exclude > "$exclude_file"
  type="${addon##*.}"
  mount_into "$mount_order_addon" "$data"
  log "Files: "`ls "$data"`
  log "Creating $type file $addon"
  if [ "$type" == "squashfs" ]; then
    if [ -z "`which mksquashfs`" ]; then
      log "Installing squashfs tools"
      apt-get -y install squashfs-tools
    fi
    mksquashfs "$data" "$addon" -noappend -no-progress -ef "$exclude_file" || \
      error "Could not squash to $addon"
  else
    error "Unrecognized type \"$type\"."
  fi
  log "Output: $addon"
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
    case "$option" in
      -a|--add)
        log_call option_add "$1" "$2"
        shift; shift ;;
      -A|--map)
        log_call option_map "$1" "$2"
        shift; shift ;;
      -C|--map-command)
        log_call option_map_command "$1"
        shift ;;
      -c|--command)
        log_call option_command "$1"
        shift ;;
      -s|--startup-command)
        log_call option_startup_command "$1" "$2"
        shift; shift ;;
      -n|--no-clean)
        log "No cleanup"
        CLEAN=false ;;
      -H|--no-hardlink)
        log "No hardlink"
        HARDLINK=false ;;
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
  (
    cd "$base"
    if [ "`echo step-*-mount`" != "step-*-mount" ]; then
      for dir in step-*-mount; do
        umount "$dir" 2>>/dev/null
      done
    fi
  )
  umount "$fs_mount"
  umount "$data"
  umount "$iso_mount"
  umount "$host_copy/sys" 2>>/dev/null
  umount "$host_copy/dev" 2>>/dev/null
  umount "$host_copy/proc"
}

main() {
  log_call parse_required_parameters "$1" "$2"; shift; shift
  log_call verify_parameters
  log_call mount_root_filesystem
  log_call setup_root_filesystem
  log_call initialize_mount_order
  log_call parse_options "$@"
  log_call write_addon
  log_call clean_up
}

main "$@"

exit 0
