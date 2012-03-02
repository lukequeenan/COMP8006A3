#!/bin/sh

# Blocks an IP using iptables and schedules a cronjob for removing the ip after
# the user defined duration.
function blockIP()
{
    /sbin/iptables -A INPUT -s $1 -j DROP
    
    (crontab -l; echo "* $2 * * * $PWD/unblock_ip.sh $1") | crontab -
}


# Reads last 1000 lines from /var/log/secure
# Check for "Failed password" in SSHD
# Checks the IP and increments it
# Loops through the IPs and checks if the same IP
# Appears more times than the user provide threshold.
# It then reads the IP and check if it already exists 
# in the iptables. If it does, it is ignored, otherwise
# it gets added with a DROP.
function monitor()
{
    tail -1000 /var/log/secure | awk '/sshd/ && /Failed password for/ { if (/invalid user/) evilIP[$13]++; else evilIP[$11]++; }
    END { for (host in evilIP) if (evilIP[host] > $1) print host; }' |

    while read ip
    do
	    # 
	    /sbin/iptables -L -n | grep $ip > /dev/null
	    if [ $? -eq 0 ] ; then
		    # echo "already denied ip: [$ip]" ;
		    true
	    else
		    # Block IP
		    blockIP $ip $3
	    fi
    done
}

# Ensures that the job is running as root, then calls the monitor function
function main()
{
    # Make sure the user is running as root (otherwise this won't work)
    if [[ $EUID -ne 0 ]]; then
        exit 1
    fi

    # Call monitor
    # $1 = blockAttempts $2 = monitorDuration $3 = blockDuration
    monitor $1 $2 $3
}

main $1 $2 $3
