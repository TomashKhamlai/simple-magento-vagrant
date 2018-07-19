#!/usr/bin/env bash

if [ ! -d /vagrant/public_html ] ; then
    mkdir -p /vagrant/public_html
fi

whoami
# mount --help
# mount -t vboxsf -o uid=33,gid=33,dmode=755,fmode=644 public_html /var/www/html/magento/public_html

# mount.vboxsf public_html /vagrant/public_html vboxsf
