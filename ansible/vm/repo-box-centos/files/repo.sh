#!/bin/bash

# Prepare the box and install Apache
yum -y check-update

# Python bindings are required (because of selinux)
yum -y install libselinux-python

# Random Number Generator is required to create enough entropy to create
# new test signing keys
yum -y install rng-tools

# Install createrepo to manage rpm repository
yum -y install createrepo

# Expect is crucial during package signing,
# because 'rpm' does not give any possibility
# of performing the process in an non-interactive way
yum -y install expect

# Start rng daemon
service rngd start

# Prepare repo directory structure
if [ ! -f /var/www/repo ]
then
    echo 'Creating repo directory structure'
    mkdir -p /var/www/repo/stable/2.0/rhel/el6/i386 \
             /var/www/repo/stable/2.0/rhel/el6/x86_64 \
             /var/www/repo/stable/2.0/rhel/el7/x86_64
else
    echo 'Directory structure is already there.'
fi

# Create repositories
repo_root=/var/www/repo/stable/2.0/rhel
repo_dirs=($repo_root/el6/i386 $repo_root/el6/x86_64 \
           $repo_root/el7/x86_64)
for dir in ${repo_dirs[*]}
do
    createrepo $dir
done

# Copy gpg key config file
mkdir -p /opt/tmp/
cp /vagrant/files/key_config /opt/tmp/

# Generate Zato package test signing keys
gpg --batch --gen-key /opt/tmp/key_config

# Add private Zato package test signing key to the keyring
# Export the public key
gpg --armor --export example@example.com > /opt/tmp/zato-rpm-test.pgp.asc
# Import the public key to rpm
rpm --import /opt/tmp/zato-rpm-test.pgp.asc
echo "%_gpg_name Zato test signing key" > /etc/rpm/macros

# Copy public test Zato package signing key
if [ ! -f /var/www/repo/zato-rpm-test.pgp.asc ]
then
    sudo cp /opt/tmp/zato-rpm-test.pgp.asc /var/www/repo
else
    echo 'Zato repository test key already in place.'
fi
