#!/bin/sh

# Script to install the log_monitor program in the crontab.

function main()
{
    # Make sure the user is running as root (otherwise this won't work)
    if [[ $EUID -ne 0 ]]; then
        echo "Log Monitor requires root access due to iptables!" 1>&2
        exit 1
    fi
    
    # Get user input
    #TODO Should check user input values
    echo "Number of failed attempts before block: "
    read blockAttempts

    echo "Duration (minutes) between first attempt and attempt that causes a block: "
    read monitorDuration

    echo "Duration (hours) to block IP for:"
    read blockDuration
    
    echo "How often (minutes) to check the log file: "
    read minuteCheck
    
    # Put the job in the crontab
    (crontab -l; echo "$minuteCheck * * * * $PWD/log_monitor.sh $blockAttempts $monitorDuration $blockDuration") | crontab -
}

main
