#!/bin/bash

path=$(pwd)
cd $(dirname $0)
spath=$(pwd)
cd $path
segment=

tmppath="/share/knxtmp/"
if [[ ! -d "$tmppath" ]] ; then
	tmppath="/tmp/knxtmp"
	#echo "Dev environment: Using knx tmp directory: $tmppath"
fi

f=
if [[ $# -lt 2 ]] ; then
	echo "Error invalid params: [My.knxproj] [MKA-MyDevice]"
	exit 13
fi

f=$1

folder=$tmppath$(echo $f | tr "." "-" | tr "/" "_")

rm -Rf $tmppath ; mkdir -p $tmppath
unzip -qo $f -d $folder

#filterprefix for my own knx devices
filterPrefix="MKA-"
deviceName=$filterPrefix"Hallway"

if [[ $# -ge 2 ]] ; then
	deviceName="$2"
fi

deviceStart=""
deviceStop=""
data=""

p=P-0128
xmlfilename=0

i=100
while [[ $i -le 999 ]] ; do
        p="P-0"$(echo "ibase=10;obase=16;$i" |bc)
        if [[ -f "$folder/$p/$xmlfilename.xml" ]] ; then
                break
        fi
        i=$((i+1))
done


#replace/remove "xmlns= " attrib for performance problems
xml="$folder/$p/$xmlfilename.xml"

# remove online lookup causing xmlns attribute. (link does not exist)
sed -i 's/ xmlns=/ NIXxmlns=/' $xml

function printGroup()
{
	xml=$1
	id=$2
	group=$3
	n=$4

	if [[ ! -n $group ]] ; then
		return
	fi

	groupDec=$(xmllint --xpath 'string(//KNX/Project/Installations/Installation/GroupAddresses/GroupRanges/GroupRange/GroupRange/GroupAddress[@Id="'$group'"]/@Address)' $xml)
	groupName=$(xmllint --xpath 'string(//KNX/Project/Installations/Installation/GroupAddresses/GroupRanges/GroupRange/GroupRange/GroupAddress[@Id="'$group'"]/@Name)' $xml)


	if [[ ! -n $groupName && -n $groupDec ]] ; then
		return
	fi

	if [[ $n -ge 1 ]] ; then
		echo ","
	fi
	n=$((n+1))

	echo "{\"ComRefId\": \"$id\", \"Group\":$groupDec,\"Name\":\"$groupName\"}"
}

function printGroups() {
	xml=$1
	deviceXml=$2
	i=$3
	groupName=$4
	n=$5
	id=$6
	p=$7
	xmlfilename=$8

	# processing send groups
	groupCount=$(echo $deviceXml | xmllint --xpath 'count(/DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/Connectors/'$groupName')' -)
	if [[ $groupCount -ne 0 ]] ; then
		for (( j=1; j<= $groupCount ; j++ )); do
			group=$(echo $deviceXml | xmllint --xpath 'string(/DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/Connectors/'$groupName'['$j']/@GroupAddressRefId)' -)
			printGroup $xml $id $group $n
		done
	#ETS6 xml, and only once
	elif [[ "$groupName" == "Send" ]] ; then
		groupCount=$(echo $deviceXml | xmllint --xpath 'count(/DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/@Links)' -)
		for (( j=1; j<= $groupCount ; j++ )); do
			group=$(echo $deviceXml | xmllint --xpath 'string(/DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/@Links['$j'])' -)
			printGroup $xml $id "$p-${xmlfilename}_$group" $n
		done
	fi

	return $n
}

function printDeviceParams() {
	deviceXml=$1
	n=$2

	count=$(echo -e "$deviceXml" | xmllint --xpath 'count(//DeviceInstance/ParameterInstanceRefs/ParameterInstanceRef)' -)

	for (( i=1; i<= $count ; i++ )); do
		id=$(echo $deviceXml | xmllint --xpath 'string(//DeviceInstance/ParameterInstanceRefs/ParameterInstanceRef['$i']/@RefId)' -)
		val=$(echo $deviceXml | xmllint --xpath 'string(//DeviceInstance/ParameterInstanceRefs/ParameterInstanceRef['$i']/@Value)' -)
		if [[ -n "$id" && -n "$val" ]] ; then
			if [[ $n -ge 1 ]] ; then
				echo ","
			fi
			n=$((n+1))
			echo "{\"ParamRefId\": \"$id\", \"Value\": \"$val\"}"
		fi
	done
	return $n
}

deviceCount=$(xmllint --xpath 'count(//KNX/Project/Installations/Installation/Topology/Area/Line/DeviceInstance[contains(@Name, "'$deviceName'")])' $xml)
if [[ $deviceCount -eq 0 ]] ; then
	segment="Segment/"
fi

deviceCount=$(xmllint --xpath 'count(//KNX/Project/Installations/Installation/Topology/Area/Line/'$segment'DeviceInstance[contains(@Name, "'$deviceName'")])' $xml)

echo "{\"ComObjects\": ["

n=0
for (( d=1; d<= $deviceCount ; d++ )); do

	deviceXml=$(xmllint  --xpath '//KNX/Project/Installations/Installation/Topology/Area/Line/'$segment'DeviceInstance[contains(@Name, "'$deviceName'")]['$d']' $xml)

	if [[ "X$deviceXml" == "X" ]] ; then
		continue
	fi

	count=$(echo -e "$deviceXml" | xmllint --xpath 'count(//DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef)' -)
	hwrefid=$(echo -e "$deviceXml" | xmllint --xpath 'string(//DeviceInstance/@Hardware2ProgramRefId)' -)

	for (( i=1; i<= $count ; i++ )); do
		id=$(echo $deviceXml | xmllint --xpath 'string(//DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/@RefId)' -)
		if [[ "$id" != "M-*" ]] ; then
			id="${hwrefid}_${id}"
		fi

		printGroups "$xml" "$deviceXml" "$i" "Send" $n $id $p $xmlfilename
		n=$?

		printGroups "$xml" "$deviceXml" "$i" "Receive" $n $id $p $xmlfilename
		n=$?
	done

	printDeviceParams "$deviceXml" $n
	n=$?
done

echo "] }"
exit 0
