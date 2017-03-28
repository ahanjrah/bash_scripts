#!/bin/bash
#
# Author: Aman Hanjrah
# License: GNU GPL v2.0
# Description: Quick way to upload a file to servers and share direct URL right from the terminal.

DST_URL="http://pomf.se/upload.php"
RTRN_URL="http://a.pomf.se"

        if [ $# -lt 1 ]
        then
                echo "File does not exist."
		echo "Usage: `basename $0` [file1] [file2] ... [n]"
                echo "Hit 'ENTER' to exit."
                echo " "
                read
                exit 1
        fi
function upload() {
	if [[ "$i" = *.@(jpg|png|svg|jpeg|gif|bmp|tif|tiff|JPEG|PNG|SVG|JPEG|GIF|BMP|TIF|TIFF) ]]
	then
		echo "Uploading in progress..."
	OUTPUT=`curl -sS -F files[]=@"$i" "$DST_URL" | cut -d "," -f5 | cut -d":" -f 2 | tr '"' " " | cut -d" " -f2`
		echo "$i: $RTRN_URL/$OUTPUT"
		echo " "
	elif [[ "$i" = *.@(txt|csv|html|xhtml|php|sh|xml|rtf|conf|sql) ]]
	then
		echo "Uploading in progress..."
	OUTPUT=`cat "$i" | curl -sS -F 'sprunge=<-' http://sprunge.us`
		echo "$i: $OUTPUT"
		echo " "
	else
		echo "File is of unknown extension, please let me know should I upload it to 'SPRUNGE' (text files), or 'POMF' (image files). Select one of the numbers below corresponding to the type of the file"
		echo "1. Image file"
		echo "2. Text file"
		read "TYPE"
		if (( "$TYPE" == 1 ))
		then
			echo "Uploading in progress..."
			OUTPUT1=`curl -sS -F files[]=@"$i" "$DST_URL" | cut -d "," -f5 | cut -d":" -f 2 | tr '"' " " | cut -d" " -f2`
			echo "$i: $RTRN_URL/$OUTPUT"
			echo " "
		elif (( "$TYPE" == 2 ))
		then
			echo "Uploading in progress..."
			OUTPUT1=`cat "$i" | curl -sS -F 'sprunge=<-' http://sprunge.us`
			echo "$i: $OUTPUT1"
			echo " "
		fi
	
	fi
}

for i in "$@"; do
	upload
done
