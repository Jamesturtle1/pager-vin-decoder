#!/bin/bash
# Title: VIN Decoder
# Description: Decode a vehicle VIN using the NHTSA vPIC database
# Author: OpenAI
# Version: 1.0
# Category: Utilities
#
# Requires:
#   - WiFi Pineapple Pager
#   - Internet access
#   - curl
#   - jsonfilter (normally included with OpenWrt)
#
# This uses NHTSA's public vPIC VIN decoder API.
# It returns manufacturer-reported vehicle information.
#
# It does NOT perform owner, registration, title, or personal-information lookups.

API_BASE="https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValuesExtended"

cleanup() {
    rm -f /tmp/vin_decoder.json /tmp/vin_decoder.tmp
}
trap cleanup EXIT

# ---------- Helpers ----------

get_field() {
    # $1 = JSON field name
    jsonfilter -i /tmp/vin_decoder.json -e "@.Results[0].$1" 2>/dev/null
}

show_value() {
    # $1 = label, $2 = value
    if [ -n "$2" ] && [ "$2" != "null" ] && [ "$2" != " " ]; then
        LOG white "$1: $2"
    fi
}

decode_vin() {
    VIN="$(TEXT_PICKER 'Enter 17-character VIN' '')"
    VIN="$(echo "$VIN" | tr '[:lower:]' '[:upper:]' | tr -d ' -')"

    if [ -z "$VIN" ]; then
        LOG red "No VIN entered."
        sleep 2
        return
    fi

    # VINs are normally 17 characters and do not contain I, O, or Q.
    if [ "${#VIN}" -ne 17 ]; then
        LOG red "VIN must be exactly 17 characters."
        sleep 2
        return
    fi

    case "$VIN" in
        *I*|*O*|*Q*)
            LOG red "Invalid VIN: I, O and Q are not used."
            sleep 2
            return
            ;;
    esac

    # Optional model year. NHTSA can often determine it from the VIN,
    # but supplying it can improve decoding for some VINs.
    YEAR="$(TEXT_PICKER 'Model year (optional)' '')"
    YEAR="$(echo "$YEAR" | tr -cd '0-9')"

    LOG blue "Checking Internet connection..."
    if ! curl -k -s --connect-timeout 5 --max-time 10 "https://vpic.nhtsa.dot.gov/" >/dev/null; then
        LOG red "No Internet connection."
        sleep 2
        return
    fi

    LOG blue "Decoding $VIN..."
    sleep 1

    if [ -n "$YEAR" ]; then
        curl -k -s --get \
            --connect-timeout 8 \
            --max-time 20 \
            --data-urlencode "format=json" \
            --data-urlencode "modelyear=$YEAR" \
            "${API_BASE}/${VIN}" > /tmp/vin_decoder.json
    else
        curl -k -s --get \
            --connect-timeout 8 \
            --max-time 20 \
            --data-urlencode "format=json" \
            "${API_BASE}/${VIN}" > /tmp/vin_decoder.json
    fi

    if [ ! -s /tmp/vin_decoder.json ]; then
        LOG red "No response from NHTSA."
        sleep 2
        return
    fi

    MAKE="$(get_field Make)"
    MODEL="$(get_field Model)"
    MODEL_YEAR="$(get_field ModelYear)"
    SERIES="$(get_field Series)"
    TRIM="$(get_field Trim)"
    BODY="$(get_field BodyClass)"
    VEHICLE_TYPE="$(get_field VehicleType)"
    ENGINE="$(get_field EngineModel)"
    CYLINDERS="$(get_field EngineCylinders)"
    DISPLACEMENT="$(get_field DisplacementL)"
    FUEL="$(get_field FuelTypePrimary)"
    TRANSMISSION="$(get_field TransmissionStyle)"
    DRIVE="$(get_field DriveType)"
    DOORS="$(get_field Doors)"
    PLANT_CITY="$(get_field PlantCity)"
    PLANT_COUNTRY="$(get_field PlantCountry)"
    MANUFACTURER="$(get_field Manufacturer)"
    ERROR_TEXT="$(get_field ErrorText)"

    if [ -z "$MAKE$MODEL$MODEL_YEAR" ]; then
        LOG red "NHTSA did not return a vehicle result."
        [ -n "$ERROR_TEXT" ] && LOG yellow "$ERROR_TEXT"
        sleep 3
        return
    fi

    while true; do
        LOG cyan "===== VIN RESULT ====="
        LOG white "VIN: $VIN"
        show_value "Year" "$MODEL_YEAR"
        show_value "Make" "$MAKE"
        show_value "Model" "$MODEL"
        show_value "Series" "$SERIES"
        show_value "Trim" "$TRIM"
        show_value "Body" "$BODY"
        show_value "Vehicle Type" "$VEHICLE_TYPE"
        show_value "Engine" "$ENGINE"
        show_value "Cylinders" "$CYLINDERS"
        show_value "Displacement" "$DISPLACEMENT L"
        show_value "Fuel" "$FUEL"
        show_value "Transmission" "$TRANSMISSION"
        show_value "Drive" "$DRIVE"
        show_value "Doors" "$DOORS"
        show_value "Plant" "$PLANT_CITY"
        show_value "Country" "$PLANT_COUNTRY"
        show_value "Manufacturer" "$MANUFACTURER"
        LOG cyan "======================"
        LOG green "Press A to decode another VIN"
        LOG red "Press B to exit"

        BUTTON=""
        while [ -z "$BUTTON" ]; do
            BUTTON="$(BUTTON_WAIT)"
            sleep 0.1
        done

        case "$BUTTON" in
            A|a)
                return
                ;;
            B|b)
                exit 0
                ;;
        esac
    done
}

# ---------- Main menu ----------

while true; do
    CHOICE="$(SELECT 'VIN Decoder' \
        'Decode VIN' \
        'About' \
        'Exit')"

    case "$CHOICE" in
        "Decode VIN")
            decode_vin
            ;;
        "About")
            LOG cyan "VIN Decoder"
            LOG white "Uses NHTSA vPIC."
            LOG white "Manufacturer-reported vehicle data."
            LOG white "Internet connection required."
            sleep 3
            ;;
        "Exit"|"")
            exit 0
            ;;
    esac
done
