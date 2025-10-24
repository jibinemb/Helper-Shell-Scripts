#!/bin/bash
####################################################
#Author: Jibin
#Date: 2025/10/22
# This script output list of cron user's job's 
####################################################
set -x #debug mode

set -e # exit the scrips when there is an error

set -o pipefail

for USER in $(cut -f1 -d: /etc/passwd); do \
USERTAB="$(sudo crontab -u "$USER" -l 2>&1)";  \
FILTERED="$(echo "$USERTAB"| grep -vE '^#|^$|no crontab for|cannot use this program')";  \
if ! test -z "$FILTERED"; then  \
echo "# ------ $(tput bold)$USER$(tput sgr0) ------";  \
echo "$FILTERED";  \
echo "";  \
fi;  \
done
