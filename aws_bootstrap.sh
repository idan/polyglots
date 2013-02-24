#!/bin/bash
set -e -x

# update and install various bits we need
apt-get -y update
apt-get -y upgrade
apt-get -y install build-essential python2.7-dev git libxml2 libxml2-dev libxml2-utils libxslt1.1 libxslt1-dev libzmq1 libzmq-dev tmux

# setup python and pip requirements
curl -O http://python-distribute.org/distribute_setup.py
python distribute_setup.py
easy_install pip
pip install ipython tornado pyzmq

# git clone our stuff
echo 'export IPYTHONDIR=~/polyglots/.ipython' >> /home/ubuntu/.bashrc
echo 'export POLYGLOTS_REPOS=/mnt/data/repos' >> /home/ubuntu/.bashrc
sudo -u ubuntu -i git clone https://github.com/umbrellaco/polyglots.git
pip install -r /home/ubuntu/polyglots/requirements.txt

sudo -u ubuntu -i tmux new-session -d

# mount the snapshot of the git repos
mkdir -p /mnt/data
mount -r -o noatime,nodiratime,noacl,nouser_xattr /dev/xvdc /mnt/data


