#!/bin/bash

cat /etc/crontab > /root/script/new
DIFF=$(diff new tmp)
if [ "$DIFF" != "" ]; then
	cp mail_type.txt mail.txt
	diff new tmp >> mail.txt
	sudo sendmail -vt < ./mail.txt
	rm -f /root/script/tmp
	cp /root/script/new /root/script/tmp
fi