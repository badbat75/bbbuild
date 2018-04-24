#!/bin/bash

# Static variables
[ "x$MOODE_REL" = "x" ] && MOODE_REL=r41
[ "x$TMP_DIR" = "x" ] && TMP_DIR=/tmp/moode
[ "x$IMG_URL" = "x" ] && IMG_URL='https://downloads.raspberrypi.org/raspbian_lite_latest'
[ "x$IMG_ROOT" = "x" ] && IMG_ROOT=root
[ "x$IMG_SIZE" = "x" ] && IMG_SIZE=3G
[ "x$ENABLE_SQUASHFS" = "x" ] && ENABLE_SQUASHFS=1
[ "x$ENABLE_CCACHE" = "x" ] && ENABLE_CCACHE=1
[ "x$CCACHE_DIR" = "x" ] && CCACHE_DIR=/var/cache/ccache
[ "x$CREATE_ZIP" = "x" ] && CREATE_ZIP=1
[ "x$ZIP_FORMAT" = "x" ] && ZIP_FORMAT=ZIP
[ "x$DELETE_TMP" = "x" ] && DELETE_TMP=0
[ "x$DEV_MODE" = "x" ] && DEV_MODE=0

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

# In DEV mode, there's no download and unzip, the existing img file is used
if [ $DEV_MODE -eq 0 ]
then
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
else
	IMGNAME=$(ls *.img 2>/dev/null)
	[ ! $? -eq 0 ] && echo "No images found!!!" && exit $?
	IMGNAME=$(echo $IMGNAME | head -n1 )
fi

# Extend the image size to $IMG_SIZE
echo -n "Extend image size to $IMG_SIZE..."
truncate -s $IMG_SIZE $IMGNAME >> $STARTDIR/$0.log
echo "Done."
# Expand root partition in the image
echo -n "Expand root partition..."
PARTINFO=$(sfdisk -d $IMGNAME | tail -n1)
sfdisk --delete $IMGNAME 2
echo $PARTINFO | sed '$s/ size.*,//' | sfdisk --append $IMGNAME >> $STARTDIR/$0.log 2>&1
echo "Done."
# Create loopback devices for the image and its partitions
echo -n "Creating loop devices..."
sudo losetup -f -P $IMGNAME >> $STARTDIR/$0.log
LOOPDEV=$(sudo losetup -j $IMGNAME | awk '{print $1}' | sed 's/.$//g')
echo "Done."
# Check the root partition
echo -n "Check root filesystems..."
sudo e2fsck -fp $LOOPDEV"p2" >> $STARTDIR/$0.log 2>&1
echo "Done."
# Resize the root partition
echo -n "Resize root partition..."
sudo resize2fs $LOOPDEV"p2" >> $STARTDIR/$0.log 2>&1
echo "Done."

# Mount the image filesystems
echo -n "Mounting all the partitions in $IMG_ROOT..."
sudo mount -t ext4 $LOOPDEV"p2" $IMG_ROOT >> $STARTDIR/$0.log 
sudo mount -t vfat $LOOPDEV"p1" $IMG_ROOT/boot >> $STARTDIR/$0.log
sudo mount -t tmpfs -o nosuid,nodev,mode=755 /run $IMG_ROOT/run >> $STARTDIR/$0.log
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
	echo "cache_dir = $CCACHE_DIR" | sudo tee --append $IMG_ROOT/etc/ccache.conf >> $STARTDIR/$0.log
	sudo chroot root apt-get -y install ccache >> $STARTDIR/$0.log
	echo "Done."
fi

# Add header to run.sh in the image
echo -n "Add header to run.sh..."
cat <<EOF > $IMG_ROOT/home/pi/run.sh
#!/bin/bash

set -x

NPROC=\$(nproc)
BUILDHOSTNAME=\$(hostname)

echo "Moode Release: "\$MOODE_REL
echo "Is SQUASHFS enabled: "\$ENABLE_SQUASHFS
echo "Is CCACHE enabled: "\$ENABLE_CCACHE

if [ \$ENABLE_CCACHE -eq 1 ]
then
	 export PATH=/usr/lib/ccache:\$PATH
	 export CC="ccache gcc"
	 export CXX="ccache g++"
fi

export CFLAGS="-O3"
export CXXFLAGS="-O3"
export MAKEFLAGS="-j\$NPROC"

echo ""
echo "C: "\$CC" "\$(which gcc)
echo "C flags: "\$CFLAGS
echo "C++: "\$CXX" "\$(which g++)
echo "C++ flags: "\$CXXFLAGS
echo "MAKE flags: "\$MAKEFLAGS
EOF
chmod +x $IMG_ROOT/home/pi/run.sh >> $STARTDIR/$0.log
echo "Done."

# Run the batch in chrooted environment
if [ ! "x$1" = "x" ]
then
	echo -n "Running $BATCHFILE to build. Log file in $BATCHFILE.log..."
	cat $BATCHFILE >> $IMG_ROOT/home/pi/run.sh
	sudo chroot $IMG_ROOT sudo -u pi MOODE_REL=$MOODE_REL ENABLE_CCACHE=$ENABLE_CCACHE ENABLE_SQUASHFS=$ENABLE_SQUASHFS /home/pi/run.sh > $BATCHFILE.log 2>&1
	echo "Done."
else
	echo "Interactive chroot mode. Press CTRL+D or type EXIT to close interactive chroot mode."
	sudo chroot $IMG_ROOT su - pi -c "MOODE_REL=$MOODE_REL ENABLE_CCACHE=$ENABLE_CCACHE ENABLE_SQUASHFS=$ENABLE_SQUASHFS bash"
	echo "Closed."
fi
rm $IMG_ROOT/home/pi/run.sh >> $STARTDIR/$0.log

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
sudo umount $IMG_ROOT/proc $IMG_ROOT/dev/pts $IMG_ROOT/run $IMG_ROOT/boot $IMG_ROOT >> $STARTDIR/$0.log
echo "Done."
# Delete the loopback devices
echo -n "Delete loopback device..."
sudo losetup -D >> $STARTDIR/$0.log
echo "Done."

# In DEV mode there's no rename, move and zip for the image 
if [ $DEV_MODE -eq 0 ]
then
	# Rename the image
	mv $IMGNAME $MOODENAME".img"

	# ZIP the image if set
	if [ $CREATE_ZIP -eq 1 ]
	then
		echo -n "Zipping the image $MOODENAME.img in $STARTDIR..."
		case $ZIP_FORMAT in
		ZIP)
			zip $STARTDIR/$MOODENAME".img.zip" $MOODENAME".img" >> $STARTDIR/$0.log &&
			rm -f $MOODENAME".img" >> $STARTDIR/$0.log
			;;
		XZ)	xz -T0 $MOODENAME".img" >> $STARTDIR/$0.log &&
			mv $MOODENAME".img.xz" $STARTDIR/ >> $STARTDIR/$0.log
			;;
		*)
			echo "Compression $ZIP_FORMAT not supported."
		esac
		echo "Done."
	else
		echo -n "Moving the image $MOODENAME.img in $STARTDIR..."
		mv $MOODENAME".img" $STARTDIR/ >> $STARTDIR/$0.log
		echo "Done."
	fi

	# Delete TMP directory
	[ $DELETE_TMP -eq 1 ] && sudo rm -rf $TMP_DIR >> $STARTDIR/$0.log
fi

cd $STARTDIR
