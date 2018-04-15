# rpi_moode_build
Release version 1.1

This project aim to have a build script that build Moode on a vanilla raspbian
generating an image file.

Usage:
```
rpi_moode_build [batchfile]
```
Where:

* *batchfile* is the file to be executed in chrooted environment

Environment variables:
```
MOODE_REL
    Default: r41
    Is the version of the moode package.
TMP_DIR
    Default: /tmp/moode
    The temporary directory where start the job
IMG_URL
    Default: https://downloads.raspberrypi.org/raspbian_lite_latest
    The URL where to download the base OS
IMG_ROOT
    Default: root
    The directory where the immage will be mounted
IMG_SIZE
    Default: 3G
    The resizing value of the image expressed in GB
ENABLE_SQUASHFS
    Default: 1
    Set to 0 to disable it. Enable the creation of the SquashFS filesystem. See moode recipe.
ENABLE_CCACHE
    Default: 1
    Set to 0 to disable it. Enable the compiler cache. This will speedup everything from the 2nd time.
CCACHE_DIR
    Default: /var/cache/ccache
    Set the CCACHE directory
CREATE_ZIP
    Default: 1
    Set to 0 to disable it. ZIP the image at the end of the build
DELETE_TMP
    Default: 0
    Set to 1 to enable it. Delete everything after the build
DEV_MODE
    Default: 0
    Set to 1 to enable it. Enable the developer mode: No download and unzip, the existing img file in the working directory is used. No rename, move and zip of the image after the build: DELETE_TMP and CREATE_ZIP is ignored.
```
