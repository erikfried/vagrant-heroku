#!/bin/sh
# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

date > /etc/vagrant_box_build_time

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline5-dev
apt-get -y install git-core vim

# install java (openjdk 7)
apt-get -y install openjdk-7-jre
apt-get -y install openjdk-7-jdk
apt-get -y install icedtea6-plugin
rm /etc/alternatives/java
ln -s  /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java /etc/alternatives/java

# Apt-install python tools and libraries
# libpq-dev lets us compile psycopg for Postgres
apt-get -y install python-setuptools python-dev libpq-dev pep8

# Setup sudo to allow no-password sudo for "admin"
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers
echo "vagrant ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install NFS client
apt-get -y install nfs-common

# Install Ruby from source in /opt so that users of Vagrant
# can install their own Rubies using packages or however.
wget http://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.bz2
tar jxf ruby-2.0.0-p247.tar.bz2
cd ruby-2.0.0-p247
./configure --prefix=/opt/ruby
make
make install
cd ..
rm -rf ruby-2.0.0-p247*
chown -R root:admin /opt/ruby
chmod -R g+w /opt/ruby

# Install RubyGems 2.0.3
wget http://production.cf.rubygems.org/rubygems/rubygems-2.0.3.tgz
tar xzf rubygems-2.0.3.tgz
cd rubygems-2.0.3
/opt/ruby/bin/ruby setup.rb
cd ..
rm -rf rubygems-2.0.3*

# Installing chef & Puppet
/opt/ruby/bin/gem install chef --no-ri --no-rdoc
/opt/ruby/bin/gem install puppet --no-ri --no-rdoc
/opt/ruby/bin/gem install bundler --no-ri --no-rdoc

# Add the Puppet group so Puppet runs without issue
groupadd puppet

# Install Foreman
/opt/ruby/bin/gem install foreman --no-ri --no-rdoc

# Install pip, virtualenv, and virtualenvwrapper
easy_install pip
pip install virtualenv
pip install virtualenvwrapper

# Add a basic virtualenvwrapper config to .bashrc
echo "export WORKON_HOME=/home/vagrant/.virtualenvs" >> /home/vagrant/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> /home/vagrant/.bashrc

# Install PostgreSQL 9.2.4
#wget http://ftp.postgresql.org/pub/source/v9.3.2/postgresql-9.3.2.tar.bz2
#tar jxf postgresql-9.3.2.tar.bz2
#cd postgresql-9.3.2
#./configure --prefix=/usr
#make world
#make install-world
#cd ..
#rm -rf postgresql-9.3.2*
#
## Initialize postgres DB
#useradd -p postgres postgres
#mkdir -p /var/pgsql/data
#chown postgres /var/pgsql/data
#su -c "/usr/bin/initdb -D /var/pgsql/data --locale=en_US.UTF-8 --encoding=UNICODE" postgres
#mkdir /var/pgsql/data/log
#chown postgres /var/pgsql/data/log
#
## Start postgres
#su -c '/usr/bin/pg_ctl start -l /var/pgsql/data/log/logfile -D /var/pgsql/data' postgres

# Start postgres at boot
#sed -i -e 's/exit 0//g' /etc/rc.local
#echo "su -c '/usr/bin/pg_ctl start -l /var/pgsql/data/log/logfile -D /var/pgsql/data' postgres" >> /etc/rc.local

# Install NodeJs for a JavaScript runtime
git clone https://github.com/joyent/node.git
cd node
git checkout v0.10.24
./configure --prefix=/usr
make
make install
cd ..
rm -rf node*

# Add /opt/ruby/bin to the global path as the last resort so
# Ruby, RubyGems, and Chef/Puppet are visible
echo 'PATH=$PATH:/opt/ruby/bin' > /etc/profile.d/vagrantruby.sh

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /home/vagrant
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Install Heroku toolbelt
wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh

# Install some libraries
apt-get -y install libxml2-dev libxslt-dev curl libcurl4-openssl-dev
apt-get -y install imagemagick libmagickcore-dev libmagickwand-dev
apt-get clean

# Set locale
echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale

# Add 'vagrant' role
# su -c 'createuser vagrant -s' postgres

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
exit
exit
