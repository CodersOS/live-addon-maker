#!/bin/bash

special="$1"
specials="/tmp/specials"
url="https://github.com/CoderDojoPotsdam/CoderDojoOS/archive/master.zip"

(
  set -e
  cd /tmp
  mkdir -p addon-specials
  cd addon-specials
  [ -d CoderDojoOS* ] || {
    wget -q -c "$url" && \
    unzip master.zip
  } || {
    echo "Could not unzip CoderDojoOS"
    exit 1
  }
  cd CoderDojoOS*/specials
  rm "$specials"
  ln -s "`pwd`" "$specials"
) || exit "$?"

print_specials() {
  (
    cd /tmp/specials
    find -name install.sh
  ) | sed 's/\.\//    /' | sed 's/\/install.sh//'
}

if [ -z "$special" ]; then
  echo "The first parameter should be the name of the special you want to install."
  echo "Please have a look at"
  echo "  https://github.com/CoderDojoPotsdam/CoderDojoOS/tree/master/specials"
  echo "And choose a special."
  echo "This is valid as first argument:"
  print_specials
  exit 2
fi

special_folder="$specials/$special"
install_file="$special_folder/install.sh"

if ! [ -f "$install_file" ]; then
  echo "Could not find special $special under $special_folder"
  echo "Please choose among"
  print_specials
  exit 3
fi

addon="z-`basename \"$special\"`.squashfs"
echo "Addon name: $addon"

sudo ./make-addon.sh *.iso "$addon" \
                     -A "$special_folder" "/special" \
                     -c "/special/install.sh" \
                     -n
