live-addon-maker
================

[![Build Status](https://travis-ci.org/CodersOS/live-addon-maker.svg?branch=master)](https://travis-ci.org/CodersOS/live-addon-maker)

Customize your ubuntu iso images with additional software.

Ubunut live images come with software like Open Office and Pidgin for the end user.
Programmers need other tools.
We can equip USB devices with the additional software without changing the underlying system.
The installation is **just one copy and paste**:  

1. Copy an [example `.squashfs` file](examples) into the `casper` folder or wherever `filesystem.squashfs` is.
2. Boot and you can start the Python Shell.

Examples
--------

The are examples available in the [examples](examples#readme) folder.

History & Idea
--------------

We can use live distributions on USB-sticks. However, it is hard to customize them:
Using the [persistent mode](https://help.ubuntu.com/community/LiveCD/Persistence),
the system broke for me when I had software installed.
But, I found the following lines in the `caspter/initrd.lz/initrd/scripts/casper` in line 385 in `setup_unionfs()`:
```
    for image_type in "ext2" "squashfs" "dir" ; do
        for image in "${image_directory}"/*."${image_type}"; do
```
These lines go through all `.ext2`, `.squashfs` files and `.dir` folders and mount them.
`filesystem.squashfs` is just one of them. What happens:

1. all `.ext2` files are mounted readonly.
2. all `.squashfs` files are mounted readonly.
3. all `.dir` directories are mounted readonly.

Summary
~~~~~~~

The `make-addon.sh` script creates `.squashfs` files as a basis to customize image.
Without using any tool, you can also create a folder, e.g. `example.dir` in the folder of the `filesystem.squashfs` and put files there.


