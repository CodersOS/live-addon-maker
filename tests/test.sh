#!/bin/bash

if [ -z "$_initialized" ]; then
  _iso="`ls ../*.iso | head -n 1`"
  _addon=/tmp/test.squashfs
  _mount=/tmp/test.squashfs-mount
  _ok=0
  _fail=0
  _skip=0
  _output=/tmp/test-output.txt
   _initialized=true
  _error=0
  for option in "$@"; do
    case "$option" in
      -a)
        SHOW_ADDON_OUTPUT="true" ;;
      -t=*)
        MATCH_TEST_CASE="${option#-t=}" ;;
    esac
  done
  _merge_addon="/tmp/merge-addon"
fi

# make an empty directory because git cannot to that
mkdir -p "empty"

output() {
  [ "$1" == "color" ] && echo -e -n "\e[1;34m"
  cat "$_output" | sed 's/^/    /'
  [ "$1" == "color" ] && echo -n -e "\e[0m"
}

addon() {
  matches_testcase || return
  touch "$_output"
  if [ "$SHOW_ADDON_OUTPUT" == "true" ]; then
    sudo ../make-addon.sh "$_iso" "$_addon" "$@"
  else
    sudo ../make-addon.sh "$_iso" "$_addon" "$@" 1>> "$_output" 2>> "$_output"
  fi
  _error="$?"
  if [ "$_error" != "0" ]; then
    echo "FAIL make-addon.sh $_iso $_addon $@"
    [ "$SHOW_ADDON_OUTPUT" == "true" ] || output
    did_fail "addon failed with error code $_error"
  fi
}

merge() {
  if [ -z "`which mksquashfs`" ]; then
    1>&2 echo "Installing squashfs tools"
    apt-get -y install squashfs-tools
  fi
  i=0
  local addons=""
  for folder in "$@"; do
    i="$((i + 1))"
    local addon="${_merge_addon}-${i}.squashfs"
    mksquashfs "$folder" "$addon" -noappend 1>"$_output" 2>"$_output" || {
      output
      echo "ERROR: Could not squash addon"
      return 1
    }
    local addons="$addons $addon"
  done
  sudo ../merge-addons.sh "$_addon" $addons 2>"$_output" 1>"$_output" || {
    local error="$?"
    output
    echo "ERROR: merge-addons.sh $_addon $addons"
    echo "       exited with $error"
    return 1
  }
}

did_ok() {
  _ok=$((_ok + 1))
  1>&2 echo -e "\e[1;32mOK   $testcase $@\e[0m"
}

did_fail() {
  _fail=$((_fail + 1))
  1>&2 echo -e "\e[1;31mFAIL $testcase $@\e[0m"
}

did_skip() {
  _skip=$((_skip + 1))
  1>&2 echo -e "\e[1;33mSKIP $testcase $@\e[0m"
}

expect() {
  local test="$1"
  local message="$2"
  maybe_skip "$message" || return
  [ "$_error" == "0" ] || return
  mkdir -p "$_mount"
  sudo umount "$_mount" 2>/dev/null
  sudo mount "$_addon" "$_mount" 1>"$_output" 2>"$_output" || {
    output
    did_fail "$message"
    return
  }
  if [ -d "$test" ]; then
    2>&1 diff -rq --no-dereference "$_mount" "$test" > "$_output" || {
      output color
      did_fail "$message (\"$_mount\" \"$test\")"
      return
    }
  else
    (
      cd "$_mount"
      bash -c "$test" 1>"$_output" 2>"$_output"
      exit "$?"
    )
    local error="$?"
    [ "$error" == "0" ] || {
      output color
      did_fail "$message (\"$_mount\" \"$test\")"
    }
  fi
  did_ok "$message"
}

maybe_skip() {
  matches_testcase && return 0
  did_skip "$1"
  return 1
}

matches_testcase() {
  echo "$testcase" | grep -qe "$MATCH_TEST_CASE"
}

summarize() {
  1>&2 echo -e "\e[1;31mERROR: $_fail \e[1;32mSUCCESS: $_ok\e[1;33m SKIPPED: $_skip\e[0m"
}

testcase() {
  testcase="[$1]"
}

exit_tests() {
  if [ "$_fail" != "0" ] || [ "$_skip" != "0" ]; then
    exit 1
  fi
  exit 0
}
