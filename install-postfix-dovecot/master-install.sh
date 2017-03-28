#!/usr/bin/env bash

#
# Date: 27 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used for the installation of email server Postfix along with Dovecot and virtual users and domains. Script will also use to add and remove the users.
#

main() {
	clear
	echo -e "-----------------------------------------------"
	echo -e "Press the numbers for their corresponding tasks"	
	echo -e "1. Install Postfix and Dovecot on your server."
	echo -e "2. Add an email address."
	echo -e "3. Remove an email address."
	echo -e "4. Exit"
	echo -e "-----------------------------------------------"
	prerequisites
	processRequest

}

prerequisites() {
	txtBold=`tput bold`
	txtNormal=`tput sgr0`
}

takeUserInput() {
	unset "USERINPUT"
	read -e USERINPUT
	if [[ -z "$USERINPUT" ]]; 
		then
			echo -e "${txtBold}Please choose at least one option...\n${txtNormal}"
			takeUserInput
	fi
}

processRequest() {
	takeUserInput
	case "$USERINPUT" in
		1)
			sh install-postfix-dovecot.sh
		;;

		2)
			sh add-user.sh
		;;

		3)
			sh remove-user.sh
		;;

		4)
			clear
			echo -e "For other technical stuff please visit the following sites:\nhttp://phpnmysql.com\nhttp://techlinux.net"
			exit 0
		;;

		*)
			echo -e "${txtBold}Invalid input supplied...\nPlease choose the correct option.${txtNormal}"
			processRequest
	esac
}

main
