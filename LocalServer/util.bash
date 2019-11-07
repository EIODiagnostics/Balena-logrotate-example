#!/bin/bash
 
# common utility functions for balena container logging
function err_report() {
  echo "errexit on line $(caller)" >&2
}

trap err_report ERR

function initLogging() {
    if [ -z ${LOG_PATH+x} ]; then
         export LOG_PATH="/data/log/${BALENA_SERVICE_NAME}.log"
         echo "LOG_PATH not defined, using ${LOG_PATH}"
    fi
    echo "LOG_PATH = ${LOG_PATH}"

    mkdir -p $(dirname ${LOG_PATH})
    LOG_FOLDER_AND_PREFIX="${LOG_PATH%.*}"
    SCRIPT_LOG_LOCATION="${LOG_FOLDER_AND_PREFIX}-runCommand.log"
    echo "SCRIPT_LOG_LOCATION = ${SCRIPT_LOG_LOCATION}"

    if [ -n "$DO_NOT_LOG_TO_CONSOLE" ]; then 
        # set up logging only to file
        exec >> $SCRIPT_LOG_LOCATION
    else
       # set up logging to file and console
       exec > >(tee -a -i $SCRIPT_LOG_LOCATION)
    fi
    exec 2>&1

    OS_NAME=$(uname -s)

    LOG_FORMAT="[%Y-%m-%d %T]"
    # start log with a blank line just in case the last writter didn't output a newline
    echolog ""

    if [ "$OS_NAME" == "Darwin" ]; then
        LOG_FORMAT="[%Y-%m-%d %T.000000]"
        debuglog "Running on Darwin, LOG_FORMAT = $LOG_FORMAT"
    else
        LOG_FORMAT="[%Y-%m-%d %T.6N]"
        debuglog "Running on $OS_NAME, LOG_FORMAT = $LOG_FORMAT"
    fi
}

function initVariables() {
    if [ -z ${DELAY_SLEEP_SECONDS+x} ]; then
        export DELAY_SLEEP_SECONDS=0
    fi

    if [ -z ${LOG_LEVEL+x} ]; then
        DELAY_SLEEP_SECONDS=0
    elif [ "$LOG_LEVEL" != "debug" ]; then
        DELAY_SLEEP_SECONDS=0
    fi

    if [ $DELAY_SLEEP_SECONDS -ne 0 ]; then
        echolog "Warning: all exits with delay will include a delay of $DELAY_SLEEP_SECONDS seconds"
    fi
}

function logContainerStartup() {
    doubleLog "Starting Container ${BALENA_SERVICE_NAME}"
    doubleLog "Uptime:" `uptime`
    debuglog "OS_NAME is $OS_NAME"
}

# from https://serverfault.com/a/880885
# can be used an alternative to echo
# also can be piped into to handle multiple lines
# modified to use our date format
#
# note on the arguments to date:
# - the + starts the format
# - the format must be one argument, no spaces allowed, thus the "...+${LOG_FORMAT}"..."
# the entire echo argument is double quotes to preserve spaces
function echolog() {
    # if there are no arguments then read from STDIN
    # WARNING: this means you have to use `echolog ""` to get a blank line
    if [ $# -eq 0 ]; then 
        cat - | while read -r message
        do
            echo "$(date "+${LOG_FORMAT}") $message"
        done
    else
        echo "$(date "+${LOG_FORMAT}") $*"
    fi
}

# debug level version of echolog() 
function debuglog() {
    if [ -z ${LOG_LEVEL+x} ]; then
        return
    elif [ "$LOG_LEVEL" != "debug" ]; then
        return
    fi

    if [ $# -eq 0 ]; then 
        cat - | while read -r message
        do
            echo "$(date "+${LOG_FORMAT}") Debug: $message"
        done
    else
        echo "$(date "+${LOG_FORMAT}") Debug: $*"
    fi
}

# log to our regular logfile and a special startup log file
function doubleLog() {
    logmsg="$(date "+${LOG_FORMAT}") $*"
    echo "$logmsg"
    echo "$logmsg" >> ${LOG_FOLDER_AND_PREFIX}-start.log
}

function errorExitWithDelay() {
    if [ $# -ne 0 ]; then 
        echolog "Exiting: $*"
    fi
    if [ $DELAY_SLEEP_SECONDS -ne 0 ]; then
        echolog "Sleeping $DELAY_SLEEP_SECONDS seconds"
        sleep $DELAY_SLEEP_SECONDS
    fi
    exit
}

# https://forums.balena.io/t/how-to-debug-a-container-which-is-in-a-crash-loop/5638
function idleLoop() {
    if [ -n "$DEBUG" ]; then
        echolog "idleLoop() called."
        while : ; do
            echolog "Idling..."
            sleep 600
        done
    fi
}

function restartContainer() {
    echolog "Attempting to restart the container"
    if [ -z ${RESIN_SUPERVISOR_ADDRESS+x} ]; then
        echolog "Error: RESIN_SUPERVISOR_ADDRESS is not set"
        exit 1
    else
        echolog "Error: restarting the container"
        curl --connect-timeout 2 --max-time 2 \
            -X POST --header "Content-Type:application/json" \
            --data '{"appId": $RESIN_APP_ID}' \
            "$RESIN_SUPERVISOR_ADDRESS/v1/restart?apikey=$RESIN_SUPERVISOR_API_KEY"
            curl --silent --fail --show-error $SERVER_URL/under_construction/false > /dev/null
        exitStatus=$?
        echolog "curl --silent --fail ${SERVER_URL} exited with value ${exitStatus}"
        if [[ exitStatus -ne 0 ]]; then
            echolog "Error: unable to reach SUPERVISOR, curl error $exitStatus"
            # 6 == Could not resolve host. 
            #      The given remote host's address was not resolved. 
            #      The address of the given server could not be resolved. 
            #      Either the given host name is just wrong, or the DNS server is misbehaving 
            #      and does not know about this name when it should or perhaps even the system
            #      you run curl on is misconfigured so that it does not find/use the correct DNS server.
            # 22 == HTTP page not retrieved. 
            #       The requested url was not found or returned another error with the HTTP 
            #       error code being 400 or above.
            # 28 == timeout
        fi
    fi
    exit 1
}

initLogging $*
initVariables
logContainerStartup

