#!/bin/bash

MOODEREL=r40
MOODENAME=$(date +%Y-%m-%d)-moode-$MOODEREL
TMPDIR=/tmp/moode
ENABLE_CCACHE=1
CREATE_ZIP=0
DELETE_TMP=0

STARTDIR=$PWD

[ ! -f $1 ] && echo "File $1 not exists!" && exit 1
[ ! "$1x" = "x" ] && BATCHFILE=$(realpath $1)

[ ! -d $TMPDIR ] && mkdir $TMPDIR
cd $TMPDIR

ZIPNAME=$(basename $(wget -nc -q -S --content-disposition https://downloads.raspberrypi.org/raspbian_lite_latest 2>&1 | grep Location: | tail -n1 | awk '{print $2}'))
unzip -n $ZIPNAME
IMGNAME=$(unzip -v $ZIPNAME | grep ".img" | awk '{print $8}')

truncate -s 3G $IMGNAME
sfdisk -d $IMGNAME | sed '$s/ size.*,//' | sfdisk $IMGNAME

sudo losetup -f -P $IMGNAME
LOOPDEV=$(sudo losetup -j $IMGNAME | awk '{print $1}' | sed 's/.$//g')

sudo e2fsck -f $LOOPDEV"p2"
sudo resize2fs $LOOPDEV"p2"

[ ! -d root ] && mkdir root

if [ $ENABLE_CCACHE -eq 1 ] && [ ! -d /var/cache/ccache ]
then
	sudo mkdir /var/cache/ccache
	sudo chown root:root /var/cache/ccache
	sudo chmod 777 /var/cache/ccache
fi

sudo mount -t ext4 $LOOPDEV"p2" root
sudo mount -t vfat $LOOPDEV"p1" root/boot
sudo mount -t devpts /dev/pts root/dev/pts
sudo mount -t proc /proc root/proc
 
if [ $ENABLE_CCACHE -eq 1 ]
then
	sudo mkdir root/var/cache/ccache
	sudo chmod 777 root/var/cache/ccache
	sudo mount --bind /var/cache/ccache root/var/cache/ccache
	echo "cache_dir = /var/cache/ccache" | sudo tee --append root/etc/ccache.conf
	sudo chroot root apt-get -y install ccache
fi

cat <<EOF | tee root/home/pi/run.sh
#!/bin/bash

NPROC=\$(nproc)
BUILDHOSTNAME=\$(hostname)

echo "Moode Release: "\$MOODEREL
echo "Is CCACHE enabled: "\$ENABLE_CCACHE

if [ \$ENABLE_CCACHE -eq 1 ]
then
#        export CC="ccache gcc"
#        export CPP="ccache g++"
	 export PATH=/usr/lib/ccache:\$PATH
fi

echo "gcc: "$CC" "\$(which gcc)
echo "g++: "$CPP" "\$(which g++)

sleep 5
EOF

if [ ! "x$1" = "x" ]
then
	cat $BATCHFILE | sudo tee --append root/home/pi/run.sh
	chmod +x root/home/pi/run.sh
	sudo chroot root su - pi -c "MOODEREL=$MOODEREL ENABLE_CCACHE=$ENABLE_CCACHE /home/pi/run.sh" 2>&1
	rm root/home/pi/run.sh
else
	sudo chroot root su - pi -c "MOODEREL=$MOODEREL ENABLE_CCACHE=$ENABLE_CCACHE bash"
fi

if [ $ENABLE_CCACHE -eq 1 ]
then
	sudo chroot root apt-get -y purge ccache
	sudo rm -f root/etc/ccache.conf
	sudo umount root/var/cache/ccache
	sudo rm -r root/var/cache/ccache
fi

sudo umount root/proc
sudo umount root/dev/pts
sudo umount root/boot
sudo umount root
sudo losetup -D

mv $IMGNAME $MOODENAME".img"

if [ $CREATE_ZIP -eq 1 ]
then
	zip $MOODENAME".zip" $MOODENAME".img"
	rm $MOODENAME".img"
	mv $MOODENAME".zip" $STARTDIR/
else
	mv $MOODENAME".img" $STARTDIR/
fi

[ $DELETE_TMP -eq 1 ] && sudo rm -rf $TMPDIR

cd $STARTDIR
