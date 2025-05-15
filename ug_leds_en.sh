#!/bin/bash

SCRIPTPATH=$(dirname "${0}")

if ! [[ -f "${SCRIPTPATH}/ugreen_leds_cli" ]]; then
  echo "ugreen_leds_cli not found in the script directory!"
  exit 1
fi

# Mapping of LED to HCTL
# https://github.com/miskcoo/ugreen_leds_controller?tab=readme-ov-file#disk-mapping
# For DX4600 Pro and DXP8800 Plus, mapping is X:0:0:0 -> diskX.
# For DXP6800 Pro, 0:0:0:0 and 1:0:0:0 map to disk5 and disk6, 2:0:0:0 to 6:0:0:0 map to disk1 to disk4.
# For other models or virtual DSM on a host, please check the HCTL of each bay and fill in the HCTL values according to the actual bay order.
# "disk" represents panel LED positions¡ªdo not modify. Leave entries for existing physical LEDs; comment out others.
declare -A led_map=(
    ["disk1"]="0:0:0:0"
    ["disk2"]="1:0:0:0"
    ["disk3"]="2:0:0:0"
    ["disk4"]="3:0:0:0"
    ["disk5"]="4:0:0:0"
    ["disk6"]="5:0:0:0"
    ["disk7"]="6:0:0:0"
    ["disk8"]="7:0:0:0"
)

# Mapping to maintain desired LED colors and states
declare -A led_status

# Initialize all LEDs to off
led_status["power"]="-off"
led_status["netdev"]="-off"
for key in "${!led_map[@]}"; do
    led_status[$key]="-off"
done

# Check network status
check_network_connectivity() {
    gw=$(ip route | awk '/default/ { print $3 }')
    if ping -q -c 1 -W 1 "${gw}" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get active SATA drives and their HCTL addresses
active_disks=$(
    for dev in /dev/sata*; do
         # Ensure the device is SATA and not a partition
        if [ -e "$dev" ] && [[ "$(basename "$dev")" =~ ^sata[0-9]+$ ]]; then
            # Check if the device is a SATA device
            if udevadm info --query=property --name="$dev" | grep -q "SYNO_DEV_DISKPORTTYPE=SATA"; then
                # Extract the HCTL address
                hctl=$(udevadm info --query=all --name="$dev" | grep -oP 'target\d+:\d+:\d+/(\d+:\d+:\d+:\d+)' | head -n 1 | sed -E 's/target[0-9]+:[0-9]+:[0-9]+\///')

                # Output device name and HCTL address
                echo "$(basename "$dev") $hctl"
            fi
        fi
    done
)

# Set power LED state (default white)
led_status["power"]="-color 255 255 255 -on -brightness 64"

# Check if the sensors command is installed (required in rr boot with sensors plugin)
if command -v sensors >/dev/null 2>&1; then
    # Get CPU temperature
    cpu_temp=$(sensors | awk '/Core 0/ {print $3}' | cut -c2- | cut -d'.' -f1)
    # echo "Current CPU $cpu_temp¡ãC"  # Log (optional)
    if [[ -n "$cpu_temp" && "$cpu_temp" -gt 90 ]]; then
        # If above 90¡ãC, set power LED to red blinking
        led_status["power"]="-color 255 0 0 -on -blink 400 600 -brightness 64"
    fi
else
    echo "Warning: 'sensors' command not found. Skipping CPU temperature check." >&2
fi

# Check network connectivity and set netdev LED accordingly
if check_network_connectivity; then
    led_status["netdev"]="-color 0 0 255 -on -brightness 64"  # Blue for connected
else
    led_status["netdev"]="-color 255 0 0 -on -brightness 64"  # Red for not connected
fi

#
