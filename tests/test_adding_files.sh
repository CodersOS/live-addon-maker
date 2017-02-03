#!/bin/bash

source test.sh

addon -c "touch /asd"
expect adding_files_empty_asd "touching file in root"

addon -c "echo 'asdasd' >> /asd"
expect adding_files_asd_with_content "adding content to file"

