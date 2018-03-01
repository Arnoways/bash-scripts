#!/bin/bash

#use this script to send some files or folders to a ftp server
#modify retentiondays var if you want the backup cycle to be shorter or longer


CURRENTDATE="`date +'%Y-%m-%d'`"
#ftp server
URL=
USER=
PASS=
FILE=
RETENTIONDAYS=15

ftp -n "$URL" <<END_SCRIPT
quote user "$USER"
quote pass "$PASS"
prompt off
dir / list.txt
END_SCRIPT

awk '{print $9}' list.txt > dirlist.txt
sed -i '1,4 d' dirlist.txt
sort dirlist.txt
NBLINES="$(wc -l < dirlist.txt)"
if [ ${NBLINES} -gt  ${RETENTIONDAYS} ]
then
DELETEME="$(sed '1!d' dirlist.txt)"
	ftp -n "$URL" <<END_SCRIPT
	quote user "$USER"
	quote pass "$PASS"
	prompt off
	mdelete "${DELETEME}"/*
	rmdir "${DELETEME}"/
END_SCRIPT
fi

ftp -n "$URL" <<END_SCRIPT
quote user "$USER"
quote pass "$PASS"
prompt off
mkdir "$CURRENTDATE"
put "$FILE" "$CURRENTDATE"/filename
quit
END_SCRIPT
rm list.txt dirlist.txt

