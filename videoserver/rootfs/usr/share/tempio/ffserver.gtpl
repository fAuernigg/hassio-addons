HTTPPort            {{ .port }}
HTTPBindAddress     0.0.0.0
MaxHTTPConnections 200
MaxClients      100
MaxBandWidth    500000
CustomLog       /run/ffserver.log
