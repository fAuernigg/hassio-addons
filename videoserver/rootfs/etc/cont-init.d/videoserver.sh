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

function addFFMpegService()
{
	mkdir -p "/etc/services.d/ffmpeg_$1/"

	echo -e "#!/usr/bin/with-contenv bashio\n"\
		"\n"\
		"echo \"start ffmpeg $name from input: $input\"\n"\
		"ffmpeg -i \"$input\" -c copy -strict -2 \"http://localhost:8090/$name.ffm\"\n"\
		"echo \"ffmpeg $name exited, errorcode: $?\"\n"\
		 >> "/etc/services.d/ffmpeg_$1/run"

	echo -e "#!/usr/bin/execlineb -S1\n"\
		"if { s6-test ${1} -ne 0 }\n"\
		"if { s6-test ${1} -ne 256 }\n\n"\
		"s6-svscanctl -t /var/run/s6/services\n"\
		>> "/etc/services.d/ffmpeg_$1/finish"

	chmod a+x /etc/services.d/ffmpeg_$1/*
}


function parseFFMpegConf()
{
	json=/data/options.json
	for row in $(jq -cr '.video_sources[]' $json); do
		name=$(echo $row | jq -r '.name')
		input=$(echo $row | jq -r '.input')
		fmt=$(echo $row | jq '.format')
		if [[ ! -n "$fmt" ]] ; then
			fmt="mpjpeg"
		fi
		echo -e "Found Video config: \n\tName: $name\n\tstream: $input\n\tFormat: $fmt"

		if [[ -n "$name" && -n "$input" ]] ; then
			addServerConf "$name" "$fmt" 3 "640x360"
			addFFMpegService "$name" "$input"
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
