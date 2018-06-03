#!/bin/sh
# homie spec (incomplete)
$PUBBIN -h $mqtthost $auth -t $topic/\$homie -m "3.0.0" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$name -m "$devicename" -r
$PUBBIN -h $mqtthost $auth -t $topic/\$fw/version -m "$version" -r

# identify mFi device
export mFiType=`cat /etc/board.inc | grep board_name | sed -e 's/.*="\(.*\)";/\1/'`

$PUBBIN -h $mqtthost $auth -t $topic/\$fw/name -m "mFi MQTT" -r

IPADDR=`ifconfig ath0 | grep 'inet addr' | cut -d ':' -f 2 | awk '{ print $1 }'`
$PUBBIN -h $mqtthost $auth -t $topic/\$localip -m "$IPADDR" -r

NODES=`seq $PORTS | sed 's/\([0-9]\)/port\1/' |  tr '\n' , | sed 's/.$//'`
$PUBBIN -h $mqtthost $auth -t $topic/\$nodes -m "$NODES" -r

UPTIME=`awk '{print $1}' /proc/uptime`
$PUBBIN -h $mqtthost $auth -t $topic/\$stats/uptime -m "$UPTIME" -r

properties=relay

if [ $energy -eq 1 ]
then
    properties=$properties,energy
fi

if [ $power -eq 1 ]
then
    properties=$properties,power
fi

if [ $voltage -eq 1 ]
then
    properties=$properties,voltage
fi

if [ $lock -eq 1 ]
then
    properties=$properties,lock
fi

if [ $mFiTHS -eq 1 ]
then
    properties=$properties,mFiTHS
fi

if [ $mFiCS -eq 1 ]
then
    properties=$properties,mFiCS
fi

if [ $mFiMSW -eq 1 ]
then
    properties=$properties,mFiMSW
fi

if [ $mFiDS -eq 1 ]
then
    properties=$properties,mFiDS
fi


if [ $mFiType == "mPower" ]
then

# node infos
for i in $(seq $PORTS)
do
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$name -m "Port $i" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$type -m "power switch" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/\$properties -m "$properties" -r
    $PUBBIN -h $mqtthost $auth -t $topic/port$i/relay/\$settable -m "true" -r
done

if [ $lock -eq 1 ]
then
    for i in $(seq $PORTS)
    do
        $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock/\$settable -m "true" -r
    done

fi

fi
