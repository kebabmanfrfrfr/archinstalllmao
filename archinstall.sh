#!/bin/bash

# ZAMIEŃ ZMIENNE TUTAJ!!!!!!!!!!!!!!!
user="user"
password="password"
disk="/dev/sda"
host="host"

if ! ping -c 1 ping.archlinux.org; then
    echo Nie jesteś połączony do internetu! Połącz się i spróbuj ponownie.
    exit 1
fi

parted -s $disk mklabel gpt
parted -s $disk mkpart primary ext4 1MiB 14000MiB
parted -s $disk mkpart primary ext4 14001MiB 36000MiB
parted -s $disk mkpart primary fat32 50001MiB 2000MiB
parted -s $disk mkpart primary linux-swap 52001MiB 8000MiB

rootpart="${disk}1"
homepart="${disk}2"
bootpart="${disk}3"
swappart="${disk}4"

parted -s $rootpart set root
parted -s $homepart set linux-home
parted -s $bootpart set esp
parted -s $swappart set swap

mkfs.ext4 $rootpart
mkfs.ext4 $homepart
mkfs.fat -F 32 $bootpart
mkswap $swappart

mount $rootpart /mnt
mount $homepart /mnt/home --mkdir
mount $bootpart /mnt/boot --mkdir
swapon $swappart

pacstrap -K /mnt base linux linux-firmware hyprland kitty firefox wofi dolphin base-devel neovim grub efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash -c "echo ${host} >> /etc/hostname"
arch-chroot /mnt bash -c "hwclock --systohc"
arch-chroot /mnt bash -c "echo ${password} | passwd --stdin"
arch-chroot /mnt bash -c "useradd ${user}"
arch-chroot /mnt bash -c "echo ${password} | passwd ${user} --stdin"
arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH"
arch-chroot /mnt bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

reboot