#!/bin/bash -e
sudo apt-get update -y
sudo apt-get install -y jq

echo 'export PATH=$PATH:/vagrant' >> ~/.profile
echo '[ ! -d /var/log/chimera ] && sudo mkdir /var/log/chimera' >> ~/.profile
echo 'sudo chown vagrant /var/log/chimera' >> ~/.profile
echo '[ ! -d /home/vagrant/data ] && mkdir /home/vagrant/data' >> ~/.profile
echo 'export DATA_FOLDER=/home/vagrant/data' >> ~/.profile
source ~/.profile