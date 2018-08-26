

# load keyboard
loadkeys pl

# set time
timedatectl set-ntp true

# create MBR partitions
# /dev/sda1 8G    swap
# /dev/sda2 rest  linux
fdisk /dev/sda << EOF
o
n
p
1
2048
+8G
t
83
n
p
2


w 
EOF

# create GPT partitions
# /dev/sda1 8G    swap
# /dev/sda2 rest  linux
#fdisk /dev/sda << EOF
#g
#n
#1
#2048
#+8G
#t
#19
#n
#2
#
#
#w 
#EOF

# format partitions
mkfs.ext4 /dev/sda2

# create swap
mkswap /dev/sda1
swapon /dev/sda1

# mount partitions
mount /dev/sda2 /mnt

# install system
pacstrap /mnt base base-devel vim grub os-prober the_silver_searcher

# prepare fstab
genfstab -U /mnt >> /mnt/etc/fstab

# change to new enviroment
arch-chroot /mnt

# setup time
ln -sf /usr/share/zoneinfo/Poland /etc/localtime
hwclock --systohc

# generate locale
printf "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# configure locale
printf "LANG=en_US.UTF-8" > /etc/locale.conf
printf "KEYMAP=pl" > /etc/vconsole.conf
printf "den" > /etc/hostname
printf "127.0.0.1 localhost\n::1 localhost\n127.0.0.1 den.shadows den\n" > /etc/hosts

# set default password for root
printf "root\nroot" | passwd

# install bootloader
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# exit new enviroment
exit
umount -R /mnt
