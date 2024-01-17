#!/bin/bash

# FTP Practice -- Antonia Sáez Camacho

#----------------------------------------------------------#
#-----------------------DNS server-------------------------#
#----------------------------------------------------------#

# Install the service
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt-get install -y bind9 bind9-utils bind9-doc
unset DEBIAN_FRONTEND

# Copy the configuration files
cp /vagrant/dns/named /etc/default/
cp /vagrant/dns/named.conf.options /etc/bind
cp /vagrant/dns/named.conf.local /etc/bind
cp /vagrant/dns/sri.ies.dns /var/lib/bind
cp /vagrant/dns/192.168.57.rev /var/lib/bind

# Restart the service
systemctl restart bind9
systemctl status bind9