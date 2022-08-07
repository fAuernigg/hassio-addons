#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the knxdevice2json service for running
# ==============================================================================
port="$(bashio::addon.port 7273)"
if [ ! -n "$port" ] ; then
	port="7273"
	echo "No port configured using port $port"
fi
echo "Using server port: $port"

# Generate configuration.
#jq ".port = \"${port}\"" /data/options.json \
#    | tempio \
#      -template /usr/share/tempio/knxdevice2json.gtpl \
#      -out /etc/knxdevice2json.conf

exit 0
