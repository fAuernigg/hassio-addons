# example to use ffmpeg, ffserver
#   netbios name = {{ env "HOSTNAME" }}
#   interfaces = {{ .interface }}

HTTPPort            8090
HTTPBindAddress     0.0.0.0
#HTTPBindAddress     {{ .interface }}
MaxHTTPConnections 200
MaxClients      100
MaxBandWidth    500000
CustomLog       /run/ffserver.log

<Feed n.ffm>
File            /run/n.ffm
FileMaxSize     10M
</Feed>


<Stream n.mjpeg>
Feed n.ffm
Format mpjpeg
VideoFrameRate 3
VideoIntraOnly
VideoBufferSize 4096
VideoSize 640x360
VideoQMin 5
VideoQMax 51
NoAudio
Strict -1
</Stream>
