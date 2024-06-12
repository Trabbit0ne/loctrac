#!/bin/bash

#----------------------------------------
#     .:: Made by Pentagone Group ::.
#----------------------------------------
# Date - 2024.06.01
#----------------------------------------
#     Location Tracking Software
#----------------------------------------

# Function to kill all previous Firefox sessions
kill_firefox() {
    if pgrep -x "firefox" > /dev/null; then
        pkill firefox
        echo "Firefox processes killed."
    else
        echo "No Firefox processes found."
    fi
}

# Function to install necessary packages if not installed
install_package() {
    if ! command -v "$1" &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y "$1"
    fi
}

# Clear the screen
clear

# Check and install necessary packages
install_package "xdotool"
install_package "xdpyinfo"
install_package "xwininfo"
install_package "jq"

# Function to get public IP address
get_public_ip() {
    curl -s https://api.ipify.org
}

# Function to perform traceroute and determine device type
get_device_type() {
    local ip=$1
    local traceroute_output=$(traceroute -w 1 -q 1 -m 1 "${ip}" 2>/dev/null)
    local device_type="Unknown"

    if [[ -n "${traceroute_output}" ]]; then
        if echo "${traceroute_output}" | grep -qiE '3g|4g|lte'; then
            device_type="Mobile device"
        elif echo "${traceroute_output}" | grep -qiE 'satellite'; then
            device_type="Satellite connection"
        else
            device_type="Desktop or broadband connection"
        fi
    fi

    echo "$device_type"
}

# Check if the IP address is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: loctrac <ip> or loctrac -m"
    exit 1
fi

if [ "$1" = "-m" ]; then
    ip=$(get_public_ip)
else
    ip=$1
fi

# Get the location based on IP address using IP-API
location_ipapi=$(curl -s "http://ip-api.com/json/${ip}")
latitude=$(echo "$location_ipapi" | jq -r '.lat')
longitude=$(echo "$location_ipapi" | jq -r '.lon')

# Get the zip code using ipinfo.io
location_ipinfo=$(curl -s "https://ipinfo.io/${ip}/json")
zip_code=$(echo "$location_ipinfo" | jq -r '.postal')

# Further check if the zip code is null or empty, set a default message
if [ "$zip_code" = "null" ] || [ -z "$zip_code" ]; then
    zip_code="Unavailable"
fi

# Determine device type
device_type=$(get_device_type "$ip")

timestamp=$(date +%s)
filename="location_${ip}_${timestamp}.html"

# Create a Folium map
cat <<EOF > $filename
<!DOCTYPE html>
<html>
<head>
    <title>Location Map</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
</head>
<body>
    <div id="map" style="width: 100%; height: 100vh;"></div>
    <script>
        var map = L.map('map').setView([$latitude, $longitude], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19
        }).addTo(map);
        L.marker([$latitude, $longitude], { color: 'red' }).addTo(map);
        L.circle([$latitude, $longitude], { color: 'red', radius: 200 }).addTo(map);
    </script>
</body>
</html>
EOF

# Move the file to saves directory
mkdir -p /etc/loctrac/saves/
mv $filename /etc/loctrac/saves/

# Open the HTML file in Firefox
firefox /etc/loctrac/saves/$filename &

# Wait for Firefox window to appear
attempts=0
max_attempts=20
while true; do
    FIREFOX_WINDOW_ID=$(xdotool search --onlyvisible --class "firefox")
    if [ -n "$FIREFOX_WINDOW_ID" ]; then
        break
    fi
    if [ "$attempts" -ge "$max_attempts" ]; then
        echo "Firefox window did not appear. Exiting."
        exit 1
    fi
    sleep 0.5  # Check every 0.5 seconds
    attempts=$((attempts + 1))
done

# Get the screen resolution using xdpyinfo
SCREEN_RESOLUTION=$(xdpyinfo | awk '/dimensions:/ {print $2}')
SCREEN_WIDTH=$(echo $SCREEN_RESOLUTION | cut -d 'x' -f 1)
SCREEN_HEIGHT=$(echo $SCREEN_RESOLUTION | cut -d 'x' -f 2)

# Calculate window positions and sizes
HALF_SCREEN_WIDTH=$((SCREEN_WIDTH / 2))

# Function to get the window ID for a given application
get_window_id() {
    local app_class=$1
    xdotool search --onlyvisible --class "$app_class" | head -n 1
}

TERMINAL_WINDOW_ID=$(get_window_id "gnome-terminal")

# Move and resize windows using xdotool
if [ -n "$TERMINAL_WINDOW_ID" ]; then
    xdotool windowmove "$TERMINAL_WINDOW_ID" 0 0
    xdotool windowsize "$TERMINAL_WINDOW_ID" "$HALF_SCREEN_WIDTH" "$SCREEN_HEIGHT"
fi

if [ -n "$FIREFOX_WINDOW_ID" ]; then
    xdotool windowmove "$FIREFOX_WINDOW_ID" "$HALF_SCREEN_WIDTH" 0
    xdotool windowsize "$FIREFOX_WINDOW_ID" "$HALF_SCREEN_WIDTH" "$SCREEN_HEIGHT"
else
    echo "Firefox window not found"
    exit 1
fi

# Print IP information
echo "PENTAGONE GROUP - LOCTRAC SOFTWARE"
echo "[+] IP Address   => $(echo "$location_ipapi" | jq -r '.query')"
echo "[+] Country      => $(echo "$location_ipapi" | jq -r '.country')"
echo "[+] Date & Time  => $(date +'%Y-%m-%d %H:%M:%S')"
echo "[+] Region code  => $(echo "$location_ipapi" | jq -r '.region')"
echo "[+] Region       => $(echo "$location_ipapi" | jq -r '.regionName')"
echo "[+] City         => $(echo "$location_ipapi" | jq -r '.city')"
echo "[+] Zip code     => $zip_code"
echo "[+] Time zone    => $(echo "$location_ipapi" | jq -r '.timezone')"
echo "[+] ISP          => $(echo "$location_ipapi" | jq -r '.isp')"
echo "[+] Organization => $(echo "$location_ipapi" | jq -r '.org')"
echo "[+] ASN          => $(echo "$location_ipapi" | jq -r '.as')"
echo "[+] Latitude     => $latitude"
echo "[+] Longitude    => $longitude"
echo "[+] Location     => $latitude,$longitude"
echo "[+] Device type  => $device_type"
echo
read -p "Press Enter To Continue & Exit The Map GUI/UI..."
clear
kill_firefox
clear
echo "Session $ip Terminated."
sleep 1
clear
exit 0
