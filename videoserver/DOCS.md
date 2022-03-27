# Home Assistant Add-on: Videoserver

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "Videpserver" add-on and click it.
3. Click on the "INSTALL" button.

## How to use

1. In the configuration section, set a input video url and the output stream name.
2. Save the configuration.
3. Start the add-on.
4. Check the add-on log output to see the result.

## Connection

Test your video in your browser using `http://<IP_ADDRESS>:8090/<OUTPUT_STREAM_NAME>.mjpeg`.

## Configuration

This is an example of a configuration. **_DO NOT USE_** without making the necessary changes.
Fields between `<` and `>` indicate values that are omitted and need to be changed.

```yaml
video_sources:
- input: http://192.168.10.155/cgi-bin/hi3510/snap.cgi?&-getstream&-chn=2
  name: n
  format: mpjpeg
```

### Option `video_server` (optional)

Add video input stream urls here.

## Support

### Common problems
