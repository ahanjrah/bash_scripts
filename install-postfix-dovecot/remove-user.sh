#!/usr/bin/env bash

#
# Date: 26 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used remove the virtual user from email server. Before adding new user it will check the username/email address already exists or not.
#

main() {
	clear

	echo -e "---------------------------------------"
	echo -e "Removing user from postfix mail server."
	echo -e "---------------------------------------"

	acceptEmail

	if [ "$?" == 0 ];
		then
			removeUser
			reloadPostmap
			echo -e "---------------------------------------------------"
			echo -e "Email address: $EMAIL_ADDRESS removed successfully."
			echo -e "---------------------------------------------------"
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
	fi
}

acceptEmail() {
	# Input by user
	echo -e "Please choose a valid email address"
	read -e EMAIL_ADDRESS

	# Check pattern of email address

	if [[ ! "$EMAIL_ADDRESS" =~ ^[-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4} ]];
		then
			echo "-----------------------------"
			echo "Invalid email address entered"
			acceptEmail
		else
			chkEmailExistes
	fi
}

chkEmailExistes() {
	# Get all exixting email address

	if [[ ! -f "/etc/postfix/virtmail_mailbox" ]]; then
		touch /etc/postfix/virtmail_mailbox
	fi

	cat /etc/postfix/virtmail_mailbox | cut -d' ' -f1 > /tmp/list.txt
	EMAIL_EXIST=`grep -e "$EMAIL_ADDRESS" /tmp/list.txt`

	# Check new email address exists or not
	if [ -n "$EMAIL_EXIST" ];
		then
			return 0
		else
			echo "-----------------------------"
			echo "Email address you are trying to remove does not exist."
			acceptEmail
		fi
}

removeUser() {
	grep -Fv "$EMAIL_ADDRESS" /etc/postfix/virtmail_mailbox > /tmp/virtmail_mailbox.bak && mv -f /tmp/virtmail_mailbox.bak /etc/postfix/virtmail_mailbox
	grep -Fv "$EMAIL_ADDRESS" /etc/dovecot/passwd > /tmp/passwd.bak && mv -f /tmp/passwd.bak /etc/dovecot/passwd
}

reloadPostmap() {
	postmap /etc/postfix/virtmail_domains
	postmap /etc/postfix/virtmail_mailbox
	postmap /etc/postfix/virtmail_aliases
}

main

