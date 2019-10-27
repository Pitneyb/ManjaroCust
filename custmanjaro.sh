#!/bin/bash

# Script to customize my manjaro installation

uuid=''
tmpdir="/home/$USER/tmpInstall"
partlabel=""

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
    local startuuidpos=`expr index "$Diskblkidline" UUID`
    uuid=`echo ${Diskblkidline:$startuuidpos+5:$lngthuuid}`
    
    #exit 0
}

# start of main script
pushd ~/Testing
pwd

echo tmpdir = $tmpdir

chkdir "$tmpdir"

# Delete files in $tmpdir (~/tmpInstall)
# find "$tmpdir" -mindepth 1
find "$tmpdir" -mindepth 1 -delete
# ls -la "$tmpdir/"

# Mount Ext USB Drive for Backups and timeshift
partlabel=Backup
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /mnt/"$partlabel" root
cp /etc/fstab "$tmpdir"/
#sudo chown -v steve:users /mnt/$partlabel
#sudo chmod u+rwX,go+rX,go-w /mnt/$partlabel
#ls -l /mnt/

# write UUID for Backup disk to /etc/fstab
printf "UUID=$uuid /mnt/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

#echo "$USER before mount"
sudo mount -a
#echo "$USER after mount"
#ls -l /mnt

# Create initial timeshift snapshot
sudo timeshift --snapshot-device $uuid
sudo timeshift --create --comments "Fresh Install" --verbose

# Add Internal and External Drives
partlabel=Games
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /home/$USER/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /home/$USER/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Downloads
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /home/$USER/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /home/$USER/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Music
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /home/$USER/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /home/$USER/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Pictures
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /home/$USER/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /home/$USER/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=Videos
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /home/$USER/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /home/$USER/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

partlabel=VBoxVM
getuuid "$partlabel"
echo UUID="$uuid"

chkdir /home/$USER/$partlabel
cp /etc/fstab "$tmpdir"

printf "UUID=$uuid /home/$USER/$partlabel\text4\trw,user,exec\t0 2\n" | sudo tee -a /etc/fstab

# update mirrorlist with fastest mirrors
sudo pacman-mirrors --fasttrack && sudo pacman -Syyu

sudo pacman -Syu apcupsd bleachbit grsync gufw
# Remove $tmpdir
#rm -r "$tmpdir"
popd
#pwd
echo "!!!Finished - Please reboot!!!"
