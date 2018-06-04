#!/usr/bin/env bash
#
# Date: 23 November, 2016
# Author: Aman Hanjrah
# License: GNU GPL v2.0
# Description: A simple script to add a new user along with user keys and disable password authentication and direct root logins.
#
set -x
if [[ $# -lt 1 ]]; then
  echo "Please provide a username"
  echo "Usage: sh `basename $0` username"
  exit 1
fi
  # Check if needed packages are installed or not
function packages_check() {
  P1="cronie"
  P2="sudo"
  if [[ -z $(rpm -qa | grep $P1) ]]; then
    yum install $P1 -y >> /dev/null
  fi
  if [[ -z $(rpm -qa | grep $P2) ]]; then
    yum install $P2 -y >> /dev/null
  fi
}

USERN=$1
function init() {
  PASSPHRASE=$(date | md5sum | cut -d" " -f1)
  SSHDIR="/home/$USERN/.ssh"
  KEYNAME="/home/$USERN/.ssh/key-$USERN"
  check_if_user_exist
}
# Check if the mentioned username already exists
function check_if_user_exist() {
CHK_USER=$(getent passwd | grep $USERN)
  if [[ $? == 1 ]]; then
    useradd -m $USERN
    echo "User added"
  else
    echo "User already exists in the system."
    echo "Please use a different username."
    exit 1
  fi
}
# Generate SSH keys
function gen_keys() {
# make directory to store the SSH keys
cd /home/$USERN
if [[ $? == 0 ]]; then
  mkdir .ssh && chown -cR $USERN.$USERN /home/$USERN/.ssh >> /dev/null && cd .ssh
else
  echo "Cannot change directory to newly created user."
  exit 1
fi
# Generate SSH keys and set correct permissions
ssh-keygen -t rsa -b 4096 -C "generated by a script" -P "$PASSPHRASE" -f "$KEYNAME" -q
if [[ $? == 0 ]]; then
  chown -cR $USERN.$USERN $KEYNAME >> /dev/null
  chown -cR $USERN.$USERN $KEYNAME.pub >> /dev/null
  chmod 0700 $SSHDIR
  chmod 0600 $KEYNAME
  cat $KEYNAME.pub >> $SSHDIR/authorized_keys
  rm -f $KEYNAME.pub
  chmod 0600 $SSHDIR/authorized_keys
  chown -cR $USERN.$USERN $SSHDIR/authorized_keys
  if [[ $? == 0 ]]; then
    echo "Please MOVE your private key, named: $KEYNAME from $SSHDIR to your system."
    echo "Your passphrase is: $PASSPHRASE, please save it to a secure location."
    no_root_login
  fi
else
  echo "Something went wrong while generating the SSH keys."
  exit 1
fi
}
function no_root_login() {
  sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  systemctl restart sshd
  if [[ $? == 0 ]]; then
    echo "Direct 'root' login and password authentication disabled."
  fi
}
# Add the newly created user to sudoers list with no password required switch
function no_passwd_sudo() {
  echo "$USERN  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  echo "User "$USERN" added in sudoers list successfully!"
}
# Run the script
init
packages_check
gen_keys
no_passwd_sudo
