#!/bin/sh

DCSERVER="server poc-eus-dc1.iglooaz.local"
ZONE="zone iglooaz.local"
ADDR=`/sbin/ifconfig eth0 | grep 'inet ' | awk '{print $2}' | sed -e s/.*://`
HOST=`hostname -f`
DOMAIN=".iglooaz.local."

echo "Updating DNS"
echo "$DCSERVER" > /etc/dhcp/dnsupdate.txt
echo "$ZONE" >> /etc/dhcp/dnsupdate.txt
echo "update delete $HOST$DOMAIN A" >> /etc/dhcp/dnsupdate.txt
echo "update add $HOST$DOMAIN 86400 A $ADDR" >> /etc/dhcp/dnsupdate.txt
echo "show" >> /etc/dhcp/dnsupdate.txt
echo "send" >> /etc/dhcp/dnsupdate.txt
nsupdate /etc/dhcp/dnsupdate.txt