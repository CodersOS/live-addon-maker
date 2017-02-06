#!/bin/bash

source "test.sh"

testcase "one addon stays the same"
  merge adding_files_asd_with_content
  expect adding_files_asd_with_content "one addon as argument"

  merge example_startup_script example_startup_script
  expect example_startup_script "add example script twice"

testcase "order of merge"
  merge adding_files_asd_with_content adding_files_empty_asd
  expect adding_files_empty_asd "the content is overwritten"

  merge adding_files_empty_asd adding_files_asd_with_content
  expect adding_files_asd_with_content "the content is overwritten"
