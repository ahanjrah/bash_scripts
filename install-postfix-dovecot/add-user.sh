#!/usr/bin/env bash

#
# Date: 26 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used add a virtual user for email server. Before adding new user it will check the username/email address already exists or not.
#

main() {
	clear

	echo -e "----------------------------------------"
	echo -e "Adding new user for postfix mail server."
	echo -e "----------------------------------------"

	acceptEmail

	if [ "$?" == 0 ];
		then
			getPassword
			registerEmailAddress
			reloadPostmap
			echo -e "-------------------------------------------------"
			echo -e "Email address: $EMAIL_ADDRESS added successfully."
			echo -e "-------------------------------------------------"
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
	fi
}
acceptEmail() {
	# Input by user
	echo "Please choose a valid email address"
	read -e EMAIL_ADDRESS

	# Check pattern of email address

	if [[ ! "$EMAIL_ADDRESS" =~ ^[-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4} ]];
		then
			echo "-----------------------------"
			echo "Invalid email address entered"
			acceptEmail
		else
			chkUniqueEmail
	fi
}

chkUniqueEmail() {
	# Get all exixting email address

	if [[ ! -f "/etc/postfix/virtmail_mailbox" ]]; then
		touch /etc/postfix/virtmail_mailbox
	fi

	cat /etc/postfix/virtmail_mailbox | cut -d' ' -f1 > /tmp/list.txt
	EMAIL_EXIST=`grep -e "$EMAIL_ADDRESS" /tmp/list.txt`

	# Check new email address exists or not
	if [ -n "$EMAIL_EXIST" ];
		then
			echo "-----------------------------"
			echo "Email already registered. Please choose different email address"
			acceptEmail
		else
			return 0
		fi
}

splitEmailAddress() {
	DOMAIN_ADDR=`echo $EMAIL_ADDRESS | cut -d'@' -f 2`
	USER_ADDR=`echo $EMAIL_ADDRESS | cut -d'@' -f 1`
}

chkUniqueDomain() {
	
	if [[ ! -f "/etc/postfix/virtmail_domains" ]]; then
		touch /etc/postfix/virtmail_domains
	fi

	cat /etc/postfix/virtmail_domains | cut -f1 > /tmp/tmp_domain.txt
	DOMAIN_EXIST=`grep -e "$DOMAIN_ADDR" /tmp/tmp_domain.txt`
	if [ -z "$DOMAIN_EXIST" ];
		then
			echo -e "$DOMAIN_ADDR\t\tOK" >> /etc/postfix/virtmail_domains
		fi

}

registerEmailAddress() {
	splitEmailAddress
	echo -e "$EMAIL_ADDRESS\t\t$DOMAIN_ADDR/$USER_ADDR/" >> /etc/postfix/virtmail_mailbox
	chkUniqueDomain
	echo -e "$EMAIL_ADDRESS\t\t$EMAIL_ADDRESS" >> /etc/postfix/virtmail_aliases
}

chkPasswordFile() {
	if [[ ! -f "/etc/dovecot/passwd" ]]; 
		then
			touch /etc/dovecot/passwd
			chown root: /etc/dovecot/passwd
			chmod 600 /etc/dovecot/passwd
		fi
}

getPassword() {
	chkPasswordFile
	PASSWORD=`doveadm pw -s sha1 | cut -d '}' -f2`
	echo "$EMAIL_ADDRESS:$PASSWORD" >> /etc/dovecot/passwd
}

reloadPostmap() {
	postmap /etc/postfix/virtmail_domains
	postmap /etc/postfix/virtmail_mailbox
	postmap /etc/postfix/virtmail_aliases
}

main

