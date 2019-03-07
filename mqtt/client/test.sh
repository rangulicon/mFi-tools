#!/bin/sh

log() {
        logger -s -t "mqtt" "$*"
}

# identify mFi device
export mFiType=`mPower Mini`

log "mFi Type: $mFiType."

# identify type of mpower
if [ "$mFiType" == "mPower" ] || [ "$mFiType" == "mPower Mini" ]
then
    export PORTS=1
else
    export PORTS=3
fi

log "Found $((PORTS)) ports."