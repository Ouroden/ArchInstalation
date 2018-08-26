
function loadKeyboard(){
  loadkeys pl
}

function setNtp(){
  timedatectl set-ntp true
}

function createMBRPartitions(){
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
82
n
p
2


t
2
83
w 
EOF
}

function createGPTPartitions(){
# /dev/sda1 8G    swap
# /dev/sda2 rest  linux
fdisk /dev/sda << EOF
g
n
1
2048
+8G
t
19
n
2


w 
EOF
}

function formatPartitions(){
  mkfs.ext4 /dev/sda2
}

function createSwap(){
  mkswap /dev/sda1
  swapon /dev/sda1
}

function mountPartitions(){
  mount /dev/sda2 /mnt
}

function installSystem(){
  pacstrap /mnt base base-devel vim grub os-prober the_silver_searcher
}

function prepareFstab(){
  genfstab -U /mnt >> /mnt/etc/fstab
}

function setupTime(){
  ln -sf /usr/share/zoneinfo/Poland /etc/localtime
  hwclock --systohc
}

function generateLocale(){
  printf "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
}

function configureLocale(){
  printf "LANG=en_US.UTF-8" > /etc/locale.conf
  printf "KEYMAP=pl" > /etc/vconsole.conf
  printf "den" > /etc/hostname
  printf "127.0.0.1 localhost\n::1 localhost\n127.0.0.1 den.shadows den\n" > /etc/hosts
}

function setRootPassword(){
  printf "root\nroot" | passwd
}

function installBootloader(){
  grub-install --target=i386-pc /dev/sda
  grub-mkconfig -o /boot/grub/grub.cfg
}

function changeToChroot()
{
  arch-chroot /mnt
}

function umountAll(){
  umount -R /mnt
}

function preChroot(){
  loadKeyboard
  setNtp
  createMBRPartitions
  formatPartitions
  createSwap
  mountPartitions
  installSystem
  prepareFstab
}

function inChroot()
{
  setupTime
  generateLocale
  configureLocale
  setRootPassword
  installBootloader
}

function main()
{
  if [ $1 = "full" ]; then 
  	preChroot
  	changeToChroot
  	exit
  	inChroot
  	umountAll
  fi

  if [ $1 = "pre" ]; then 
  	preChroot
  fi

  if [ $1 = "in" ]; then 
  	inChroot
  fi

  if [ $1 = "chroot" ]; then 
  	changeToChroot
  fi
}

main "$@"
