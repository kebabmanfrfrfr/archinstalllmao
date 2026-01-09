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
parted -s $disk mkpart primary fat32 1MiB 2048MiB
parted -s $disk mkpart primary ext4 2049MiB 51200MiB
bootpart=$disk"1"
rootpart=$disk"2"

parted -s $rootpart set root
parted -s $bootpart set esp

mkfs.ext4 $rootpart
mkfs.fat -F 32 $bootpart

mount $rootpart /mnt
mount $bootpart /mnt/boot --mkdir

mkdir /mnt/home

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