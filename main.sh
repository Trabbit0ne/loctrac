#!/bin/bash

#----------------------------------------
#     .:: Made by Pentagone Group ::.
#----------------------------------------
#          Date - 2024.06.01
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

# Function to determine device type
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

# Function to display help
show_help() {
    echo "        .:: Loctrac Program Usage ::.        "
    echo "---------------------------------------------"
    echo "Options:"
    echo "  [-m] | Track your own public IP"
    echo "  [-h] | Show help and usage information"
    echo "  [-v] | Show current version of the program"
    echo
    echo "---------------------------------------------"
    echo "Examples:"
    echo "  [1. loctrac -m ]"
    echo "  [2. loctrac -h | loctrac ]"
    echo "  [3. loctrac -v ]"
    echo
}

# Check if the IP address is provided
if [ "$#" -lt 1 ]; then
    show_help
    exit 1
fi

# Parse arguments
ip=""
version="1.6"

while getopts ":mhv" option; do
    case $option in
        m)
            ip=$(get_public_ip)
            ;;
        h)
            show_help
            exit 1
            ;;
        v)
            echo -e "\e[36mINFO\e[0m Version: $version"
            exit 1
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

# If IP is still not set, use the provided argument
if [ -z "$ip" ]; then
    ip="$1"
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
    <title>$filename</title>
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
        L.marker([$latitude, $longitude], { color: 'blue' }).addTo(map);
        L.circle([$latitude, $longitude], { color: 'blue', radius: 800 }).addTo(map);
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

# Display IP location information
clear
echo -e "   |     \_|)   _   _ _|_  ,_   _,   _        "
echo -e "--(+)--    |   / \_/   |  /  | / |  /         "
echo -e "   |      (\__/\_/ \__/|_/   |/\/|_/\__/      "
echo
echo -e "\e[46m       PENTAGONE GROUP - LOCTRAC SOFTWARE     \e[0m"
echo
echo -e "\e[36mINFO\e[0m [+] IP Address   => $ip    "
echo -e "\e[36mINFO\e[0m [+] Country      => $(echo "$location_ipapi" | jq -r '.country')"
echo -e "\e[36mINFO\e[0m [+] Date & Time  => $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "\e[36mINFO\e[0m [+] Region code  => $(echo "$location_ipapi" | jq -r '.region')"
echo -e "\e[36mINFO\e[0m [+] Region       => $(echo "$location_ipapi" | jq -r '.regionName')"
echo -e "\e[36mINFO\e[0m [+] City         => $(echo "$location_ipapi" | jq -r '.city')"
echo -e "\e[36mINFO\e[0m [+] Zip code     => $zip_code"
echo -e "\e[36mINFO\e[0m [+] Time zone    => $(echo "$location_ipapi" | jq -r '.timezone')"
echo -e "\e[36mINFO\e[0m [+] ISP          => $(echo "$location_ipapi" | jq -r '.isp')"
echo -e "\e[36mINFO\e[0m [+] Organization => $(echo "$location_ipapi" | jq -r '.org')"
echo -e "\e[36mINFO\e[0m [+] ASN          => $(echo "$location_ipapi" | jq -r '.as')"
echo -e "\e[36mINFO\e[0m [+] Latitude     => $latitude"
echo -e "\e[36mINFO\e[0m [+] Longitude    => $longitude"
echo -e "\e[36mINFO\e[0m [+] Location     => $latitude,$longitude"
echo -e "\e[36mINFO\e[0m [+] Device Type  => $device_type"
echo
read -p "Press Enter To Continue & Exit The Map GUI/UI..."
clear

# Kill all Firefox processes that are running
kill_firefox

# Clear the terminal screen
clear

# Print backup information
echo -e "\e[36mINFO\e[0m Backup Saved At /etc/loctrac/saves/."
echo -e "\e[36mINFO\e[0m Backup Saved As Html"
echo -e "\e[36mINFO\e[0m -- ALL SAVED -- "
sleep 2.5

# Clear the terminal screen
clear

# Exit the terminal
exit 0
