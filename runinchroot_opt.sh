################################################################
#
# Build Recipe v2.4, 2018-04-02
#
# moOde 4.1
#
# These instructions are written for Linux Enthusiasts
# and System Integrators and provide a recipe for making
# a custom OS for running moOde audio player.
#
# NOTE: This recipe is based on Stretch Lite 2017-11-29
# 
# Unless otherwise noted or if a command requires user
# interaction, groups of commands can be run in batch.
#
# Changes:
#
# v2.4: Set permissions for localui.service in STEP 8
#       Specify Linux kernel by Git hash in STEP 11
#       Add echo "y" to rpi-update in STEP 11, reqd for prompt in 4.14.y branch
#       Add apt-get clean to STEP 11
#       Bump to MPD 0.20.18 in STEP 6
#       Bump to upmpdcli-code-1.2.16 in COMPONENT 6 for Tidal fixes
#       Bump to Bluetooth 5.49 in STEP 4
#       Use local libupnppsamples-code sources in COMPONENT 6
#       Remove djmount in COMPONENT 1 and /mnt/UPNP in STEP 7
#       Set time zone to America/Detroit in STEP 2
#       Add second apt-get update in STEP 3 for robustness
# v2.3: Add sudo for cp pre-compiled MPD binary in STEP 6
#       Bump to shairport-sync 3.1.7
#		Reset dir permissions for var local in STEP 8
#       Update emerald theme settings in STEP 8
#       Remove page zoom setting from localui in COMPONENT 8
#		Use single squeezelite binary in COMPONENT 5
# v2.2: Reestablish musicroot symlink in STEP 7
#       Remove sudo from make for squeezelite
#       Add instructions for wpa_supplicant file
#       Bump to Raspbian Stretch Lite 2017-11-29
# v2.1: Chg poweroff to reboot in STEP 2
#       Should be /var/log/mpd/log in STEP 6
# v2.0: Add COMPONENT 8 Local UI display
#       Add COMPONENT 9 Allo Piano 2.1 firmware
#       Update STEP 8 with xinitrc
#       Add avahi-utils to STEP 3 core packages
#       Remove -j $(nproc --all) for compiles
#       Add 0644 to /etc/upmpdcli.conf in COMPONENT 6 number 4
# v1.9: Fixes for COMPONENT 6 number 4
#       Remove -j arg from make (it causes segfault)
#       Fix typo in ./configure: /etcmake -> /etc
# v1.8: Add / to dev/null in STEP 9
#       Remove bluealsa.servide disable in STEP 4
# v1.7: Fix step numbering
#       Gmusicapi is optional install (COMPONENT 7)
#       Squeezelite compile for native DSD support
#       Use make -j $(nproc --all) for certain compiles
#       Use amixer instead of alsamixer in STEP 9
#       Add reference to win32diskimager to Appendix
#       Add version suffix to rel-stretch zipfile
#       Adjust rel-stretch-ver.zip download path 
# v1.6: Add additional dev libs for gmusicapi
#       Fix typo in STEP 2, wrong r40b_
# v1.5: Fix various typos
# v1.4: Remove odd binary chars at end of some lines
# v1.3: Added WiFi config to STEP 1
# v1.2: Simplified method for STEPS 1,2
#       Bump to MPD 0.20.11
# v1.1: echo "pi:moodeaudio" | sudo chpasswd in STEP 2
#       Set 0755 permissions on /var/local/www in STEP 7
#       Remove templatesw# fatfinger dir in STEP 7
#
# (C) Tim Curtis 2017 http://moodeaudio.org
#
################################################################

sudo apt-get -y purge triggerhappy

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get -y install \
rpi-update php-fpm nginx sqlite3 php-sqlite3 memcached php-memcache mpc bs2b-ladspa libbs2b0 libasound2-plugin-equal telnet automake sysstat squashfs-tools tcpdump shellinabox samba smbclient udisks-glue ntfs-3g exfat-fuse git inotify-tools libav-tools avahi-utils \
dnsmasq hostapd \
\
bluez bluez-firmware pi-bluetooth \
dh-autoreconf expect libortp-dev libbluetooth-dev libasound2-dev \
libusb-dev libglib2.0-dev libudev-dev libical-dev libreadline-dev libsbc1 libsbc-dev \
\
libmad0-dev libmpg123-dev libid3tag0-dev libflac-dev libvorbis-dev libfaad-dev libwavpack-dev libavcodec-dev libavformat-dev libmp3lame-dev libsoxr-dev libcdio-paranoia-dev libiso9660-dev libcurl4-gnutls-dev libasound2-dev libshout3-dev libyajl-dev libmpdclient-dev libavahi-client-dev libsystemd-dev libwrap0-dev libboost-dev libicu-dev libglib2.0-dev \
autoconf libtool libdaemon-dev libasound2-dev libpopt-dev libconfig-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
libmicrohttpd-dev libexpat1-dev libxml2-dev libxslt1-dev libjsoncpp-dev python-requests python-pip \
xinit xorg lsb-release xserver-xorg-legacy chromium-browser libgtk-3-0

sudo apt-get clean

# kernel ver 4.14.32
echo y | sudo PRUNE_MODULES=1 rpi-update 171c962793f7a39a6798ce374d9d63ab0cbecf8c
sudo rm -rf /lib/modules.bak
sudo rm -rf /boot.bak

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 1 - Modify Raspbian Lite and create a new, base image
echo 
echo  Use one of the two options below depending on what
echo  type of host computer you are going to be using.
echo 
echo //////////////////////////////////////////////////////////////

sudo touch /boot/ssh

sudo sed -i "s/init=.*//" /boot/cmdline.txt
sudo sed -i "s/quiet.*//" /boot/cmdline.txt
sudo rm /etc/init.d/resize2fs_once
# Configure to use standard interface names
sudo sed -i "s/^/net.ifnames=0 /" /boot/cmdline.txt

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 2 - Expand the root partition to 3GB
echo 
echo //////////////////////////////////////////////////////////////

sudo timedatectl set-timezone "Europe/Rome"

echo "Change the current password (raspberry) to moodeaudio and the host name to moode."

echo "pi:moodeaudio" | sudo chpasswd
sudo sed -i "s/raspberrypi/moode/" /etc/hostname
sudo sed -i "s/raspberrypi/moode/" /etc/hosts
sudo hostname moode

echo  Download moOde application sources and configs.

echo 
echo  NOTE: We are downloading the Sources in this particular step in order to obtain the resizefs.sh file.
echo 
echo  moOde $MOODE_REL
echo 

cd ~
wget http://moodeaudio.org/downloads/prod/rel-stretch-$MOODE_REL.zip
sudo unzip ./rel-stretch-$MOODE_REL.zip

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 3 - Install core packages
echo 
echo //////////////////////////////////////////////////////////////

echo  First lets make some basic optimizations

#sudo dphys-swapfile swapoff
sudo update-rc.d dphys-swapfile remove
#sudo rm /var/swap
sudo systemctl disable cron.service
sudo systemctl enable rpcbind

echo  Install core packages.

sudo systemctl disable shellinabox

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 4 - Install enhanced networking
echo 
echo //////////////////////////////////////////////////////////////

echo  Install Host AP mode 

sudo systemctl daemon-reload
sudo systemctl disable hostapd
sudo systemctl disable dnsmasq

echo  Install Bluetooth

# Compile bluez
cp ./rel-stretch/other/bluetooth/bluez-5.49.tar.xz ./
tar xvf bluez-5.49.tar.xz
cd bluez-5.49
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --enable-library
make -j$NPROC
sudo make install
cd ~
rm -rf ./bluez-5.49*

# Delete symlink and bin for old bluetoothd
sudo rm /usr/sbin/bluetoothd
sudo rm -rf /usr/lib/bluetooth
# Create symlink for new bluetoothd
sudo ln -s /usr/libexec/bluetooth/bluetoothd /usr/sbin/bluetoothd

echo NOTE: Ignore warnings from autoreconf and configure

cd /tmp
git clone https://github.com/Arkq/bluez-alsa.git
cd bluez-alsa
autoreconf --install
mkdir build
cd build
../configure --disable-hcitop --with-alsaplugindir=/usr/lib/arm-linux-gnueabihf/alsa-lib
make -j$NPROC
sudo make install
cd ~
rm -rf /tmp/bluez-alsa

echo  Services are started by moOde Worker so lets disable them here.

sudo systemctl daemon-reload
sudo systemctl disable bluetooth.service
sudo systemctl disable hciuart.service

echo  Finish up

sudo mkdir -p /var/run/bluealsa
sudo sync

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 5 - Install Rotary encoder driver
echo 
echo //////////////////////////////////////////////////////////////

echo  WiringPi

echo NOTE: Ignore warnings during build

sudo cp ./rel-stretch/other/wiringpi/wiringPi-2.44-96344ff.tar.gz ./
sudo tar xfz ./wiringPi-2.44-96344ff.tar.gz
cd wiringPi-96344ff
sudo ./build
cd ~/
sudo rm -rf ./wiringPi-96344ff
sudo rm ./wiringPi-2.44-96344ff.tar.gz

echo  Rotenc

sudo cp ./rel-stretch/other/rotenc/rotenc.c ./
sudo gcc -std=c99 rotenc.c -orotenc -lwiringPi
sudo cp ./rotenc /usr/local/bin
sudo rm ./rotenc*

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 6 - Compile and install MPD
echo 
echo //////////////////////////////////////////////////////////////

echo  Create MPD runtime environment.

sudo useradd mpd
sudo mkdir /var/lib/mpd
sudo mkdir /var/lib/mpd/music
sudo mkdir /var/lib/mpd/playlists
sudo touch /var/lib/mpd/state
sudo chown -R mpd:audio /var/lib/mpd
sudo mkdir /var/log/mpd
sudo touch /var/log/mpd/log
sudo chmod 644 /var/log/mpd/log
sudo chown -R mpd:audio /var/log/mpd
sudo cp ./rel-stretch/mpd/mpd.conf.default /etc/mpd.conf
sudo chown mpd:audio /etc/mpd.conf
sudo chmod 0666 /etc/mpd.conf

echo  Install MPD dev libs.

echo  Download MPD 0.20.18 sources and prep for compile.

# Optionally install pre-compiled binary and skip to STEP 7
#sudo cp ./rel-stretch/other/mpd/mpd-0.20.12 /usr/local/bin/mpd

wget http://www.musicpd.org/download/mpd/0.20/mpd-0.20.18.tar.xz
tar xf mpd-0.20.18.tar.xz
cd mpd-0.20.18
sh autogen.sh

echo  Configure compile options.

./configure --enable-database --enable-libmpdclient --enable-alsa \
--enable-curl --enable-dsd --enable-ffmpeg --enable-flac \
--enable-id3 --enable-soundcloud --enable-lame-encoder --enable-mad \
--enable-mpg123 --enable-pipe-output --enable-recorder-output --enable-shout \
--enable-vorbis --enable-wave-encoder --enable-wavpack --enable-httpd-output \
--enable-soxr --with-zeroconf=avahi \
--disable-bzip2 --disable-zzip --disable-fluidsynth --disable-gme \
--disable-wildmidi --disable-sqlite --disable-jack --disable-ao --disable-oss \
--disable-ipv6 --disable-pulse --disable-nfs --disable-smbclient \
--disable-upnp --disable-expat --disable-lsr \
--disable-sndfile --disable-audiofile --disable-sidplay

echo  Compile and install.

make -j$NPROC
sudo make install
sudo strip --strip-unneeded /usr/local/bin/mpd
cd ~
rm -rf ./mpd-0.20.18*

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 7 - Create moOde runtime environment
echo 
echo //////////////////////////////////////////////////////////////

echo  Privilages

cat <<EOF | sudo -i
echo -e 'pi\tALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
echo -e 'www-data\tALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
logout
EOF

echo  Directories and files

# Dirs
sudo mkdir /var/local/www
sudo mkdir /var/local/www/commandw
sudo mkdir /var/local/www/cssw
sudo mkdir /var/local/www/jsw
sudo mkdir /var/local/www/imagesw
sudo mkdir /var/local/www/imagesw/toggle
sudo mkdir /var/local/www/db
sudo mkdir /var/local/www/templatesw
sudo chmod -R 0755 /var/local/www
sudo mkdir /var/lib/mpd/music/RADIO
# Mount points
sudo mkdir /mnt/NAS
sudo mkdir /mnt/SDCARD
# Symlinks
sudo ln -s /mnt/NAS /var/lib/mpd/music/NAS
sudo ln -s /mnt/SDCARD /var/lib/mpd/music/SDCARD
sudo ln -s /media /var/lib/mpd/music/USB
sudo ln -s /var/lib/mpd/music /var/www/vlmm90614385
# Logs
sudo touch /var/log/moode.log
sudo chmod 0666 /var/log/moode.log
sudo touch /var/log/php_errors.log
sudo chmod 0666 /var/log/php_errors.log
# Files
sudo cp ./rel-stretch/mpd/sticker.sql /var/lib/mpd
sudo cp -r "./rel-stretch/other/sdcard/Stereo Test/" /var/lib/mpd/music/SDCARD/
sudo cp ./rel-stretch/network/interfaces.default /etc/network/interfaces

## NOTE: if you created a wpa_supplicant.conf file back in STEP 1 to run the
## build over a WiFi connection then don't copy the wpa_supplicant.conf file. 
## When you reach STEP 12 open Network config and enter your SSID and Password then APPLY.
## This will create a new wpa_supplicant.conf file and also update the sql database.

sudo cp ./rel-stretch/network/wpa_supplicant.conf.default /etc/wpa_supplicant/wpa_supplicant.conf

sudo cp ./rel-stretch/network/dhcpcd.conf.default /etc/dhcpcd.conf
sudo cp ./rel-stretch/network/hostapd.conf.default /etc/hostapd/hostapd.conf
sudo cp ./rel-stretch/var/local/www/db/moode-sqlite3.db.default /var/local/www/db/moode-sqlite3.db
# Permissions
sudo chmod 0777 /var/lib/mpd/music/RADIO
sudo chmod -R 0777 /var/local/www/db
# Deletes
sudo rm -r /var/www/html
sudo rm /etc/update-motd.d/10-uname

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 8 - Install moOde sources and configs
echo 
echo //////////////////////////////////////////////////////////////

echo  Application sources and configs

# Ignore "no such file or directory" errors if they appear.
sudo rm /var/lib/mpd/music/RADIO/*
sudo rm /var/www/images/radio-logos/*

sudo cp ./rel-stretch/mpd/RADIO/* /var/lib/mpd/music/RADIO
sudo cp ./rel-stretch/mpd/playlists/* /var/lib/mpd/playlists
sudo cp -r ./rel-stretch/etc/* /etc
sudo cp -r ./rel-stretch/home/* /home/pi
sudo mv /home/pi/dircolors /home/pi/.dircolors
sudo mv /home/pi/xinitrc.default /home/pi/.xinitrc
sudo cp -r ./rel-stretch/lib/* /lib
sudo cp -r ./rel-stretch/usr/* /usr
sudo cp -r ./rel-stretch/var/* /var
sudo cp -r ./rel-stretch/www/* /var/www

sudo chmod 0755 /var/www/command/*
sudo /var/www/command/util.sh emerald "27ae60" "rgba(39,174,96,0.71)"
sudo  sqlite3 /var/local/www/db/moode-sqlite3.db "update cfg_system set value='Emerald' where param='themecolor'"

echo  Permissions for service files

# MPD
sudo chmod 0755 /etc/init.d/mpd
sudo chmod 0644 /lib/systemd/system/mpd.service
sudo chmod 0644 /lib/systemd/system/mpd.socket
# Bluetooth
sudo chmod 0666 /etc/bluealsaaplay.conf
sudo chmod 0644 /etc/systemd/system/bluealsa-aplay@.service
sudo chmod 0644 /etc/systemd/system/bluealsa.service
sudo chmod 0644 /lib/systemd/system/bluetooth.service
sudo chmod 0755 /usr/local/bin/a2dp-autoconnect
# Rotenc
sudo chmod 0644 /lib/systemd/system/rotenc.service
# Udev
sudo chmod 0644 /etc/udev/rules.d/*
# Localui
sudo chmod 0644 /lib/systemd/system/localui.service

echo  Services are started by moOde Worker so lets disable them here.

sudo systemctl daemon-reload
sudo systemctl disable mpd.service
sudo systemctl disable mpd.socket
sudo systemctl disable rotenc.service

# The binaries will not have been installed yet, but let's disable the services here
sudo chmod 0644 /lib/systemd/system/squeezelite.service
sudo systemctl disable squeezelite
sudo chmod 0644 /lib/systemd/system/upmpdcli.service
sudo systemctl disable upmpdcli.service

echo  Reset dir permissions for var local
sudo chmod -R 0755 /var/local/www
sudo chmod -R 0777 /var/local/www/db
sudo chmod -R ug-s /var/local/www

echo  Initial permissions for certain files. These also get set during moOde Worker startup.

sudo chmod 0777 /var/local/www/playhistory.log
sudo chmod 0777 /var/local/www/currentsong.txt
sudo touch /var/local/www/libcache.json
sudo chmod 0777 /var/local/www/libcache.json

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 9 - Alsaequal
echo 
echo //////////////////////////////////////////////////////////////

echo NOTE: The amixer command below will generate the alsaequal bin file.

sudo amixer -D alsaequal > /dev/null

sudo chmod 0755 /usr/local/bin/alsaequal.bin
sudo chown mpd:audio /usr/local/bin/alsaequal.bin
sudo rm /usr/share/alsa/alsa.conf.d/equal.conf

sudo mkdir /var/run/mpd
sudo chown mpd:audio /var/run/mpd
sudo /usr/local/bin/mpd /etc/mpd.conf
mpc enable only 1
sudo mpd --kill /etc/mpd.conf

if [ $ENABLE_SQUASHFS -eq 1 ]
then
    echo //////////////////////////////////////////////////////////////
    echo 
    echo  STEP 10 - Optionally squash /var/www
    echo 
    echo //////////////////////////////////////////////////////////////

    echo NOTE: This is optional but highly recommended for performance/reliability

    cat <<EOF | sudo -i
echo "/var/local/moode.sqsh   /var/www        squashfs        ro,defaults     0       0" >> /etc/fstab
logout
EOF
    cd ~
    sudo rm /var/local/moode.sqsh
    sudo mksquashfs /var/www /var/local/moode.sqsh
    sudo rm -rf /var/www/*
    sudo mount /var/local/moode.sqsh /var/www 
fi

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 12 - Launch and configure moOde!
echo 
echo //////////////////////////////////////////////////////////////

echo  Initial configuration

echo a. http://moode
echo b. Browse Tab, Default Playlist, Add
echo c. Menu, Configure, Sources, UPDATE mpd database
echo d. Menu, Audio, Mpd options, EDIT SETTINGS, APPLY
echo e. Menu, System, Set timezone
echo f. Clear system logs, YES
echo g. Compact sqlite database, YES
echo h. Keyboard
echo i. Layout

echo  Verification

echo "a) Playback tab"
echo "b) Scroll to the last item which should be the Stereo Test track"
echo "c) Click to begin play"
echo "d) Menu, Audio info"
echo "e) Verify Output stream is 16 bit 48 kHz"

echo //////////////////////////////////////////////////////////////
echo 
echo  STEP 13 - Final prep for image
echo 
echo //////////////////////////////////////////////////////////////

echo  Reset the network config to defaults

echo *** IMPORTANT! ***

#Don't forget to do this!

sudo rm /var/lib/dhcpcd5/*

sudo cp ./rel-stretch/network/interfaces.default /etc/network/interfaces

## NOTE: if you created a wpa_supplicant.conf file back in STEP 1 to run the
## build over a WiFi connection then don't copy the wpa_supplicant.conf file. 
sudo cp ./rel-stretch/network/wpa_supplicant.conf.default /etc/wpa_supplicant/wpa_supplicant.conf

sudo cp ./rel-stretch/network/dhcpcd.conf.default /etc/dhcpcd.conf
sudo cp ./rel-stretch/network/hostapd.conf.default /etc/hostapd/hostapd.conf

echo NOTE: Resetting the network config allows the moodecfg.txt automation file to be used to automatically change the
echo host name and other names at first boot. See the file /var/www/setup.txt for more information on this feature.

################################################################
#
#
# Install additional components
#
#
################################################################

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 1 - MiniDLNA
echo 
echo //////////////////////////////////////////////////////////////

sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install minidlna
sudo systemctl disable minidlna

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 2 - Auto-shuffle
echo 
echo //////////////////////////////////////////////////////////////

cd ~
sudo git clone https://github.com/Joshkunz/ashuffle.git
cd ashuffle
sudo make -j$NPROC
cd ~
sudo cp ./ashuffle/ashuffle /usr/local/bin
sudo rm -rf ./ashuffle

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 3 - MPD Audio Scrobbler
echo 
echo //////////////////////////////////////////////////////////////

cd ~
sudo git clone https://github.com/hrkfdn/mpdas
cd mpdas
sudo make -j$NPROC
sudo cp ./mpdas /usr/local/bin
cd ~/
sudo rm -rf ./mpdas
sudo cp ./rel-stretch/usr/local/etc/mpdasrc.default /usr/local/etc/mpdasrc
sudo chmod 0755 /usr/local/etc/mpdasrc

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 4 - Shairport-sync
echo 
echo //////////////////////////////////////////////////////////////

cd ~
git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
autoreconf -i -f
./configure --with-alsa --with-avahi --with-ssl=openssl --with-soxr --with-metadata --with-stdout --with-systemd
make -j$NPROC
sudo make install
sudo systemctl disable shairport-sync
cd ~
rm -rf ./shairport-sync
sudo cp ./rel-stretch/usr/local/etc/shairport-sync.conf /usr/local/etc

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 5 - Squeezelite
echo 
echo //////////////////////////////////////////////////////////////

BASE=/tmp/squeezelite
git clone https://github.com/ralph-irving/squeezelite $BASE

pushd $BASE
export CFLAGS="-O3 -march=native -mcpu=native -DDSD -DRESAMPLE -fno-fast-math -mfloat-abi=hard -pipe -fPIC"
cat ./scripts/squeezelite-ralphy-dsd.patch | patch -p 0
make -j$NPROC
sudo cp ./squeezelite /usr/local/bin/
popd
rm -rf $BASE

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 6 - Upmpdcli
echo 
echo //////////////////////////////////////////////////////////////

echo  "Enjoy a Coffee and listen to some Tunes while the compiles run :-)"

echo  Libupnp jfd5

cd ~
cp ./rel-stretch/other/upmpdcli/libupnp-1.6.20.jfd5.tar.gz ./
tar xfz ./libupnp-1.6.20.jfd5.tar.gz
cd libupnp-1.6.20.jfd5
./configure --prefix=/usr --sysconfdir=/etc
make -j$NPROC
sudo make install
cd ~
rm -rf ./libupnp-1.6.20.jfd5
rm libupnp-1.6.20.jfd5.tar.gz

echo  Libupnpp

cp ./rel-stretch/other/upmpdcli/libupnpp-0.16.0.tar.gz ./
tar xfz ./libupnpp-0.16.0.tar.gz
cd libupnpp-0.16.0
./configure --prefix=/usr --sysconfdir=/etc
make -j$NPROC
sudo make install
cd ~
rm -rf ./libupnpp-0.16.0
rm libupnpp-0.16.0.tar.gz

echo  Upmpdcli

cp ./rel-stretch/other/upmpdcli/upmpdcli-1.2.16.tar.gz ./
tar xfz ./upmpdcli-1.2.16.tar.gz 
cd upmpdcli-1.2.16
./configure --prefix=/usr --sysconfdir=/etc
make -j$NPROC
sudo make install
cd ~
rm -rf ./upmpdcli-1.2.16
rm upmpdcli-1.2.16.tar.gz

sudo useradd upmpdcli
sudo cp ./rel-stretch/lib/systemd/system/upmpdcli.service /lib/systemd/system
sudo cp ./rel-stretch/etc/upmpdcli.conf /etc
sudo chmod 0644 /etc/upmpdcli.conf
sudo systemctl daemon-reload
sudo systemctl disable upmpdcli

echo  upexplorer

echo NOTE: This also installs a bunch of other utils

#git clone https://@opensourceprojects.eu/git/p/libupnppsamples/code libupnppsamples-code
cp -r ./rel-stretch/other/libupnppsamples-code/ ./
cd libupnppsamples-code
./autogen.sh
./configure
make -j$NPROC
sudo make install
cd ~
rm -rf ./libupnppsamples-code

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 7 - Optionally install gmusicapi
echo 
echo //////////////////////////////////////////////////////////////

echo NOTE: This component enables access to Google Play Music service via UPnP renderer.
echo       If its not installed, the Google Play section in UPnP config screen will not be present.

if [ $CCACHE_ENABLED -eq 1 ]
then 
    sudo CC="ccache gcc" pip install gmusicapi
else
    sudo pip install gmusicapi
fi

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 8 - Local UI display 
echo 
echo //////////////////////////////////////////////////////////////

echo  Permissions, clean up and service config

sudo sed -i "s/allowed_users=console/allowed_users=anybody/" /etc/X11/Xwrapper.config
sudo systemctl daemon-reload
sudo systemctl disable localui

echo  Configure Chrome Browser

echo NOTE: These steps are performed AFTER actually starting local display via System config,
echo       rebooting and then accessing moOde on the local display.

echo a. Connect a keyboard.
echo b. Press Ctrl-t to open a separate instance of Chrome Browser.
echo c. Enter url chrome://flags and scroll down to Overlay Scrollbars and enable the setting.
echo d. Optionally, enter url chrome://extensions and install the xontab virtual keyboard extension.

echo //////////////////////////////////////////////////////////////
echo 
echo  COMPONENT 9 - Allo Piano 2.1 Firmware
echo 
echo //////////////////////////////////////////////////////////////

cd ~
wget https://github.com/allocom/piano-firmware/archive/master.zip
sudo unzip master.zip 
sudo rm ./master.zip
sudo cp -r ./piano-firmware-master/lib/firmware/allo /lib/firmware
sudo rm -rf ./piano-firmware-master

echo //////////////////////////////////////////////////////////////
echo 
echo  FINAL - Clean up
echo 
echo //////////////////////////////////////////////////////////////

cd ~
sudo /var/www/command/util.sh clear-syslogs
sudo apt-get autoremove

[ $ENABLE_SQUASHFS -eq 1 ] && sudo umount /var/www
sudo hostname $BUILDHOSTNAME
