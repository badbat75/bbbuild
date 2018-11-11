# bbbuild
Release version 2.1.0

This project aims to build Moode on a vanilla raspbian with the maximum efficiency on compilation and execution, generating an image file to be installed on an SD card.

Usage:
```
bbbuild [arg1]
```
Where:

  *arg1* is the command to run or the bbb batch to be executed in chrooted environment.

Command available:
```	
mount <file>
    Mount the image <file> in the $BBB_CHROOTPATH

unmount
    Unmount the image
	
interactive <file>
    Mount the image <file> and run a bash shell in the chrooted environment.
	
lsbbb
    List bbb batch file present.

lswd
    List all the files present in the work directory

help
    This message
```

Environment variables:
```
OS_URL
    Default: https://downloads.raspberrypi.org/raspbian_lite_latest
    The URL where to download the base OS
BBB_WORKDIR
    Default: /tmp/moode
    The temporary directory where start the job
BBB_DELWORKDIR
    Default: 0
    Set to 1 to enable it. Delete everything after the build
BBB_CHROOTDIR
    Default: root
    The directory where the immage will be mounted
BBB_IMGDIR
    Default: images
    The directory where the created images will be stored
BBB_IMGSIZE
    Default: 3G
    The resizing value of the image expressed in GB
BBB_LOG
    Default: bbbuilder.log
    The name of the bbbuilder log
BBB_LOGDIR
    Default: logs
    The directory where logs will be generated
ENABLE_SQUASHFS
    Default: 1
    Set to 0 to disable it. Enable the creation of the SquashFS filesystem. See moode recipe.
CCACHE_ENABLED
    Default: 1
    Set to 0 to disable it. Enable the compiler cache. This will speedup everything from the 2nd time.
CCACHE_DIR
    Default: /var/cache/ccache
    Set the CCACHE directory
ZIP_FORMAT
    Default: none
    Set to XZ to use LZMA compression or ZIP to use ZIP compression. If not defined no compression is applied.
```
