#!/bin/bash

path=$(pwd)
cd $(dirname $0)
spath=$(pwd)
cd $path

f=
if [[ $# -ne 2 ]] ; then
	echo "Error invalid params: [My.knxproj] [MKA-MyDevice]"
	exit 13
fi

f=$1

rm -Rf /share/knxtmp/ ; mkdir -p /share/knxtmp/

folder=/share/knxtmp/$(echo $f | tr "." "-" | tr "/" "_")
unzip -qo $f -d $folder

#filterprefix for my own knx devices
filterPrefix="MKA-"
deviceName=$filterPrefix"Hallway"

if [[ $# -ge 2 ]] ; then
	deviceName=$2
fi

deviceStart=""
deviceStop=""
data=""

p=P-0128

i=100
while [[ $i -le 999 ]] ; do
	p="P-0$i"
	if [[ -f "$folder/$p/0.xml" ]] ; then
		break
	fi
	i=$((i+1))
done

#replace/remove "xmlns= " attrib for performance problems
xml="$folder/$p/0.xml"

# remove online lookup causing xmlns attribute. (link does not exist)
sed -i 's/ xmlns=/ NIXxmlns=/' $xml


function printGroups() {
	xml=$1
	deviceXml=$2
	i=$3
	groupName=$4

	n=$5
	# processing send groups
	groupCount=$(echo $deviceXml | xmllint --xpath 'count(/DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/Connectors/'$groupName')' -)
	for (( j=1; j<= $groupCount ; j++ )); do
		group=$(echo $deviceXml | xmllint --xpath 'string(/DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/Connectors/'$groupName'['$j']/@GroupAddressRefId)' -)
		if [[ -n $group ]] ; then
			groupDec=$(xmllint --xpath 'string(//KNX/Project/Installations/Installation/GroupAddresses/GroupRanges/GroupRange/GroupRange/GroupAddress[@Id="'$group'"]/@Address)' $xml)
			groupName=$(xmllint --xpath 'string(//KNX/Project/Installations/Installation/GroupAddresses/GroupRanges/GroupRange/GroupRange/GroupAddress[@Id="'$group'"]/@Name)' $xml)
			if [[ $n -ge 1 ]] ; then
				echo ","
			fi
			n=$((n+1))
			echo "{\"ComRefId\": \"$id\", \"Group\":$groupDec,\"Name\":\"$groupName\"}"
		fi
	done
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

echo "{\"ComObjects\": ["

n=0
for (( d=1; d<= $deviceCount ; d++ )); do

	deviceXml=$(xmllint  --xpath '//KNX/Project/Installations/Installation/Topology/Area/Line/DeviceInstance[contains(@Name, "'$deviceName'")]['$d']' $xml)

	if [[ "X$deviceXml" == "X" ]] ; then
		continue
	fi

	count=$(echo -e "$deviceXml" | xmllint --xpath 'count(//DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef)' -)
	for (( i=1; i<= $count ; i++ )); do
		id=$(echo $deviceXml | xmllint --xpath 'string(//DeviceInstance/ComObjectInstanceRefs/ComObjectInstanceRef['$i']/@RefId)' -)

		printGroups "$xml" "$deviceXml" "$i" "Send" $n
		n=$?

		printGroups "$xml" "$deviceXml" "$i" "Receive" $n
		n=$?
	done

	printDeviceParams "$deviceXml" $n
	n=$?
done

echo "] }"
exit 0


i=0



# legacy code based on sed.
# removed redundant json pairs group, type, channel

# find all references group addresses and replace address by slash separated rep.
#echo $deviceXml | while read -r line ; do
cat "$folder/$p/0.xml" | while read -r line ; do
	if [[ "X$deviceStart" == "X" ]] ; then
		deviceStart=$(echo $line | sed -e  "s/^.*\\<DeviceInstance Id=\"\(.\+\)\" Address=\"[0-9]\+\" Name=\"\($deviceName.*\)\".*$/\2=\1/g;tx;d;:x")
		#deviceStart=$(echo "$line" | grep -E '\<DeviceInstance Id=\".*\" Address=\".*\" Name=\"$deviceName')
		continue
	elif [[ "X$deviceStop" == "X" ]] ; then
		deviceStop=$(echo $line | grep -E "</DeviceInstance>")
	fi

	#if [[ "X$deviceStart" != "X" ]] ; then
	#	echo "device found: $line"
	#fi

	if [[ "X$deviceStart" == "X" && "X$deviceStop" == "X" ]] ; then
		continue
	elif [[ "X$deviceStart" != "X" && "X$deviceStop" != "X" ]] ; then
		deviceStart=""
		deviceStop=""
		exit 0
	fi

	groupId=$(echo $line | sed -e "s/.*GroupAddressRefId=\"\([0-9A-Za-z\_\-]\+\)\".*/\1/g;tx;d;:x")
	if [[ "X$groupId" == "X" ]] ; then
		d=$(echo $line | sed -e "s/.*<ComObjectInstanceRef RefId=\"\([0-9A-Za-z\_\-]\+\)\".\+/\1/g;tx;d;:x")
		if [[ -n "$d" ]] ; then
			data=$d
		fi
		continue
	fi
	id=$data

	groupDec=$(cat "$folder/$p/0.xml" | sed -e "s/.*<GroupAddress Id=\"$groupId\" Address=\"\([0-9]\+\)\".*/\1/g;tx;d;:x")
	groupName=$(cat "$folder/$p/0.xml" | sed -e "s/.*<GroupAddress Id=\"$groupId\" Address=\"\([0-9]\+\)\" Name=\"\([a-zA-Z0-9 \-\+\._]\+\)\".*/\2/g;tx;d;:x")
	if [[ "X$groupDec" == "X" ]] ; then
		continue
	fi
	group=$($spath/knxAddrToGroup.sh "$groupDec")

	funcType=$(rgrep "$id" $folder/* | sed -e "s/.*<ComObjectRef Id=\"$id\"\s.*FunctionText=\"\([^\"]\+\)\"\s\+ObjectSize=\"\([^\"]\+\)\"\s\+[a-zA-Z]\+.*$/\1,\2/g;tx;d;:x")
	channel=$(echo $id | sed -e "s/.\+FCCB_O-\([0-9]\+\).*/\1/g;tx;d;:x")
	channel=$((channel/5))


	if [[ $i -ge 1 ]] ; then
		echo ","
	fi
	i=$((i+1))

	echo "{\"channel\":$channel,\"type\":\"$funcType\",\"group\":\"$group\",\"groupD\":$groupDec,\"DPT\":\"$data\",\"name\":\"$groupName\"}"
done

echo "] }"
