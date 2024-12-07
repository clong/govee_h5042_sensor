#!/bin/bash

cd /opt/govee_h5042_sensor/temps && python3 -m http.server 9000 &

## THESE VARIABLES MUST BE FILLED OUT
## These are the names of your devices in the Govee App. The order doesn't matter.
DEVICE_1_NAME=""
DEVICE_2_NAME=""

while true; do

  TIMESTAMP=$(printf "%.6f\n" "$(date +%s.%N)")

## The curl request below should be retrieved using Proxyman on iOS

  curl \
  -X POST \
  -H 'Host: app2.govee.com' \
  -H 'Authorization: Bearer [REDACTED]' \
  -H 'Accept: */*' \
  -H 'timestamp: '"$TIMESTAMP" \
  -H 'envId: 0' \
  -H 'clientId: [REDACTED]' \
  -H 'appVersion: 6.4.11' \
  -H 'Accept-Language: en' \
  -H 'sysVersion: 18.1.1' \
  -H 'clientType: 1' \
  -H 'User-Agent: GoveeHome/6.4.11 (com.ihoment.GoVeeSensor; build:2; iOS 18.1.1) Alamofire/5.6.4' \
  -H 'timezone: America/Los_Angeles' \
  -H 'Connection: keep-alive' \
  -H 'country: US' \
  -H 'iotVersion: 0' \
  -H 'Content-Type: application/json' \
  --cookie '[REDACTED]' \
  "https://app2.govee.com/device/rest/devices/v1/list" > /opt/govee_h5042_sensor/response_json

## End curl request

  # Continue if the curl request return code was 0
  if [ "$?" -eq 0 ]; then
    # Parse out the temps using jq
    DEVICE_1_TEMP_CEL=$(jq '.devices[] | .deviceName as $name | .deviceExt.lastDeviceData | fromjson | {deviceName: $name, tem: .tem}' /opt/govee_h5042_sensor/response_json | jq --arg device1 "$DEVICE_1_NAME" 'select(.deviceName == $device1) | .tem' | sort | uniq)
    DEVICE_2_TEMP_CEL=$(jq '.devices[] | .deviceName as $name | .deviceExt.lastDeviceData | fromjson | {deviceName: $name, tem: .tem}' /opt/govee_h5042_sensor/response_json | jq --arg device2 "$DEVICE_2_NAME" 'select(.deviceName == $device2) | .tem' | sort | uniq)
    # Convert from C* to F*
    DEVICE_1_TEMP=$(echo "$DEVICE_1_TEMP_CEL" | awk '{print $1 / 100}' | awk '{print ($1 * 9 / 5) + 32}')
    DEVICE_2_TEMP=$(echo "$DEVICE_2_TEMP_CEL" | awk '{print $1 / 100}' | awk '{print ($1 * 9 / 5) + 32}')

    # If the reported temp is 32F, something went wrong parsing the temp value and we can't trust it
    if [ "$DEVICE_1_TEMP" -ne 32 ]; then
      echo "$DEVICE_1_TEMP" > /opt/govee_h5042_sensor/temps/"$DEVICE_1_NAME"
    fi
    if [ "$DEVICE_2_TEMP" -ne 32 ]; then
      echo "$DEVICE_2_TEMP" > /opt/govee_h5042_sensor/temps/"$DEVICE_2_NAME"
    fi
    sleep 60
  fi
done