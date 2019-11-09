#!/bin/sh

# Modified by Jason Harrison, 20190930
# copy this file to /etc/cron/logrotate
# Changes:
# 1. define status dir on persistent storage using statusDir variable
# 2. added mkdir -p $statusDir
# 3. added --state=$statusDir/status to logrotate command line
statusDir=/data/log/logrotate
logfile=$statusDir/../logrotate.log
echo $(date +"[%Y-%m-%d %T]") "[$_]" >> $logfile

# Clean non existent log file entries from status file

mkdir -p $statusDir
cd $statusDir
test -e status || touch status
head -1 status > status.clean
sed 's/"//g' status | while read logfile date
do
    [ -e "$logfile" ] && echo "\"$logfile\" $date"
done >> status.clean
mv status.clean status

test -x /usr/sbin/logrotate || exit 0

/usr/sbin/logrotate /etc/logrotate.conf --state=$statusDir/status >> $logfile 2>&1
