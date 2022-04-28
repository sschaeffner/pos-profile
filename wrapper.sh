#!/bin/bash

REPO_DIR=/local/repository
LOG_DIR=$REPO_DIR

sudo apt-get update
sudo apt-get install -y python3 python-is-python3

USERNAME="$(geni-get user_urn | awk -F+ '{print $4}')"

sudo -u $USERNAME $REPO_DIR/install.sh &> $LOG_DIR/install_log.txt
