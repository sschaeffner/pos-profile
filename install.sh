#!/bin/bash

REPO_DIR=/local/repository
PROJECT_DIR="$(ls -d /proj/*)"
CREDENTIAL_DIR="$PROJECT_DIR/$(whoami)/cl"

mkdir -p $CREDENTIAL_DIR
chmod 700 $CREDENTIAL_DIR

if [ ! -e $CREDENTIAL_DIR/cloudlab.pem ]; then
	echo "Error: Upload cloudlab.pem credentials to $CREDENTIAL_DIR and re-run installation."
	exit 1
fi

if [ ! -e $CREDENTIAL_DIR/cloudlab.pwd ]; then
	echo "Error: Create file cloudlab.pwd containing cloudlab password in $CREDENTIAL_DIR and re-run installation."
	exit 1
fi

# TODO remove and use deployment key
cp $CREDENTIAL_DIR/id_ed25519 $REPO_DIR/
cp $CREDENTIAL_DIR/id_ed25519.pub $REPO_DIR/

set -x
set -e

ANSIBLE_DIR=/local/ansible
ANSIBLE_COMMIT=schaeffn-geni
HOSTVARS_FILE=$ANSIBLE_DIR/host_vars/poscontroller.geni.yml
KEY_FILE=$REPO_DIR/id_ed25519

# install apt dependencies
sudo add-apt-repository multiverse # required for snmp-mibs-downloader
sudo apt-get update
sudo apt-get install -y git python3 python-is-python3 python3-pip

# install ansible
sudo -H pip install ansible==2.9.16

# setup git
export GIT_SSH_COMMAND="ssh -i $KEY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new "
chmod 600 $KEY_FILE

# clone and checkout
git clone --recursive git@gitlab.lrz.de:I8-testbeds/setup/ansible.git $ANSIBLE_DIR
cd $ANSIBLE_DIR
git checkout $ANSIBLE_COMMIT

# install dependencies
pip3 install -r ./requirements.txt
pip3 install "Jinja2<3.1"

# install ansible modules
ansible-galaxy collection install community.crypto

# copy credentials
cp $CREDENTIAL_DIR/cloudlab.pem $ANSIBLE_DIR/roles/pos/files/cloudlab.pem
cp $CREDENTIAL_DIR/cloudlab.pem $ANSIBLE_DIR/roles/pos/files/cloudlab.key
cp $CREDENTIAL_DIR/cloudlab.pwd $ANSIBLE_DIR/roles/pos/files/cloudlab.pwd

# TODO maybe create this config via ansible, not sed

# pos config: fix ip
a="$(geni-get control_mac)"
CONTROLLER_IF_MAC=${a:0:2}:${a:2:2}:${a:4:2}:${a:6:2}:${a:8:2}:${a:10:2}
CONTROLLER_IF_NAME="$(ip -br link | grep $CONTROLLER_IF_MAC | awk '{print $1}')"
CONTROLLER_IF_IP="$(ip -f inet addr show $CONTROLLER_IF_NAME | awk '/inet / {print $2}')"
sed -i "/ip: /c\ip: $CONTROLLER_IF_IP" $ANSIBLE_DIR/host_vars/poscontroller.geni.yml

# pos config: fix username
USERNAME="$(whoami)"
sed -i "s/^\( *\)username: .*/\1username: $USERNAME/" $ANSIBLE_DIR/host_vars/poscontroller.geni.yml
sed -i "s/^\([ -]*\)name: student/\1name: $USERNAME/" $ANSIBLE_DIR/host_vars/poscontroller.geni.yml

# pos config: fix project name
PROJECT_NAME="$(geni-get portalmanifest | grep -oP '(?<=project=")\w+(?=")')"
sed -i "s/^\( *\)project_name: .*/\1project_name: $PROJECT_NAME/" $ANSIBLE_DIR/host_vars/poscontroller.geni.yml

# delete own deploy keys
rm -f $REPO_DIR/id_*

# delete credentials
rm -f $REPO_DIR/cloudlab*

# run ansible
# workaround to create pos user first (ssh role assumes it to exist)
ansible-playbook -i testbeds/geni/inventory-poscontroller.ini site.yml --tags users,posuser
ansible-playbook -i testbeds/geni/inventory-poscontroller.ini site.yml

# delete credentials
rm -f $ANSIBLE_DIR/roles/pos/files/cloudlab*
