#!/bin/sh
# Enable/Disable LLDP on vSwitch ports on VMWare ESXi
# Tested with ESXi 6.0.0 3620759
# Tested with ESXi 6.7
# Doesn't need vCenter, only SSH access to the ESXi machine
# (c) Pekka "raspi" Jarvinen 2016 http://raspi.fi/
# (c) Paul Iercosan 2022 https://paulierco.ro/

SWITCH=$1
OPERATION=$2

if [ "$SWITCH" = "" ] || [ "$OPERATION" = "" ]; then
        echo "Enable/disable LLDP on vSwitch"
        echo ""
        echo "USAGE:"
        echo "$0 <vSwitch> <operation>"
        echo "Examples: "
        echo "Enable LLDP: $0 vSwitch0 1"
        echo "Disable LLDP: $0 vSwitch0 0"

        exit 1
fi

case "$OPERATION" in
                0) ;;
                1) ;;
                *) echo "Invalid operation: $OPERATION"; exit 1 ;;
esac


for PORT in `vsish -e ls /net/portsets/$SWITCH/ports | sed 's/\/$//'`
do
        DATA=`vsish -e get /net/portsets/$SWITCH/ports/$PORT/status`
        echo "$DATA" | grep -q "Physical NIC"
        if [ $? = 0 ];then
                echo "Trying to change LLDP state to $OPERATION.."
                vsish -e set /net/portsets/$SWITCH/ports/$PORT/lldp/enable $OPERATION &> /dev/null
                LLDPSTATE=`vsish -e get /net/portsets/$SWITCH/ports/$PORT/lldp/enable`
                Remote_PORTID=`vsish -e get /net/portsets/$SWITCH/ports/$PORT/lldp/rcache | grep -A5 '^type: 2' | grep -A3 '^data:' | grep '^0x'`
                Remote_Port_Desc=`vsish -e get /net/portsets/$SWITCH/ports/$PORT/lldp/rcache | grep -A5 '^type: 4' | grep -A3 '^data:' | grep '^0x'`
                Remote_Hostname=`vsish -e get /net/portsets/$SWITCH/ports/$PORT/lldp/rcache | grep -A5 '^type: 5' | grep -A3 '^data:' | grep '^0x'`
                Remote_Description=`vsish -e get /net/portsets/$SWITCH/ports/$PORT/lldp/rcache | grep -A5 '^type: 6' | grep -A3 '^data:' | grep '^0x'`
                echo "Trying to map LLDP from ESXi to remote data.."
                echo "ESXi Kerner Port: $PORT"
                Local_Port_ID=$(echo "$DATA" | grep -i "port index:" | sed 's/port index:/Local Port ID -> /g')
                echo "$Local_Port_ID"
                ONE=$(echo "$DATA" | grep -i "clientName:" | sed 's/clientName:/Local Port -> /g')
                TWO=$(printf `echo $Remote_PORTID | sed 's/ 0x/\\\\x/g;s/^0x/\\\\x/;s/,$//'`\\n)
                TREE=$(printf `echo $Remote_Hostname | sed 's/ 0x/\\\\x/g;s/^0x/\\\\x/;s/,$//'`\\n)
                FOUR=$(printf `echo $Remote_Description | sed 's/ 0x/\\\\x/g;s/^0x/\\\\x/;s/,$//'`\\n)
                FIVE=$(printf `echo $Remote_Port_Desc | sed 's/ 0x/\\\\x/g;s/^0x/\\\\x/;s/,$//'`\\n)
                echo $ONE
                echo "Remote Port -> $TWO"
                echo "Remote Port Descr -> $FIVE"
                echo "Remote Hostname -> $TREE"
                echo "Remote Description -> $FOUR"
                echo "$DATA" | grep -i "clientType:"
                echo "$DATA" | grep -i "portCfg:"
                if [ "$LLDPSTATE" = "$OPERATION" ]; then
                        echo "  LLDP state successfully changed"
                else
                        echo "  ERROR: changing LLDP state failed"
                fi

        echo "------------------------------"
        echo ""
        fi
done