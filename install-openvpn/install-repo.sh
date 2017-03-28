#!/usr/bin/env bash

installRepos() {
	ARCHITECTURE=`uname -m`
	OS_VERSION=`cat /etc/redhat-release | cut -d" " -f4 | cut -c1`
	CHK_EPEL=`rpm -qa | grep epel-release`

	if [[ ! -n "$CHK_EPEL" ]]; 
		then
			cd /tmp
			curl -O -f http://dl.fedoraproject.org/pub/epel/$OS_VERSION/$ARCHITECTURE/epel-release-$OS_VERSION-[0-9].noarch.rpm >> /tmp/epel.log 2>&1
			rpm -Uh /tmp/epel-release* >> /tmp/epel.log 2>&1

			rm -rf /tmp/epel-release*
			cd - >> /dev/null
	fi
}

installRepos

