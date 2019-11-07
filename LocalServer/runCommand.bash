#!/bin/bash

set -eo pipefail

# setup logging and other utilities
DIR=$(dirname "${BASH_SOURCE[0]}")  # get the directory name
DIR=$(realpath "${DIR}")    # resolve its full path if need be

export DO_NOT_LOG_TO_CONSOLE
source $DIR/util.bash 

function checkLogRotate() {
    set +e
    statusDir=/eio-data/log/logrotate

    # Clean non existent log file entries from status file

    if [ -d $statusDir ]; then
        echolog "logrotate: $statusDir exists"
    else
        echolog "logrotate: $statusDir does not exist"
    fi

    if [ -e $statusDir/status ]; then
        echolog "logrotate: $statusDir/status exists"
    else
        echolog "logrotate: $statusDir/status does not exist"
    fi

    if [ -x /usr/sbin/logrotate ]; then
        echolog "logrotate: /usr/sbin/logrotate is executable"
    else
        echolog "logrotate: /usr/sbin/logrotate is not executable"
    fi

    logrotatePermissions=$(stat --format "%a" /etc/logrotate.conf)
    if [ $logrotatePermissions -eq 644 ]; then
        echolog "logrotate: /etc/logrotate.conf has permissions 0644"
    else
        echolog "logrotate: /etc/logrotate.conf has permissions $logrotatePermissions"
    fi

    set -e
}

# https://forums.balena.io/t/how-to-debug-a-container-which-is-in-a-crash-loop/5638
function idleIfDebugSet() {
    if [ -n "$DEBUG" ]; then
        echolog "idleIfDebugSet() called."
        while : ; do
            echolog "Idling..."
            sleep 600
        done
    fi
}

function main() {
    echolog "starting web server"
    ./dummy-web-server.py --port 80 --listen "" >> $LOG_PATH
    echolog "web server exited with code $?"
}

idleIfDebugSet
main

