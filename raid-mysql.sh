sudo apt-get update

(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc
sudo mkfs -t ext4 /dev/sdc1
sudo mkdir /datadrive && sudo mount /dev/sdc1 /datadrive

df -h
UUID=$(sudo -i blkid /dev/sdc1 | awk '{print $2}')
NewFSMount="$UUID   /datadrive  ext4    defaults,nofail,barrier=0   1  2"
NewFSMount="${NewFSMount//\"}"
echo $NewFSMount | sudo tee -a /etc/fstab

# set up a silent install of MySQL with database on new datadisk
