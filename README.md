WiFi Pineapple Pager VIN Decoder

A small utility payload for the Hak5 WiFi Pineapple Pager.

## What it does

Enter a 17-character VIN and the payload queries the NHTSA vPIC VIN decoder API.

It can display information such as:

- Model year
- Make
- Model
- Series / trim
- Body class
- Vehicle type
- Engine
- Cylinders
- Displacement
- Fuel type
- Transmission
- Drive type
- Doors
- Manufacturing plant
- Manufacturer

## Requirements

- WiFi Pineapple Pager
- Internet access
- `curl`
- `jsonfilter`

The standard OpenWrt environment normally provides the JSON filtering utility.

## Install

Copy the `vin_decoder` folder into:

`/root/payloads/user/utilities/`

Then make the script executable:

`chmod +x /root/payloads/user/utilities/vin_decoder/payload.sh`

It should appear under the Pager's Utilities payloads.

## API

The payload uses NHTSA's vPIC VIN decoder. NHTSA states that the decoder uses vehicle information reported by manufacturers.

It does not look up vehicle owners, addresses, registration records, titles, or other personal information.