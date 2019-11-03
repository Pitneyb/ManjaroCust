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
cp /etc/fstab "$tmpdir"/
chkowner /media/"$partlabel"
#sudo chmod u+rwX,go+rX,go-w /mnt/$partlabel
#ls -l /mnt/

# write UUID for Backup disk to /etc/fstab
printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

#echo "$USER before mount"
sudo mount -a
#echo "$USER after mount"
#ls -l /mnt
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
partlabel=Downloads
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/$partlabel root
chkowner /media/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Games
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/$partlabel root
chkowner /media/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Music
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/$partlabel root
chkowner /media/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Pictures
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/$partlabel root
chkowner /media/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Videos
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/$partlabel root
chkowner /media/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=VBoxVM
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /media/$partlabel root
chkowner /media/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /media/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab


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
sudo pacman-mirrors --fasttrack && sudo pacman -Syyu

sudo pacman -Syu apcupsd bleachbit calibre grsync gufw

# set default  rules
sudo ufw default allow outgoing
sudo ufw default deny incoming

sudo ufw allow to 192.168.1.107
sudo ufw allow from 192.168.1.107

# enable ufw
sudo systemctl start ufw
sudo systemctl enable ufw

#Install python lib for GOGrepo
sudo pacman -Syu python-html5lib python-html2text python-requests python-pyopenssl

# Install printing support
sudo  pacman -Syu manjaro-printer

# Install VirtualBox
pamac install virtualbox $(pacman -Qsq "^linux" | grep "^linux[0-9]*[-rt]*$" | awk '{print $1"-virtualbox-host-modules"}' ORS=' ')
sudo gpasswd -a $USER vboxusers

# Remove $tmpdir
#rm -r "$tmpdir"
popd
#pwd
echo "!!!Finished - Please reboot!!!"
