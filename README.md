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
3. all `.dir` directories are mounted readonly. (Executable and access flags maybe lost because of the fat32 file system.)

**Summary**  

The `make-addon.sh` script creates `.squashfs` files as a basis to customize the image.
Without using any tool, you can also create a folder, e.g. `example.dir` in the folder of the `filesystem.squashfs` and put files there.

Tutorial
--------

I assume you work under an Ubuntu system.

- Install git:

        sudo apt-get -y install git

- Clone this repository:

        git clone https://github.com/CodersOS/live-addon-maker.git

- Change into the directory:

        cd live-addon-maker

Then, you can download an iso image for which you want to build an addon.

- Download an iso image of any Ubuntu release, e.g. Xubuntu, Lubuntu or Ubuntu:

        wget -c http://de.releases.ubuntu.com/16.10/ubuntu-16.10-desktop-amd64.iso

### Adding Files

We can add files to the live image.
This makes for a simple addon.
In the started live image, we want to find a file `README.txt`
in the `/home/` folder with a small explanation.

- Create a file:

        echo "This file was added to this live system." > README.txt

- Create an addon with the file:

        ./make-addon.sh *.iso example-file.squashfs -a README.txt /home/

- [Copy the addon onto the usb device][ia]

## Install An Addon
[ia]: #install-an-addon 

To install an addon, you can choose from these options:

- [Copy the addon to the usb device with an existing live system on it.][ia-exist]
- [Add the addon to an iso image][ia-add]

### Install Addon On Existing USB Device
[ia-exist]: #install-addon-on-existing-usb-device

I assume you created a live usb stick and the contents of an iso were copied onto the stick.
Then, you can find the `casper` folder somewhere on your usb device.
If not, there might be any folder with a file named `filesystem.squashfs`.

1. Copy your addon to the folder of the `filesystem.squashfs` file.
2. Then, you can eject/unmount the device and wait for the copied files to be synced onto the usb device.
3. Then, you can unplug it and plug into your computer.

### Add Addon To Iso Image
[ia-add]: #add-addon-to-iso-image

TODO: make a script: `addon-to-iso.sh *.iso new.iso *.squashfs`
