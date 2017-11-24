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
    sudo cp -rf /home/ubuntu/.ssh/authorized_keys /
    apt update
    apt -y install at dos2unix
    systemctl enable atd.service
    sudo sed -i 's%#AuthorizedKeysFile.*%AuthorizedKeysFile /authorized_keys%' /etc/ssh/sshd_config
    reboot
}

main

exit 0
