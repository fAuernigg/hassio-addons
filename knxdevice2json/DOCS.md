# Home Assistant Add-on: KnxDevice 2 Json

## Installation

Follow these steps to get the add-on installed on your system:

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store**.
2. Find the "knxdevice2json" add-on and click it.
3. Click on the "INSTALL" button.

## How to use

Upload the knxproj file using a samba or sftp to e.g. /share/ETSlatest.knxproj.
Select a target device and a knx device and trigger the device config 2 json conversion.
Output will be sent to the topic "[DEVICENAME_SPECIFIED]/knxconfig"

## How to use

Configure 'topic' with the trigger mqtt topic used to trigger the conversion.
The message contains the "[DEVICENAME] [KNXDEVICENAME]".
Devicename is the mqtt topic prefix, which receives the json output for the knx device name specied.

## Configuration

This is an example of a configuration. **_DO NOT USE_** without making the necessary changes.
Fields between `<` and `>` indicate values that are omitted and need to be changed.

```yaml
mqtt:
  - topic: "knxdevice2json/sendconfig2device"
  - knxprojfile: "/share/knxproj/ETSlatest.knxproj"
```

### Option `topic`

Mqtt topic triggering conversion and containing "[DEVICENAME] [KNXDEVICENAME]"

### Option `knxprojfile`

Upload file path accessible by this addon.
This addon can access /share or /media.

## Support

### Common problems
