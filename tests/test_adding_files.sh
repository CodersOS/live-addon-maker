#!/bin/bash

source test.sh

testcase "add file directly"
  addon -a adding_files_asd_with_content/asd /
  expect adding_files_asd_with_content "add file directly to /"

  addon -a adding_files_asd_with_content /
  expect adding_files_asd_with_content "add folder directly to /"

