 #!/usr/bin/env bash

#
# Date: 2 December, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used to install and configure OpenVPN.
#

main() {
	clear
	echo -e "------------------"
	echo -e "Installing OpenVPN"
	echo -e "------------------"
	prerequisites
	sleep 1
	listIP
	askIP
	installPackages
	sleep 1
	cloneRSA
	sleep 1
	runCommands
	sleep 1
	makeServerConfFile
	sleep 1
	addUser
	sleep 1
	makeClientConfFile
	sleep 1
	moveClientConf
	sleep 1
	changeIPTables
	sleep 1
	startServices
	echo -e "-----------------------------------------------"
	echo -e "Installation of OpenVPN successfully completed "
	echo -e "-----------------------------------------------"
	echo -e "Press enter to exit."
	read
	echo -e "For other technical stuff please visit the following sites:\nhttp://phpnmysql.com\nhttp://techlinux.net"
	sleep 1
	exit 0
}

prerequisites() {
	sh install-repo.sh
	txtBold=`tput bold`
	txtNormal=`tput sgr0`
	init
}

init() {
	PACKAGES=(gcc make rpm-build autoconf.noarch zlib-devel pam-devel openssl-devel openvpn git.x86_64)
}

listIP() {
	echo -e "Following are the IP address(s) on this server:"
	IP_LIST=`ifconfig  | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
	echo -e "$IP_LIST"
	echo -e "-------------------------"
}

askIP() {
	unset IP
	echo -e "Enter the IP address which you want to use for OpenVPN\n-------------------------"
	read -e IP
	if [[ -z "$IP" ]]; then
		askIP
	fi
}

installPackages() {
	echo -e "Please wait while we are installing requried packages...\n-------------------------"
	for PACKAGE in "${PACKAGES[@]}"
	do
		CHK_PACKAGE=`rpm -qa | grep "$PACKAGE"`
		if [[ ! -n "$CHK_PACKAGE" ]]; then
			yum -y install "$PACKAGE" >> /dev/null
			unset CHK_PACKAGE
		fi
	done
	echo -e "Required packages successfully installed.\n-------------------------"
}

cloneRSA() {
	echo -e "Cloning easy-ras form git server...\n-------------------------"
	CLONE=`git clone https://github.com/OpenVPN/easy-rsa-old.git /tmp/easy-rsa` 2> /tmp/openvpn.log
	if [[ ! -d /tmp/easy-rsa ]]; then
		echo -e "Cloning failed."
	else
		cp -var /tmp/easy-rsa /etc/openvpn/ >> /dev/null
		sed -i 's#export KEY_CONFIG=`$EASY_RSA/whichopensslcnf $EASY_RSA`#export KEY_CONFIG=/etc/openvpn/easy-rsa/easy-rsa/2.0/openssl-1.0.0.cnf#g' /etc/openvpn/easy-rsa/easy-rsa/2.0/vars
		echo -e "easy-rsa successfully cloned.\n-------------------------"
	fi
}

runCommands() {
	cd /etc/openvpn/easy-rsa/easy-rsa/2.0/
	source vars >> /dev/null
	sleep 1
	./clean-all >> /dev/null
	sleep 1
	./build-ca
	sleep 1
	./build-key-server server
	sleep 1
	./build-dh >> /dev/null
}

makeServerConfFile() {
cat << EOF >> /etc/openvpn/server.conf
port 1194
proto udp
dev tun
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
reneg-sec 0
ca /etc/openvpn/easy-rsa/easy-rsa/2.0/keys/ca.crt
cert /etc/openvpn/easy-rsa/easy-rsa/2.0/keys/server.crt
key /etc/openvpn/easy-rsa/easy-rsa/2.0/keys/server.key
dh /etc/openvpn/easy-rsa/easy-rsa/2.0/keys/dh1024.pem
plugin /usr/lib64/openvpn/plugin/lib/openvpn-auth-pam.so /etc/pam.d/login 
client-cert-not-required
username-as-common-name
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 5 30
comp-lzo
persist-key
persist-tun
status 1111.log
verb 3
EOF
}

askUsername() {
	unset VPN_USER
	echo -e "Choose the username for VPN\n-------------------------"
	read -e VPN_USER
	if [[ -z "$VPN_USER" ]]; then
		askUsername
	fi
}

askPassword() {
	unset VPN_PASS
	echo -e "Choose the password for VPN\n-------------------------"
	read -e VPN_PASS
	if [[ -z "$VPN_PASS" ]]; then
		askPassword
	fi
}

addUser() {
	askUsername
	askPassword
	ADD_USR=`useradd $VPN_USER -s /sbin/false && echo "$VPN_PASS" | passwd "$VPN_USER" --stdin` >> /dev/null
}

makeClientConfFile() {
cat << EOF >> /root/client.ovpn
client
dev tun
proto udp
remote "$IP" 1194 # Your server IP and OpenVPN Port
resolv-retry infinite
nobind
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
persist-key
persist-tun
ca ca.crt
auth-user-pass
comp-lzo
reneg-sec 0
verb 3
EOF
}

moveClientConf() {
	echo -e "Creating certificate and configuration file for client...\n-------------------------"
	cd
	PWD=`pwd`
	cp /etc/openvpn/easy-rsa/easy-rsa/2.0/keys/ca.crt ./ca.crt
	cp /root/client.ovpn ./client.ovpn
	tar -czf client.tar.gz ca.crt client.ovpn >> /dev/null
	rm -rf ca.crt client.ovpn
	echo -e "Client's certificate and configuration file successfully created.\nYou can download it from $PWD/client.tar.gz\n"
}

changeIPTables() {
	sed -i 's#net.ipv4.ip_forward = 0#net.ipv4.ip_forward = 1#g' /etc/sysctl.conf
	sysctl -e -p >> /dev/null
	iptables -t nat -A POSTROUTING -o venet0 -j SNAT --to-source "$IP"
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source "$IP"
	IPTABLES=`service iptables save` >> /dev/null
}

startServices() {
	service openvpn start >> /dev/null
}
main

