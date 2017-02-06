#!/bin/bash

source test.sh

testcase "copy to subdirectories"
  addon -a adding_files_asd_with_content/asd /sub
  expect add_to_subdirectory "add file to /sub"

  addon -a adding_files_asd_with_content/ /sub
  expect add_to_subdirectory "add directory to /sub"

