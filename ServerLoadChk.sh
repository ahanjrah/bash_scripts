#!/usr/bin/env bash

init() {
    EMAIL="aman.hanjrah@gmail.com"
}
# Check if required packages are installed.
chkPackage() {
CHECK_MUTT=$(rpm -qa | grep mutt)
    if [[ -z "$CHECK_MUTT" ]]; then
    INSTALL_MUTT=$(yum install mutt -y 2> /tmp/muttlog.log)
        if [[ -n $(cat /tmp/muttlog.log) ]]; then
            echo -e "Mutt not installed, exiting!"
            exit 1
        fi
    fi
CHECK_SYSSTAT=$(rpm -qa | sysstat)
    if [[ -z "$CHECK_SYSSTAT" ]]; then
    INSTALL_SYSSTAT=$(yum install sysstat -y 2> /tmp/sysstatlog.log)
        if [[ -n $(cat /tmp/sysstatlog.log) ]]; then
            echo -e "Sysstat package not installed, exiting!"
            exit 1
        fi
    fi
}
# Check current load on the server.
chkCurrentLoad() {
TEMP_FILE=$(mktemp)
sar -u 1 5 | grep -i average | tr -s ' ' | cut -d' ' -f5 > $TEMP_FILE
	if [[ $(cat /etc/"$TEMP_DIR") > 3.00 ]]; then # Test if the server load is above 3. If yes, check if the last email sent was within the last 600 seconds.
        checkLastEmail
    else
        return 0
    fi
}
# Check when was the last email sent.
chkLastEmail() {
CHK_DIFF=`expr $(date "+%s") - $(cat muttlog.log)`
	if [[ "$CHK_DIFF" < 600 ]]; then # Tests if the last email was sent within 600 seconds. If yes, do nothing, if it has been more than 600 seconds, then send email.
		return 0
	else
		sendEmail
	fi
}
# Update muttlog file with current time.
chkMuttLog() {
	if [[ -z /tmp/muttlog.log ]]; then
		echo $(date "+%s") > /tmp/muttlog.log
	else
		return 0
	fi
}
# Send email with stats in the body.
sendEmail() {
	{ date "+%s"; echo "Server is under load greater than 3, current load is: $(sar -u 1 1 | grep -i average | tr -s ' ' | cut -d' ' -f5)" | mutt -s "[Critical!] Server Under High Load" -- $EMAIL; } > muttlog.log
}
# Run the functions.
 main() {
    init
    chkMutt
 	chkMuttLog
 	chkCurrentLoad
 }

main