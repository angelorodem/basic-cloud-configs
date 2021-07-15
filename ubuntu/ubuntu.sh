#!/bin/bash

echo "This script will configure a Ubuntu 20 instance"

# Add 1g swap
echo "Adding 1g Swap"
fallocate -l 1G /swapfile
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
chown root:root /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab
swapon --show
echo 0 | sudo tee /proc/sys/vm/swappiness
echo vm.swappiness = 0 | sudo tee -a /etc/sysctl.conf


# automatic reboot at night
echo "Setting automatic reboot at night"
(crontab -l 2>/dev/null; echo "0 4 * * * /sbin/shutdown -r +5") | crontab -

# Auto update security
# AWS Ubuntu 20 is already configured

echo "Updating OS"
apt-get update
apt-get full-upgrade -yy

echo "Installing Fail2ban"
apt-get install fail2ban -yy
cp ../generic/jail.local /etc/fail2ban/jail.local
service enable fail2ban
service start fail2ban


OSSEC_VERSION="3.6.0"
echo "Installing OSSEC $OSSEC_VERSION"
#Deps
apt-get install gcc make libevent-dev zlib1g-dev libssl-dev libpcre2-dev wget tar build-essential -y
wget https://github.com/ossec/ossec-hids/archive/$OSSEC_VERSION.tar.gz
tar xzf $OSSEC_VERSION.tar.gz
./ossec-hids-*/install.sh
rm -rf $OSSEC_VERSION.tar.gz ossec-hids-*/
systemctl enable ossec
systemctl start ossec
service status ossec
#sudo systemctl enable ossec


# OPTIONAL
read -p "Install Cloudwatch agent [y/N]? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Installing agent"
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i -E ./amazon-cloudwatch-agent.deb
    cp ../generic/cloudwatch_config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
fi



read -p "Use Bad ip blocker? [y/N]? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Installing bad ip blocker"
    apt-get install python3 python3-pip
    yes | pip3 install requests
    cp ../generic/badblocker.py /root/badblocker.py
    (crontab -l 2>/dev/null; echo "*/20 * * * * python3 /root/badblocker.py") | crontab -    
fi


