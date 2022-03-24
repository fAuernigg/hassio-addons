#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the ffserver service for running
# ==============================================================================
port="$(bashio::addon.port 8090)"
if [ ! -n "$port" ] ; then
	port="8090"
	echo "No port configured using port $port"
fi
echo "Using server port: $port"

#cp /usr/share/tempio/ffserver.gtpl /etc/ffserver.conf

# Generate configuration.
jq ".port = \"${port}\"" /data/options.json \
    | tempio \
      -template /usr/share/tempio/ffserver.gtpl \
      -out /etc/ffserver.conf


function addServerConf()
{
    echo -e "\n"\
    "<Feed $1.ffm>\n"\
    "    File    /run/$1.ffm\n"\
    "    FileMaxSize 10M\n"\
    "</Feed>\n\n"\
    "<Stream $1.mjpeg>\n"\
    "   Feed $1.ffm\n"\
    "   Format $2\n"\
    "   VideoFrameRate $3\n"\
    "   VideoIntraOnly\n"\
    "   VideoBufferSize 4096\n"\
    "   VideoBitRate 4096\n"\
    "   VideoSize $4\n"\
    "   VideoQMin 5\n"\
    "   VideoQMax 51\n"\
    "   NoAudio\n"\
    "   Strict -1\n"\
    "</Stream>\n"\
    >> /etc/ffserver.conf
}

function parseFFMpegConf()
{
	json=/data/options.json
	for row in $(jq -cr '.video_sources[]' $json); do
		name=$(echo $row | jq -r '.name')
		input=$(echo $row | jq -r '.input')
		fmt=$(echo $row | jq '.format')
		if [[ ! -n "$fmt" ]] ; then
			fmt="mjpeg"
		fi

		if [[ -n "$name" && -n "$input" ]] ; then
			addServerConf "$name" "$fmt" 3 "640x360"
		else
			echo "Error invalid config, misssing name or input: $row"
		fi
	done
}


parseFFMpegConf

echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo "X ffserver.conf                   X"
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
cat /etc/ffserver.conf
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

exit 0
