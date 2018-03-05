#!/bin/bash

# Static variables
[ "x$MOODEREL" = "x" ] && MOODEREL=r40
[ "x$TMPDIR" = "x" ] && TMPDIR=/tmp/moode
[ "x$IMG_ROOT" = "x" ] && IMG_ROOT=root
[ "x$IMG_SIZE" = "x" ] && IMG_SIZE=3G
[ "x$ENABLE_CCACHE" = "x" ] && ENABLE_CCACHE=1
[ "x$CCACHE_DIR" = "x" ] && CCACHE_DIR=/var/cache/ccache
[ "x$CREATE_ZIP" = "x" ] && CREATE_ZIP=0
[ "x$DELETE_TMP" = "x" ] && DELETE_TMP=0

# Dynamic variables
MOODENAME=$(date +%Y-%m-%d)-moode-$MOODEREL
STARTDIR=$PWD

# Check launch parameters (file)
if [ ! "$1x" = "x" ]
then
	BATCHFILE=$(realpath $1)
	if [ ! -f $1 ]
	then
		echo "File $1 not exists!"
		exit 1
	fi
fi

[ ! -d $TMPDIR ] && mkdir $TMPDIR
cd $TMPDIR

# Download the image
ZIPNAME=$(basename $(wget -nc -q -S --content-disposition https://downloads.raspberrypi.org/raspbian_lite_latest 2>&1 | grep Location: | tail -n1 | awk '{print $2}'))
# Unzip the image
unzip -n $ZIPNAME
# Retrieve the image name
IMGNAME=$(unzip -v $ZIPNAME | grep ".img" | awk '{print $8}')
# Extend the image to $IMG_SIZE
truncate -s $IMG_SIZE $IMGNAME
# Repartition the image
sfdisk -d $IMGNAME | sed '$s/ size.*,//' | sfdisk $IMGNAME
# Create loopback devices for the image and its partitions
sudo losetup -f -P $IMGNAME
LOOPDEV=$(sudo losetup -j $IMGNAME | awk '{print $1}' | sed 's/.$//g')
# Check the root partition
sudo e2fsck -f $LOOPDEV"p2"
# Resize the root partition
sudo resize2fs $LOOPDEV"p2"

[ ! -d $IMG_ROOT ] && mkdir $IMG_ROOT

# Mount the image filesystems
sudo mount -t ext4 $LOOPDEV"p2" $IMG_ROOT
sudo mount -t vfat $LOOPDEV"p1" $IMG_ROOT/boot
sudo mount -t devpts /dev/pts $IMG_ROOT/dev/pts
sudo mount -t proc /proc $IMG_ROOT/proc

# Create CCACHE environment if set
if [ $ENABLE_CCACHE -eq 1 ]
then
	if [ ! -d $CCACHE_DIR ]
	then
		sudo mkdir $CCACHE_DIR
		sudo chown root:root $CCACHE_DIR
		sudo chmod 777 $CCACHE_DIR
	fi
	if [ ! -d $IMG_ROOT$CCACHE_DIR ]
	then
		sudo mkdir $IMG_ROOT$CCACHE_DIR
		sudo chmod 777 $IMG_ROOT$CCACHE_DIR
		sudo mount --bind $CCACHE_DIR $IMG_ROOT$CCACHE_DIR
	fi
	echo "cache_dir = $CCACHE_DIR" | sudo tee --append $IMG_ROOT/etc/ccache.conf
	sudo chroot root apt-get -y install ccache
fi

# Add header to run.sh in the image
cat <<EOF > $IMG_ROOT/home/pi/run.sh
#!/bin/bash

NPROC=\$(nproc)
BUILDHOSTNAME=\$(hostname)

echo "Moode Release: "\$MOODEREL
echo "Is CCACHE enabled: "\$ENABLE_CCACHE

if [ \$ENABLE_CCACHE -eq 1 ]
then
	 export PATH=/usr/lib/ccache:\$PATH
fi

echo ""
echo "gcc: "$CC" "\$(which gcc)
echo "g++: "$CPP" "\$(which g++)
echo ""
EOF
chmod +x $IMG_ROOT/home/pi/run.sh

# Run the batch in chrooted environment
if [ ! "x$1" = "x" ]
then
	cat $BATCHFILE >> $IMG_ROOT/home/pi/run.sh
	sudo chroot root su - pi -c "MOODEREL=$MOODEREL ENABLE_CCACHE=$ENABLE_CCACHE /home/pi/run.sh" 2>&1 > $BATCHFILE.log
	rm $IMG_ROOT/home/pi/run.sh
else
	sudo chroot root su - pi -c "MOODEREL=$MOODEREL ENABLE_CCACHE=$ENABLE_CCACHE bash"
fi

# Remove CCACHE environment
if [ $ENABLE_CCACHE -eq 1 ]
then
	sudo chroot root apt-get -y purge ccache
	sudo rm -f $IMG_ROOT/etc/ccache.conf
	sudo umount $IMG_ROOT$CCACHE_DIR
	sudo rm -r $IMG_ROOT$CCACHE_DIR
fi

# Unmount everything
sudo umount $IMG_ROOT/proc
sudo umount $IMG_ROOT/dev/pts
sudo umount $IMG_ROOT/boot
sudo umount $IMG_ROOT
# Delete the loopback devices
sudo losetup -D

# Rename the image
mv $IMGNAME $MOODENAME".img"

# ZIP the image if set
if [ $CREATE_ZIP -eq 1 ]
then
	zip $MOODENAME".zip" $MOODENAME".img"
	rm $MOODENAME".img"
	mv $MOODENAME".zip" $STARTDIR/
else
	mv $MOODENAME".img" $STARTDIR/
fi

# Delete TMP directory
[ $DELETE_TMP -eq 1 ] && sudo rm -rf $TMPDIR

cd $STARTDIR
