apt-get -y update
apt-get -y upgrade

apt-get -y install build-essential python2.7-dev git libxml2 libxml2-dev libxml2-utils libxslt1.1 libxslt1-dev libzmq1 libzmq-dev tmux

mkdir -p /mnt/data
mount /dev/xvdc /mnt/data

curl -O http://python-distribute.org/distribute_setup.py
python distribute_setup.py
easy_install pip
pip install -r /mnt/data/polyglots/requirements.txt
pip install ipython tornado pyzmq

echo 'export IPYTHONDIR=/mnt/data/.ipython' > /home/ubuntu/.bashrc
