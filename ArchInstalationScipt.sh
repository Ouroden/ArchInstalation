
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
  pacstrap /mnt base base-devel vim grub os-prober the_silver_searcher zsh zsh-completions git
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

function installBootloaderForMBR(){
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

function removeScriptCopy(){
  rm /mnt/$0
}

function runScriptInsideChroot(){
  cp $0 /mnt/$0
  arch-chroot /mnt $0 chroot
}

function runOperationsBeforeChroot(){
  loadKeyboard
  setNtp
  createMBRPartitions
  formatPartitions
  createSwap
  mountPartitions
  installSystem
  prepareFstab
}

function runOperationsInsideChroot(){
  setupTime
  generateLocale
  configureLocale
  setRootPassword
  installBootloaderForMBR
}

function runOperationsAfterChroot(){
	removeScriptCopy
  	umountAll
}

function setupWiredConnection(){
  interface=$(ls /sys/class/net -I lo)
  ip link set ${interface} up
  systemctl enable dhcpcd
  dhcpcd ${interface}	
}

function createUser(){
  user=$1
  useradd -m -G wheel -s /usr/bin/zsh $1
  printf "$1\n$1" | passwd $1
}

function enableSudo(){
  echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
}

function enableProxy(){
  echo 'Defaults env_keep += "EDITOR PROXY http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY rsync_proxy RSYNC_PROXY"' | EDITOR='tee -a' visudo
}

function createProxyFile(){
  proxy=http://defra1c-proxy.emea.nsn-net.net:8080
  proxyFile=/etc/profile.d/proxy.sh

  printf "default=$proxy\n" > proxyFile
  printf "export PROXY=$default\n" >> proxyFile
  printf "export http_proxy=$PROXY\nexport HTTP_PROXY=$PROXY\n" >> proxyFile
  printf "export https_proxy=$PROXY\nexport HTTPS_PROXY=$PROXY\n" >> proxyFile
  printf "export ftp_proxy=$PROXY\nexport FTP_PROXY=$PROXY\n" >> proxyFile
  printf "export rsync_proxy=$PROXY\nexport RSYNC_PROXY=$PROXY\n" >> proxyFile
}

function installVMPlugins(){
  pacman -S --noconfirm virtualbox-guest-utils <<< '2'
  systemctl enable vboxservice
  systemctl start vboxservice
  #printf "VBoxClient-all" >> ??? # run after startx
}

function runOperationsAfterReboot(){
  setupWiredConnection
  createUser "ouro"
  enableSudo
  createProxyFile 
  enableProxy
  installVMPlugins
}

main()
{
  if [[ $1 = "chroot" ]]; then runOperationsInsideChroot; exit 0; fi 

  if [[ $1 = "basic" ]]; then
    runOperationsBeforeChroot
    runScriptInsideChroot
    runOperationsAfterChroot
    printf "Basic installation finished successfully.\n"
    printf "Please reboot and eject CD.\n"
    printf "After reboot please run this script with: \'$0 post\' to configure system\n"
  fi

  if [[ $1 = "post" ]]; then runOperationsAfterReboot; exit 0; fi 

}

main "$@"
