#!/bin/bash

# FTP Practice -- Antonia Sáez Camacho

#----------------------------------------------------------#
#-----------------------FTP servers------------------------#
#----------------------------------------------------------#

# Install the service
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install vsftpd -y
unset DEBIAN_FRONTEND

# Copy the configuration files
mkdir /etc/vsftpd
cp /vagrant/ftp/anon.conf /etc/vsftpd/
cp /vagrant/ftp/local.conf /etc/vsftpd/

# To avoid errors
sed -i 's,\r,,;s, *$,,' /etc/vsftpd/local.conf
sed -i 's,\r,,;s, *$,,' /etc/vsftpd/anon.conf

    #--------------Anonymmous server-----------------#

    # Create the anon users' landing directory 
    mkdir /srv/ftp/public
    # Make sure that they cannot modify the folder itself.
    chmod 755 /srv/ftp/public
    # Copy the .message
    cp /vagrant/ftp/.message /srv/ftp/public/

    #------------------Local server-------------------#

    # Copy the key pair
    cp /vagrant/ftp/private_key.pem /etc/ssl/private/
    cp /vagrant/ftp/server.crt /etc/ssl/certs/
    # Create the users
    useradd -m -s /bin/bash charles
    echo 'charles:1234' | chpasswd
    useradd -m -s /bin/bash laura
    echo 'laura:1234' | chpasswd
    # Copy the jailed list file
    cp /vagrant/ftp/vsftpd.chroot_list /etc/ 

# Create two different services
cp /vagrant/ftp/vsftpd-anon.service /etc/systemd/system/
cp /vagrant/ftp/vsftpd-local.service /etc/systemd/system/

# Disable the default service and enable ours
systemctl disable --now vsftpd
systemctl enable --now vsftpd-anon
systemctl enable --now vsftpd-local

# Stablish the name server 
cp /vagrant/ftp/resolv.conf /etc/