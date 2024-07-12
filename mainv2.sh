# ******************************************************************
# | WARNING: This Tool Is Made For Pentesters And Ethical Purposes |
# ******************************************************************

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Youtube: TrabbitOne
# BuyMeACoffee: trabbit0ne

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#----------------------------------------
#     .:: Made by Pentagone Group ::.
#----------------------------------------
#          Date - 2024.06.01
#----------------------------------------
#     Location Tracking Software
#----------------------------------------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#!/bin/bash

# Set color code shortcuts
blue="\e[36m"
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
bgblue="\e[46m"
bgred="\e[41m"
bggreen="\e[42m"
bgyellow="\e[43m"
clean="\e[0m"

# Function to write text with text writing effect
write() {
    local text="$1"
    local delay=${2:-0.01}  # Default delay of 0.05 seconds

    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo  # Print a newline at the end
}


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
install_package "inetutils-traceroute"

# Function to get public IP address
get_public_ip() {
    curl -s https://api.ipify.org    # Ip Tracking Public API
}

# Function to determine device type
get_device_type() {
    local traceroute_output=$(traceroute -w 1 -q 1 -m 1 "${ip}" 2>/dev/null)
    local device_type="Unknown"

    if [[ -n "${traceroute_output}" ]]; then
        if echo "${traceroute_output}" | grep -qiE '3g|4g|lte'; then
            device_type="Mobile device"
        elif echo "${traceroute_output}" | grep -qiE 'satellite'; then
            device_type="Satellite connection"
        else
            device_type="Desktop // broadband connection"
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
            echo -e "${red}INFO${clean} Version: $version"
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
        // Replace these variables with the actual latitude and longitude
        var latitude = $latitude;
        var longitude = $longitude;

        // Initialize the map and set its view to the specified coordinates
        var map = L.map('map').setView([latitude, longitude], 14);

        // Add OpenStreetMap tile layer to the map
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19
        }).addTo(map);

        // Define a custom red marker icon
        var redIcon = new L.Icon({
            iconUrl: 'https://i.ibb.co/vvB6T4b/58568b014f6ae202fedf2717-620355315.png', // Example URL to a red marker icon
            iconSize: [80, 80], // Size of the icon
            iconAnchor: [39, 39], // Point of the icon which will correspond to marker's location (centered bottom)
            popupAnchor: [0, -20], // Point from which the popup should open relative to the iconAnchor
            shadowUrl: '#', // Optional shadow URL
            shadowSize: [0, 0], // Size of the shadow
            shadowAnchor: [0, 0] // Point of the shadow which will correspond to the marker's location
        });

        // Use the custom red marker icon and add it to the map at the specified coordinates
        L.marker([latitude, longitude], { icon: redIcon }).addTo(map);

        // Add a red circle with the specified radius around the marker
        L.circle([latitude, longitude], { color: 'red', radius: 1500 }).addTo(map);
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

# Display IP location informations
clear
echo -e "   |     \_|)   _   _ _|_  ,_   _,   _        "
echo -e "--(+)--    |   / \_/   |  /  | / |  /         "
echo -e "   |      (\__/\_/ \__/|_/   |/\/|_/\__/      "
echo
echo -e "${bgred}       PENTAGONE GROUP - LOCTRAC SOFTWARE       ${clean}"
echo
echo -e "${red}[INFO]${clean} [+] IP Address   => $ip    "
echo -e "${red}[INFO]${clean} [+] Country      => $(echo "$location_ipapi" | jq -r '.country')"
echo -e "${red}[INFO]${clean} [+] Date & Time  => $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${red}[INFO]${clean} [+] Region code  => $(echo "$location_ipapi" | jq -r '.region')"
echo -e "${red}[INFO]${clean} [+] Region       => $(echo "$location_ipapi" | jq -r '.regionName')"
echo -e "${red}[INFO]${clean} [+] City         => $(echo "$location_ipapi" | jq -r '.city')"
echo -e "${red}[INFO]${clean} [+] Zip code     => $zip_code"
echo -e "${red}[INFO]${clean} [+] Time zone    => $(echo "$location_ipapi" | jq -r '.timezone')"
echo -e "${red}[INFO]${clean} [+] ISP          => $(echo "$location_ipapi" | jq -r '.isp')"
echo -e "${red}[INFO]${clean} [+] Organization => $(echo "$location_ipapi" | jq -r '.org')"
echo -e "${red}[INFO]${clean} [+] ASN          => $(echo "$location_ipapi" | jq -r '.as')"
echo -e "${red}[INFO]${clean} [+] Latitude     => $latitude"
echo -e "${red}[INFO]${clean} [+] Longitude    => $longitude"
echo -e "${red}[INFO]${clean} [+] Location     => $latitude,$longitude"
echo -e "${red}[INFO]${clean} [+] Device Type  => $device_type"
echo

read -p "Press Enter To Continue & Exit The Map GUI/UI..."
clear

# Kill all Firefox processes that are running
kill_firefox

# Clear the terminal screen
clear

# Print backup information
echo -e "${red}[INFO]${clean}"
write "Backup Saved At /etc/loctrac/saves/."
echo -e "${red}[INFO]${clean}"
write "Backup Saved As Html"
echo -e "${red}[INFO]${clean}"
write "-- All Saved -- "
echo -e "${red}[INFO]${clean}"
write "Saved By $(whoami) User"
sleep 0.3

# Clear the terminal screen
clear

# Exit the terminal
exit 0
