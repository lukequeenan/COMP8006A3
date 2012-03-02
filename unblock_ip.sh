#!/bin/sh

# Script to un-block an IP and remove the calling cronjob from the crontab

function removeIP()
{
    # Remove the IP from the iptable
    /sbin/iptables -D INPUT -s $1 -j DROP
    
    # Remove this cronjob from the crontab
    crontab -l >$CRON_TEMP
    awk '$0!~/$1/ { print $0 }' $CRON_TEMP >$CRON_NEW
    crontab $CRON_NEW
}

function main()
{
    # Make sure the user is running as root (otherwise this won't work)
    if [[ $EUID -ne 0 ]]; then
        echo "Log Monitor requires root access due to iptables!" 1>&2
        exit 1
    fi
    
    removeIP $1
}

main $1