#!/usr/bin/with-contenv bashio
# ==============================================================================
# Prepare the ffserver service for running
# ==============================================================================
declare interface
export HOSTNAME

# Read hostname from API or setting default "hassio"
HOSTNAME=$(bashio::info.hostname)
if bashio::var.is_empty "${HOSTNAME}"; then
    bashio::log.warning "Can't read hostname, using default."
    name="hassio"
    HOSTNAME="hassio"
fi

# Get default interface
#interface=$(bashio::network.name)

#bashio::log.info "Using hostname=${HOSTNAME} interface=${interface}"
interface=enp0s31f6

cp /usr/share/tempio/ffserver.gtpl /etc/ffserver.conf

# Generate Samba configuration.
jq ".interface = \"${interface}\"" /data/options.json \
    | tempio \
      -template /usr/share/tempio/ffserver.gtpl \
      -out /etc/ffserver.conf
exit 0
