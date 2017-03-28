#!/usr/bin/env bash

#
# Date: 1 December, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used to check the status of all the services, if stopped then script will try to start the service, if the service is started, the script will send a notification email using mutt.
#
# Define all the funtions in one funtion.
# NOTE: Works in EL 6.x only
#
main() {
	prerequisites
	init
	chkAllServices
	sendMail
}
# Check if mutt is installed
prerequisites() {
	CHK_MUTT=`rpm -qa | grep mutt`
	if [[ ! -n '$CHK_MUTT' ]]; then
		yum -y install mutt
		unset CHK_MUTT
		CHK_MUTT=`rpm -qa | grep mutt`
		if [[ ! -n "$CHK_MUTT" ]]; then
			exit 1
		fi
	fi
}
# Define some variables that we are going to use.
init() {
	EMAIL_TO="aman.hanjrah@gmail.com"
	SER_APACHE="httpd"
	SER_NGINX="nginx"
	SER_MYSQLD="mysqld"
	SER_PHP_FPM="php-fpm"
	SER_PERCONA="mysql"
	SER_POSTFIX="postfix"
	SER_DOVECOT="dovecot"
}
# Add funtions at one place.
chkAllServices() {
	chkHttpd
	chkNginx
	chkPHP_FPM
	chkMySQLD
	chkPercona
	chkPostfix
	chkDovecot
}
# Check if httpd service is running.
chkHttpd() {
	CHK_APACHE=`rpm -qa | grep httpd`
	if [[ -n "$CHK_APACHE" ]]; then
		SERVICE="$SER_APACHE"
		chkService
	fi
}
# Check if nginx service is running
# You can either have httpd or nginx running at one time, comment out the one that you are not intended to use.
chkNginx() {
	CHK_NGINX=`rpm -qa | grep nginx`
	if [[ -n "$CHK_NGINX" ]]; then
		SERVICE="$SER_NGINX"
		chkService
	fi
}
# Check if php-fpm service is running
chkPHP_FPM() {
	CHK_PHP_FPM=`rpm -qa | grep php-fpm`
	if [[ -n "$CHK_PHP_FPM" ]]; then
		SERVICE="$SER_PHP_FPM"
		chkService
	fi
}
# Check if MySQL service is running
chkMySQLD() {
	CHK_MYSQLD=`rpm -qa | grep mysql-server`
	if [[ -n "$CHK_MYSQLD" ]]; then
		SERVICE="$SER_MYSQLD"
		chkService
	fi
}
# Check if Percona service is running
# Since MySQL and Percona uses the same port by default, only one can be run, comment out the one that you are not intended to use.
chkPercona() {
	CHK_PERCONA=`rpm -qa | grep Percona-Server`
	if [[ -n "$CHK_PERCONA" ]]; then
		SERVICE="$SER_PERCONA"
		chkService
	fi
}
# check if postfix service is running
chkPostfix() {
	CHK_POSTFIX=`rpm -qa | grep postfix`
	if [[ -n "$CHK_POSTFIX" ]]; then
		SERVICE="$SER_POSTFIX"
		chkService
	fi
}
# Check if DoveCot service is running
chkDovecot() {
	CHK_DOVECOT=`rpm -qa | grep dovecot`
	if [[ -n "$CHK_DOVECOT" ]]; then
		SERVICE="$SER_DOVECOT"
		chkService
	fi
}

chkService() {
	STATUS=$(/etc/init.d/$SERVICE status) # Check the current status of service
	if [[ $(echo $?) != 0 ]]; then
		$(/etc/init.d/$SERVICE start) # Try to start the service
		NEW_STATUS=$(/etc/init.d/$SERVICE status) # Record the new status
		if [[ $(echo $?) != 0 ]]; then # Check if the exit code is 0, if not, log it in a file
			touch /tmp/srv_ser_err.log
			echo -e "$SERVICE" >> /tmp/srv_ser_err.log
		fi
	fi
	# unset the variables
	unset SERVICE
	unset STATUS
	unset NEW_STATUS
}
# Send email to the admin
sendMail() {
	if [[ -s /tmp/srv_ser_err.log ]]; then
		ERRORS=`cat /tmp/srv_ser_err.log`
		echo -e "An attempt to start the following service(s) Failed!\n$ERRORS" | mutt -s "[CRITICAL] Server Alert!" -- $EMAIL_TO
		rm -rf /tmp/srv_ser_err.log
	fi
}
# Run main funtion
main
