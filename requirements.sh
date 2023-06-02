#!/bin/bash
# TODO: Make it for Debian, Suse & Mac

machine_type = $1

if [ -z $machine_type ]
then
    machine_type = "rhel"
fi

echo "Will run requirements for $machine_type"

### Requirements to run this script #####

echo "Set script runnable"
chmod +x *.sh

if [ "$machine_type" == "rhel" ]
then

    echo "Install wget"
    yum -y install wget

    echo "Install Git"
    yum -y install git

    echo "Install Unzip"
    yum -y install unzip

    echo "Install network packages"
    yum -y install dnsutils
    yum -y install bind-utils

    echo "Install Python 3"
    yum -y install python3

    echo "Install ansible"
    yum -y install epel-release
    yum -y install ansible



elif [ "$machine_type" == "debian" ]
then

elif [ "$machine_type" == "suse" ]
then

elif [ "$machine_type" == "mac" ]
then

fi

echo "Generates a local key"
mkdir -p ~/.ssh/
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''

echo "Install ansible required collections"
ansible-galaxy collection install community.general
ansible-galaxy collection install freeipa.ansible_freeipa
ansible-galaxy collection install community.crypto
