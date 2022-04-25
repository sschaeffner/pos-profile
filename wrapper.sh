#!/bin/bash

REPO_DIR=/local/repository
LOG_DIR=$REPO_DIR

$REPO_DIR/install.sh &> $LOG_DIR/install_log.txt
