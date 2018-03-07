#!/bin/bash

# Static variables
[ "x$MOODE_REL" = "x" ] && MOODE_REL=r40
[ "x$TMP_DIR" = "x" ] && TMP_DIR=/tmp/moode
[ "x$IMG_URL" = "x" ] && IMG_URL='https://downloads.raspberrypi.org/raspbian_lite_latest'
[ "x$IMG_ROOT" = "x" ] && IMG_ROOT=root
[ "x$IMG_SIZE" = "x" ] && IMG_SIZE=3G
[ "x$ENABLE_CCACHE" = "x" ] && ENABLE_CCACHE=1
[ "x$CCACHE_DIR" = "x" ] && CCACHE_DIR=/var/cache/ccache
[ "x$CREATE_ZIP" = "x" ] && CREATE_ZIP=0
[ "x$DELETE_TMP" = "x" ] && DELETE_TMP=0

# Dynamic variables
MOODENAME=$(date +%Y-%m-%d)-moode-$MOODE_REL
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

# Prepare directories
[ ! -d $TMP_DIR ] && mkdir $TMP_DIR >> $STARTDIR/$0.log
cd $TMP_DIR
[ ! -d $IMG_ROOT ] && mkdir $IMG_ROOT >> $STARTDIR/$0.log

# Download the image
echo -n "Downloading image from $IMG_URL..."
ZIPNAME=$(basename $(wget -nc -q -S --content-disposition $IMG_URL 2>&1 | grep Location: | tail -n1 | awk '{print $2}'))
echo "Done."
# Unzip the image
echo -n "Unzip the image $ZIPNAME..."
unzip -n $ZIPNAME > $STARTDIR/$0.log
echo "Done."
# Retrieve the image name
IMGNAME=$(unzip -v $ZIPNAME | grep ".img" | awk '{print $8}')
# Extend the image size to $IMG_SIZE
echo -n "Extend image size to $IMG_SIZE..."
truncate -s $IMG_SIZE $IMGNAME >> $STARTDIR/$0.log
echo "Done."
# Expand root partition in the image
echo -n "Expand root partition..."
sfdisk -d $IMGNAME | sed '$s/ size.*,//' | sfdisk $IMGNAME >> $STARTDIR/$0.log
echo "Done."
# Create loopback devices for the image and its partitions
echo -n "Creating loop devices..."
sudo losetup -f -P $IMGNAME >> $STARTDIR/$0.log
LOOPDEV=$(sudo losetup -j $IMGNAME | awk '{print $1}' | sed 's/.$//g')
echo "Done."
# Check the root partition
echo -n "Check root filesystems..."
sudo e2fsck -f $LOOPDEV"p2"
echo "Done."
# Resize the root partition
echo -n "Resize root partition..."
sudo resize2fs $LOOPDEV"p2"
echo "Done."

# Mount the image filesystems
echo -n "Mounting all the partitions in $IMG_ROOT..."
sudo mount -t ext4 $LOOPDEV"p2" $IMG_ROOT >> $STARTDIR/$0.log
sudo mount -t vfat $LOOPDEV"p1" $IMG_ROOT/boot >> $STARTDIR/$0.log
sudo mount -t devpts /dev/pts $IMG_ROOT/dev/pts >> $STARTDIR/$0.log
sudo mount -t proc /proc $IMG_ROOT/proc >> $STARTDIR/$0.log
echo "Done."

# Create CCACHE environment if set
if [ $ENABLE_CCACHE -eq 1 ]
then
	echo -n "Create CCACHE environment..."
	if [ ! -d $CCACHE_DIR ]
	then
		sudo mkdir $CCACHE_DIR >> $STARTDIR/$0.log
		sudo chown root:root $CCACHE_DIR >> $STARTDIR/$0.log
		sudo chmod 777 $CCACHE_DIR >> $STARTDIR/$0.log
	fi
	if [ ! -d $IMG_ROOT$CCACHE_DIR ]
	then
		sudo mkdir $IMG_ROOT$CCACHE_DIR >> $STARTDIR/$0.log
		sudo chmod 777 $IMG_ROOT$CCACHE_DIR >> $STARTDIR/$0.log
		sudo mount --bind $CCACHE_DIR $IMG_ROOT$CCACHE_DIR >> $STARTDIR/$0.log
	fi
	echo "cache_dir = $CCACHE_DIR" | sudo tee --append $IMG_ROOT/etc/ccache.conf
	sudo chroot root apt-get -y install ccache >> $STARTDIR/$0.log
	echo "Done."
fi

# Add header to run.sh in the image
echo -n "Add header to run.sh..."
cat <<EOF > $IMG_ROOT/home/pi/run.sh
#!/bin/bash

NPROC=\$(nproc)
BUILDHOSTNAME=\$(hostname)

echo "Moode Release: "\$MOODE_REL
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
chmod +x $IMG_ROOT/home/pi/run.sh >> $STARTDIR/$0.log
echo "Done."

# Run the batch in chrooted environment
if [ ! "x$1" = "x" ]
then
	echo -n "Running $BATCHFILE to build. Log file in $BATCHFILE.log..."
	cat $BATCHFILE >> $IMG_ROOT/home/pi/run.sh >> $STARTDIR/$0.log
	sudo chroot root su - pi -c "MOODE_REL=$MOODE_REL ENABLE_CCACHE=$ENABLE_CCACHE /home/pi/run.sh" 2>&1 > $BATCHFILE.log
	rm $IMG_ROOT/home/pi/run.sh >> $STARTDIR/$0.log
	echo "Done."
else
	sudo chroot root su - pi -c "MOODE_REL=$MOODE_REL ENABLE_CCACHE=$ENABLE_CCACHE bash"
fi

# Remove CCACHE environment
if [ $ENABLE_CCACHE -eq 1 ]
then
	echo -n "Clean CCACHE environment"...
	sudo chroot root apt-get -y purge ccache >> $STARTDIR/$0.log
	sudo rm -f $IMG_ROOT/etc/ccache.conf >> $STARTDIR/$0.log
	sudo umount $IMG_ROOT$CCACHE_DIR >> $STARTDIR/$0.log
	sudo rm -r $IMG_ROOT$CCACHE_DIR >> $STARTDIR/$0.log
	echo "Done."
fi

# Unmount everything
echo -n "Unmount all partitions..."
sudo umount $IMG_ROOT/proc >> $STARTDIR/$0.log
sudo umount $IMG_ROOT/dev/pts >> $STARTDIR/$0.log
sudo umount $IMG_ROOT/boot >> $STARTDIR/$0.log
sudo umount $IMG_ROOT >> $STARTDIR/$0.log
echo "Done."
# Delete the loopback devices
echo -n "Delete loopback device..."
sudo losetup -D >> $STARTDIR/$0.log
echo "Done."

# Rename the image
mv $IMGNAME $MOODENAME".img"

# ZIP the image if set
if [ $CREATE_ZIP -eq 1 ]
then
	echo -n "Zipping the image $MOODENAME.img in $STARTDIR..."
	zip $STARTDIR/$MOODENAME".zip" $MOODENAME".img" >> $STARTDIR/$0.log
	rm $MOODENAME".img" >> $STARTDIR/$0.log
	echo "Done."
else
	echo -n "Moving the image $MOODENAME.img in $STARTDIR..."
	mv $MOODENAME".img" $STARTDIR/ >> $STARTDIR/$0.log
	echo "Done."
fi

# Delete TMP directory
[ $DELETE_TMP -eq 1 ] && sudo rm -rf $TMP_DIR >> $STARTDIR/$0.log

cd $STARTDIR
