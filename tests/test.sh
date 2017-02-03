#!/bin/bash

if [ -z "$_initialized" ]; then
  _iso="` echo ../*.iso`"
  _addon=/tmp/test.squashfs
  _mount=/tmp/test.squashfs-mount
  _ok=0
  _fail=0
  _output=/tmp/test-output.txt
   _initialized=true
  _error=0
fi

# make an empty directory because git cannot to that
mkdir -p "empty"

addon() {
  touch "$_output"
  sudo ../make-addon.sh "$_iso" "$_addon" "$@" 1>> "$_output" 2>> "$_output"
  _error="$?"
  if [ "$_error" != "0" ]; then
    echo "  make-addon.sh $_iso $_addon $@"
    cat "$_output" | sed 's/^/    /'
    did_fail "addon failed with error code $_error"
  fi
}

did_ok() {
  _ok=$((_ok + 1))
  1>&2 echo -e "\e[1;32mOK   $testcase $@\e[0m"
}

did_fail() {
  _fail=$((_fail + 1))
  1>&2 echo -e "\e[1;31mFAIL $testcase $@\e[0m"
}

expect() {
  [ "$_error" == "0" ] || {
    return
  }
  local folder="$1"
  local message="$2"
  mkdir -p "$_mount"
  sudo umount "$_mount" 2>/dev/null
  sudo mount "$_addon" "$_mount" || {
    did_fail "$message"
    return
  }
  2>&1 diff "$_mount" "$folder" > "$_output" || {
    cat "$_output" | sed 's/^/    /'
    did_fail "$message (\"$_mount\" \"$folder\")"
    return
  }
  did_ok "$message"
}

summarize() {
  1>&2 echo -e "\e[1;31mERROR: $_fail \e[1;32m SUCCESS: $_ok\e[0m"
}

testcase() {
  testcase="$1"
}