portmap=
if [[ -n "$2" ]] ; then
        portmap="-p $2:$2"
fi

docker create $portmap -it test_$1 /bin/ash
