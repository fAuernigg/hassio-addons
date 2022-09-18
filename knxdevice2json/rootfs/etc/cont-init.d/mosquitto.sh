#!/command/with-contenv bashio
declare host
declare password
declare port
declare username

if bashio::services.available "mqtt"; then
  host=$(bashio::services "mqtt" "host")
  password=$(bashio::services "mqtt" "password")
  port=$(bashio::services "mqtt" "port")
  username=$(bashio::services "mqtt" "username")
  mkdir -p /root/.config
  {
    echo "-h ${host}"
    echo "--pw ${password}"
    echo "--port ${port}"
    echo "--username ${username}"
  } > /root/.config/mosquitto_sub
  rm /root/.config/mosquitto_rr /root/.config/mosquitto_pub -f
  ln -s /root/.config/mosquitto_sub /root/.config/mosquitto_pub
  ln -s /root/.config/mosquitto_sub /root/.config/mosquitto_rr
fi
