#!/bin/sh

# Make sure the user is running as root (otherwise this won't work)
if [[ $EUID -ne 0 ]]; then
    echo "Log Monitor requires root access to run!" 1>&2
    exit 1
fi

# Scan /var/log/secure for ssh attempts
# Use iptables to block evil IPs 

echo "Please enter the number of consecutive failed login attempts to block on: "
read blockAttempts


# Reads last 1000 lines from /var/log/secure
# Check for "Failed password" in SSSH
# Checks the IP and increments it
# Loops through the IPs and checks if the same IP
# Appears more times than the user provide threshold.
# It then reads the IP and check if it already exists 
# in the iptables. If it does, it is ignored, otherwise
# it gets added with a DROP.
tail -1000 /var/log/secure | awk '/sshd/ && /Failed password for/ { if (/invalid user/) evilIP[$13]++; else evilIP[$11]++; }
END { for (host in evilIP) if (evilIP[host] > blockAttempts) print host; }' |
while read ip
do
	# 
	/sbin/iptables -L -n | grep $ip > /dev/null
	if [ $? -eq 0 ] ; then
		# echo "already denied ip: [$ip]" ;
		true
	else
		# Block IP
		/sbin/iptables -A INPUT -s $ip -j DROP
	fi
done  
