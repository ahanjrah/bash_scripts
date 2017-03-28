#!/usr/bin/env bash

#
# Date: 25 November, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used for the installation of postfix email server and dovecot. Before installation script will check exim or send mail servers are already installed or not, if installed, script will ask for the confirmation to remove them or not. If user don't want to remove them the script will be redirected to the main menu.
#

main() {
	clear
	echo -e "------------------------------"
	echo -e "Installing Postfix and Dovecot"
	echo -e "------------------------------"
	prerequisites
	sleep 1
	installPostfix
	sleep 1
	installDovecot
	sleep 1
	startServices
	echo -e "-------------------------------------------"
	echo -e "Postfix and Dovecot successfully installed."
	echo -e "-------------------------------------------"
	echo -e "Press enter to return to the main menu."
        read
        sh master-install.sh
        exit 0
}


prerequisites() {
	txtBold=`tput bold`
	txtNormal=`tput sgr0`
}

removeSendMail() {
	CHK_SENDMAIL=`rpm -qa | grep sendmail`
	if [ -n "$CHK_SENDMAIL" ]; then
		echo "SendMail is already installed."
		echo -e "Do you want to remove SendMail?"
		echo -e "${txtBold}Press 'yes' to uninstall or press 'no' to exit.${txtNormal}"
		takeUserInput
		case "$USERINPUT" in
				[yY] | [yY][Ee][Ss] )
					echo -e "Removing SendMail...\n--------------------"
					yum -y remove sendmail* >> /dev/null
					echo -e "SendMail successfully removed.\n--------------------"
				;;

				[nN] | [nN][oO] )
					echo -e "Press enter to return to the main menu."
					read
					sh master-install.sh
					exit 0
				;;

				*)
					echo -e "${txtBold}Invalid input supplied...\nPlease choose the correct option.${txtNormal}"
					removeSendMail
				;;
			esac
	fi
}

removeExim() {
	CHK_EXIM=`rpm -qa | grep exim`
	if [ -n "$CHK_EXIM" ]; then
		echo "Exim is already installed."
		echo -e "Do you want to remove Exim?"
		echo -e "${txtBold}Press 'yes' to uninstall or press 'no' to exit.${txtNormal}"
		takeUserInput
		case "$USERINPUT" in
				[yY] | [yY][Ee][Ss] )
					echo -e "Removing Exim...\n--------------------"
					yum -y remove exim* >> /dev/null
					echo -e "Exim successfully removed.\n--------------------"
				;;

				[nN] | [nN][oO] )
					echo -e "Press enter to return to the main menu."
					read
					sh master-install.sh
					exit 0
				;;

				*)
					echo -e "${txtBold}Invalid input supplied...\nPlease choose the correct option.${txtNormal}"
					removeExim
				;;
			esac
	fi
}

installPostfix() {
	removeExim
	removeSendMail
	CHK_POSTFIX=`rpm -qa | grep postfix`
	if [ -n "$CHK_POSTFIX" ]; then
		echo -e "Postfix is already installed.\n--------------------"
		unset CHK_POSTFIX
		echo -e "Press enter to return to the main menu."
		read
		sh master-install.sh
		exit 0
	else
		echo -e "Installing Postfix...\n--------------------"
		addUserGroup
		yum -y install postfix* >> /dev/null
		changePostfixConf
		unset CHK_POSTFIX
		CHK_POSTFIX=`rpm -qa | grep postfix`
		if [ -n "$CHK_POSTFIX" ]; then
			echo -e "Postfix successfully installed.\n--------------------"
		else
			echo -e "Error while installing Postfix.\n--------------------"
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
		fi
	fi
}

changePostfixConf() {
	mv /etc/postfix/main.cf /etc/postfix/main.cf.bak
	cp /etc/postfix/master.cf /etc/postfix/master.cf.bak
	sed -i 's/#submission inet n       -       n       -       -       smtpd/submission inet n       -       n       -       -       smtpd/g' /etc/postfix/master.cf
	cp main.cf /etc/postfix/
}

addUserGroup() {
	groupadd virtmail -g  2100
	useradd virtmail -r -g  2100 -u 2100 -d /var/virtmail -m
}

installDovecot() {
	CHK_DOVECOT=`rpm -qa | grep dovecot`
	if [ -n "$CHK_DOVECOT" ]; then
		echo -e "Dovecot is already installed.\n--------------------"
		unset CHK_DOVECOT
		echo -e "Press enter to return to the main menu."
		read
		sh master-install.sh
		exit 0
	else
		echo -e "Installing Dovecot...\n--------------------"
		yum -y install dovecot >> /dev/null
		changeDovecotConf
		unset CHK_DOVECOT
		CHK_DOVECOT=`rpm -qa | grep dovecot`
		if [ -n "$CHK_DOVECOT" ]; then
			echo -e "Dovecot successfully installed...\n--------------------"
		else
			echo -e "Error while installing Dovecot.\n--------------------"
			echo -e "Press enter to return to the main menu."
			read
			sh master-install.sh
			exit 0
		fi
	fi
}

changeDovecotConf() {
	mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak
	cp dovecot.conf /etc/dovecot/
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

startServices() {
	service postfix start >> /dev/null
	service dovecot start >> /dev/null
	chkconfig postfix on >> /dev/null
	chkconfig dovecot on >> /dev/null
}

main

