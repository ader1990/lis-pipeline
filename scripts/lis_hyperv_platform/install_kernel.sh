#!/bin/bash

install_kernel() {
    lsblk | grep rom | cut -d ' ' -f 1 | xargs -I {} mkdir -p /mnt/{}
    lsblk | grep rom | cut -d ' ' -f 1 | xargs -I {} mount /dev/{} /mnt/{}

    find /mnt -name "*.deb" | xargs dpkg -i

    lsblk | grep rom | cut -d ' ' -f 1 | xargs -I {} umount /mnt/{}
    lsblk | grep rom | cut -d ' ' -f 1 | xargs -I {} rm -rf /mnt/{}
}

main() {
    install_kernel
    reboot
}

main

exit 0
