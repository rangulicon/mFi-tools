#!/bin/sh

log() {
        logger -s -t "mqtt" "$*"
}

# read config file
source $BIN_PATH/client/mpower-pub.cfg
export PUBBIN=$BIN_PATH/mosquitto_pub

# identify mFi device
export mFiType=`cat /etc/board.inc | grep board_name | sed -e 's/.*="\(.*\)";/\1/'`

log "mFi Type: $mFiType."

# identify type of mpower
if [ $mFiType == "mPower" ] || [ $mFiType == "mPower Mini" ]
then
    export PORTS=`cat /etc/board.inc | grep feature_power | sed -e 's/.*\([0-9]\+\);/\1/'`
else
    export PORTS=3
fi

log "Found $((PORTS)) ports."
log "Publishing to $mqtthost with topic $topic"

REFRESHCOUNTER=$refresh
FASTUPDATE=0


export relay=$relay
export power=$power
export energy=$energy
export voltage=$voltage
export current=$current
export lock=$lock
export mFiTHS=$mFiTHS
export mFiCS=$mFiCS
export mFiMSW=$mFiMSW
export mFiDS=$mFiDS

$BIN_PATH/client/mqpub-static.sh
while sleep 1;
do
        # refresh logic: either we need fast updates, or we count down until it's time
        TMPFASTUPDATE=`cat $tmpfile`
        #echo "TMPFILE = " $TMPFASTUPDATE
    if [ -n "${TMPFASTUPDATE}" ]
        then
                FASTUPDATE=$TMPFASTUPDATE
                : > $tmpfile
        fi

        if [ $FASTUPDATE -ne 0 ]
        then
                # fast update required, we do updates every second until the requested number of fast updates is done
                FASTUPDATE=$((FASTUPDATE-1))
        else
                # normal updates, decrement refresh counter until it is time
                if [ $REFRESHCOUNTER -ne 0 ]
                then
                        # not yet, keep counting
                        REFRESHCOUNTER=$((REFRESHCOUNTER-1))
                        continue
                else
                        # time to update
                        REFRESHCOUNTER=$refresh
                fi
        fi

if [ $mFiType != "mPower" ] && [ $mFiType != "mPower Mini" ]
then


    if [ $mFiTHS -eq 1 ] && [ "$port1" == "mFiTHS" ] || [ "$port2" == "mFiTHS" ]
    then
        #temperature
        if [ "$port1" == "mFiTHS" ];then
            mFiTHS_val=`cat /proc/analog/value1`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/mFiTHS -m "$mFiTHS_val" -r
        elif [ "$port2" == "mFiTHS" ];then
            mFiTHS_val=`cat /proc/analog/value2`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/mFiTHS -m "$mFiTHS_val" -r
        fi
    fi

    if [ $mFiCS -eq 1 ] && [ "$port1" == "mFiCS" ] || [ "$port2" == "mFiCS" ]
    then
        #pinca corrente
        if [ "$port1" == "mFiCS" ];then
            mFiCS_val=`cat /proc/analog/rms1`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/mFiCS -m "$mFiCS_val" -r
        elif [ "$port2" == "mFiCS" ];then
            mFiCS_val=`cat /proc/analog/rms2`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/mFiCS -m "$mFiCS_val" -r
        fi
    fi


    if [ $mFiMSW -eq 1 ] && [ "$port1" == "mFiMSW" ] || [ "$port2" == "mFiMSW" ]
    then
        #sensor movimento
        if [ "$port1" == "mFiMSW" ];then
            mFiMSW_val=`cat /dev/input21`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/mFiMSW -m "$mFiMSW_val" -r
        elif [ "$port2" == "mFiMSW" ];then
            mFiMSW_val=`cat /dev/input22`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/mFiMSW -m "$mFiMSW_val" -r
        fi
    fi


    if [ $mFiDS -eq 1 ] && [ "$port1" == "mFiDS" ] || [ "$port2" == "mFiDS" ] || [ "$port3" == "mFiDS" ]
    then
        #sensor abertura porta
        if [ "$port1" == "mFiDS" ];then
              mFiDS_val=`cat /dev/input11`
              $PUBBIN -h $mqtthost $auth -t $topic/port1/mFiDS -m "$mFiDS_val" -r
        elif [ "$port2" == "mFiDS" ];then
              mFiDS_val=`cat /dev/input12`
              $PUBBIN -h $mqtthost $auth -t $topic/port2/mFiDS -m "$mFiDS_val" -r
        elif [ "$port3" == "mFiDS" ];then
              mFiDS_val=`cat /dev/input13`
              $PUBBIN -h $mqtthost $auth -t $topic/port3/mFiDS -m "$mFiDS_val" -r
        fi
    fi

fi

if [ $mFiType == "mPower" ] || [ $mFiType == "mPower Mini" ]
then


    if [ $relay -eq 1 ]
    then
        # relay state
        for i in $(seq $PORTS)
        do
            relay_val=`cat /proc/power/relay$((i))`
            if [ $relay_val -ne 1 ]
            then
              relay_val=0
            fi
            $PUBBIN -h $mqtthost $auth -t $topic/port$i/relay -m "$relay_val" -r
        done
    fi

    if [ $power -eq 1 ]
    then
        # power
        for i in $(seq $PORTS)
        do
            power_val=`cat /proc/power/active_pwr$((i))`
            power_val=`printf "%.1f" $power_val`
            $PUBBIN -h $mqtthost $auth -t $topic/port$i/power -m "$power_val" -r
        done
    fi

    if [ $energy -eq 1 ]
    then
        # energy consumption
        for i in $(seq $PORTS)
        do
            energy_val=`cat /proc/power/cf_count$((i))`
            energy_val=$(awk -vn1="$energy_val" -vn2="0.3125" 'BEGIN{print n1*n2}')
            energy_val=`printf "%.0f" $energy_val`
            $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy -m "$energy_val" -r
        done
    fi

    if [ $voltage -eq 1 ]
    then
        # voltage
        for i in $(seq $PORTS)
        do
            voltage_val=`cat /proc/power/v_rms$((i))`
            voltage_val=`printf "%.1f" $voltage_val`
            $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage -m "$voltage_val" -r
        done
    fi

    if [ $current -eq 1 ]
    then
        # current
        for i in $(seq $PORTS)
        do
            current_val=`cat /proc/power/i_rms$((i))`
            current_val=`printf "%.1f" $current_val`
            $PUBBIN -h $mqtthost $auth -t $topic/port$i/current -m "$current_val" -r
        done
    fi

    if [ $lock -eq 1 ]
    then
        # lock
        for i in $(seq $PORTS)
        do
            port_val=`cat /proc/power/lock$((i))`
            $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock -m "$port_val" -r
        done
    fi

fi
done

