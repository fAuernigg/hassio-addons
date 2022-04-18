#!/bin/bash

cd $(dirname $0)
spath=$(pwd)

if [[ $# -eq 0 ]] ; then
        echo "Error params: [ETS device name] [Device name or id] [ETS.knxproj]"
        echo "e.g: ./sendKnxProjConfig.sh \"MKA-OgToilett\" \"mka_24:0A:C4:03:A3:0C\"" "Mw13_11june_2019.knxproj\""
        exit 22
fi

echo "sendknxProjConfig.sh: Params: $@"

devicename=$1

id=$devicename
if [ $# -ge 2 ] ; then
	id=$2
fi

knxproj=/share/knxproj/ETSlatest.knxproj
if [ $# -ge 3 ] ; then
	knxproj=$3
fi

if [[ ! -e "$knxproj"  ]] ; then
	echo "knxproj file: $knxproj not found"
	exit 23
fi

config=$($spath/knxFindDeviceObjects.sh $knxproj $devicename | tr "\n" " ")

echo -e "Sending config $devicename to device: $id: \n"

mosquitto_pub -t "$id/knxconfig"  -i knxproj2json -m "$config" 2>&1

echo -e "$config" | jq -C "."
