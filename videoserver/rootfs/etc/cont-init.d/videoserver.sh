#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the ffserver service for running
# ==============================================================================
declare port
export HOSTNAME

# Read hostname from API or setting default "hassio"
HOSTNAME=$(bashio::info.hostname)
if bashio::var.is_empty "${HOSTNAME}"; then
    bashio::log.warning "Can't read hostname, using default."
    name="hassio"
    HOSTNAME="hassio"
fi

#cp /usr/share/tempio/ffserver.gtpl /etc/ffserver.conf

# Generate configuration.
jq ".port = \"${port}\"" /data/options.json \
    | tempio \
      -template /usr/share/tempio/ffserver.gtpl \
      -out /etc/ffserver.conf



function startStream()
{
	while [ 1 ] ; do
		sleep 1s
		echo "start ffmpeg $1 from input: $2"
		#pid=$(ps aux | grep -v grep | grep ffmpeg | grep "$1" | grep "$2")
		#if [ -n "$pid"  ] ; then
		#	kill -9 $(echo $pid | cut -d ' ' -f1)
		#fi
		ffmpeg -i "$2" -strict -2 "http://localhost:8090/$1.ffm"
		echo "ffmpeg exit done errorcode: $?"
	done
}

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
    "   VideoSize $4\n"\
    "   VideoQMin 5\n"\
    "   VideoQMax 51\n"\
    "   NoAudio\n"\
    "   Strict -1\n"\
    "</Stream>\n"\
    >> ffserver.conf
}

function parseFFMpegConf()
{
	json=options.json
	for row in $(jq -cr '.video_sources[]' $json); do
		name=$(echo $row | jq -r '.name')
		input=$(echo $row | jq -r '.input')
        fmt=$(echo $row | jq '.format')

		if [[ -n "$name" && -n "$input" ]] ; then
            addServerConf "$name" "$fmt" 3 "640x360"
			startStream "$name" "$input" &
		else
			echo "Error invalid config, misssing name or input: $row"
		fi
	done
}

parseFFMpegConf

exit 0
