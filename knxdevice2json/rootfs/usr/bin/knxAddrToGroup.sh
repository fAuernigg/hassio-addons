#!/bin/bash

if [[ $# -le 0 ]] ; then
	echo "Error specify value of 'Address' attribute from knx project file"
	exit 1
fi

adr=$1
v1=$((adr/256/8))
v2=$(( (adr/256)%8 ))
v3=$((adr%256))

echo "$v1/$v2/$v3"

