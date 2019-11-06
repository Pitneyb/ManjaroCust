#!/bin/bash

# Script to customize my manjaro installation

uuid=''
tmpdir="/home/$USER/tmpInstall"
partlabel=""
dirNames=(Downloads Games Music Pictures Videos VBoxVM)


chkdir()
{
    local dirName=$1
    local argcount="$#"
    echo "Total number of arguments : '$argcount'"
    # check if $dirName exists if not create it. If it does empty it
    if [ ! -d "$dirName" ]
    then
        if [ "$argcount" -eq 1 ]
        then
            echo then
            echo "Directory $dirName Does not exist. Creating"
            mkdir "$dirName"
        else
            echo else
            echo "Directory $dirName Does not exist. Creating"
            sudo mkdir "$dirName"
        fi
    fi
    
    if [ ! -d "$dirName" ]
        then
        echo "Failed to create Directory '$dirName'"
        exit 1
    fi
    
}

# Function to check and change ownership
chkowner()
{
    local dirpath=$1
    local curOwner=$(stat -c %U $dirpath)
    
    if [ $USER != $curOwner ]
        then
        sudo chown $USER $dirpath
    fi
}

getuuid()
{
    # get the disk UUID from a text file
    local dsklabel=$1
    local fName=Diskblkid.txt
    local lngthuuid=36
    echo Disk Label = $dsklabel
    
    # get list of UUID in a text file
    sudo blkid > "$tmpdir/$fName"
    local Diskblkidline=`grep "$dsklabel" "$tmpdir/$fName"`
    echo Diskblkidline = "$Diskblkidline"
    local startuuidpos=`expr index "$Diskblkidline" U`
    uuid=`echo ${Diskblkidline:$startuuidpos+5:$lngthuuid}`
    
    #exit 0
}

chklink()
{
local curdir=$1

if [ -L $curdir ]
then
    printf "Directory $curdir is a symlink\n"
    true
    return
else
    printf "Directory $curdir is not a symlink\n"
    false; return
fi
}

removedir()
{
local dirtoremove=$1
echo dirtoremove = $dirtoremove/
rm -rf $dirtoremove
}

createsymlink()
{
local symlinktocreate=$1
ln -s /media/$symlinktocreate/ /home/$USER/$symlinktocreate
}

addtofstab()
{
local drivepart=$1
cp /etc/fstab $tmpdir/fstab-$drivepart

printf "UUID=$uuid /media/$drivepart\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab
}

# start of main script
chkdir ~/Testing

pushd ~/Testing
pwd

echo tmpdir = $tmpdir

chkdir "$tmpdir"

# Delete files in $tmpdir (~/tmpInstall)
# find "$tmpdir" -mindepth 1
find "$tmpdir" -mindepth 1 -delete
# ls -la "$tmpdir/"

chkdir /media root

# Mount Ext USB Drive for Backups and timeshift
partlabel=Backup
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/"$partlabel" root
chkowner /media/"$partlabel"
#sudo chmod u+rwX,go+rX,go-w /mnt/$partlabel
#ls -l /mnt/

# write UUID for Backup disk to /etc/fstab
addtofstab $partlabel

sudo mount -a

# Delete existing timeshift Directory
if [ -d /media/Backup/timeshift ]
then
    echo "Removing existing timeshift directory"
    sudo rm -rf /media/Backup/timeshift
fi

# Create initial timeshift snapshot
sudo timeshift --snapshot-device $uuid
sudo timeshift --create --comments "Fresh Install" --verbose

# Add Internal and External Drives
for partlabel in "${dirNames[@]}"
do
{
    echo "Drive = $partlabel"
    getuuid $partlabel
    echo "UUID for $partlabel = $uuid"
    
    chkdir /media/$partlabel root
    chkowner /media/$partlabel
    
    # Add entry to /etc/fstab
    addtofstab $partlabel
}
done

sudo mount -a

# Create symlinks for Home Directory

for i in "${dirNames[@]}"
do
  {
    chklink /home/$USER/"$i"
    status=$?
    echo status = $status

        if [ "$status" -eq 1 ]
        then
        printf "Removing Directory /home/$USER/$i\n"
        removedir /home/$USER/$i
        printf "Creating symlink\n"
        createsymlink $i
        
        fi
    }
done

# Download and upgrade
sudo pacman -Syyu

# update mirrorlist with fastest mirrors
echo "Update miiror list"
sudo pacman-mirrors --fasttrack && sudo pacman -Syyu

sudo pacman -Syu apcupsd bleachbit calibre grsync gufw yay xsane

# set default  rules
echo "Setting ufw rules"
sudo ufw default allow outgoing
sudo ufw default deny incoming
# rules for network printing
sudo ufw allow to 192.168.1.107
sudo ufw allow from 192.168.1.107
# Rules for KDE Connect
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp

# enable ufw
echo "enable ufw"
sudo systemctl start ufw
sudo systemctl enable ufw

#Install python lib for GOGrepo
echo "Installing python Libraries"
sudo pacman -Syu python-html5lib python-html2text python-requests python-pyopenssl

# Install printing support
echo "Installing printer support"
sudo  pacman -Syu manjaro-printer

# Install Extra Fonts
echo "Installing extra fonts"
pamac build fonts-tlwg 
pamac build ttf-ms-fonts

# Install VirtualBox
echo "Installing Virtualbox"
pamac install virtualbox $(pacman -Qsq "^linux" | grep "^linux[0-9]*[-rt]*$" | awk '{print $1"-virtualbox-host-modules"}' ORS=' ')
pamac build virtualbox-ext-oracle
sudo gpasswd -a $USER vboxusers

# Install Wine
echo "Installing Wine"
sudo pacman -Syu wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader

# Installing Lutris
echo "Installing lutris"
sudo pacman -Syu lutris

# Remove $tmpdir
#rm -r "$tmpdir"
popd
#pwd
echo "!!!Finished - Please reboot!!!"
