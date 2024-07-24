
 ##################################################################
 # WARNING: This Tool Is Made For Pentesters And Ethical Purposes #
 ##################################################################

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ----------------------------------------
# Youtube: TrabbitOne
# BuyMeACoffee: trabbit0ne
# Bitcoin: bc1qehnsx5tdwkulamttzla96dmv82ty9ak8l5yy40
# ----------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ----------------------------------------
# IP Location Tracking software
# Author: Trabbit
# Date: 2024-07-13
# ----------------------------------------
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#!/bin/bash

# Set color code shortcuts
blue="\e[36m"     # Blue text code
red="\e[1;31m"      # Red text code
green="\e[32m"    # Green text code
yellow="\e[33m"   # Yellow text code
bgblue="\e[46m"   # Blue background color code
bgred="\e[41m"    # Red background color code
bggreen="\e[42m"  # Green background color code
bgyellow="\e[43m" # Yellow background color code
clean="\e[0m"     # cleared color (empty)

# Default theme color
text_color="$red" # Default text color
bg_color="$bgred" # Default background

# Function to write text with text writing effect
write() {
    local text="$1"
    local delay=${2:-0.02}  # Default delay of 0.05 seconds

    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo  # Print a newline at the end
}

# Function to handle errors
handle_error() {
    local exit_code=$1
    local msg="$2"
    if [ $exit_code -ne 0 ]; then
        echo -e "${red}[ERROR]${clean} $msg" >&2
        exit $exit_code
    fi
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
        handle_error $? "Failed to install package: $1"
    fi
}

# Check for network connectivity
if ! ping -c 1 google.com &> /dev/null; then
    handle_error 1 "Network connectivity is required. Please check your connection."
fi

# Clear the screen
clear

# Check and install necessary packages
required_commands=("curl" "jq" "traceroute" "xdotool" "xdpyinfo" "xwininfo" "firefox")
for cmd in "${required_commands[@]}"; do
    command -v "$cmd" &> /dev/null
    handle_error $? "$cmd is required but not installed. Please install it before running the script."
done

# Function to get public IP address
get_public_ip() {
    local result=$(curl -s -w "%{http_code}" https://api.ipify.org)
    local http_code="${result: -3}"
    if [ "$http_code" -ne 200 ]; then
        handle_error 1 "Failed to retrieve public IP address."
    fi
    echo "${result:0:${#result}-3}"
}

# Function to determine device type
get_device_type() {
    local traceroute_output=$(traceroute -w 1 -q 1 -m 1 "$ip" 2>/dev/null)
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
    echo -e "${bg_color}        .:: Loctrac Program Usage ::.        ${clean}"
    echo -e "---------------------------------------------         "
    echo -e "Options:                                              "
    echo -e "  [-m] | Track your own public IP                     "
    echo -e "  [-h] | Show help and usage information              "
    echo -e "  [-v] | Show current version of the program          "
    echo
    echo -e "---------------------------------------------         "
    echo -e "Examples:                                             "
    echo -e "  [1. loctrac -m ]   Every scans mades                "
    echo -e "  [2. loctrac -h ]   are saved in                     "
    echo -e "  [3. loctrac -v ]   /etc/loctrac/saves/              "
    echo
    echo -e "---------------------------------------------         "
    echo -e ""
    echo
}

# Check if the IP address is provided
if [ "$#" -lt 1 ]; then
    show_help
    exit 1
fi

# Parse arguments
ip=""
version="1.8"

while getopts ":mhvt" option; do
    case $option in
        m)
            ip=$(get_public_ip)
            ;;
        h)
            show_help
            exit 0
            ;;
        v)
            echo -n -e "${text_color}[INFO]${clean} "
            write "Version: $version"
            exit 0
            ;;
        t)
            set_colors "$OPTARG"
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

# If IP is still not set, use the provided argument
if [ -z "$ip" ]; then
    ip="$1"
    if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        handle_error 1 "Invalid IP address format."
    fi
fi

# Get the location based on IP address using IP-API
location_ipapi=$(curl -s "http://ip-api.com/json/${ip}")
handle_error $? "Failed to retrieve location from IP-API."
latitude=$(echo "$location_ipapi" | jq -r '.lat')
longitude=$(echo "$location_ipapi" | jq -r '.lon')

# Get the zip code using ipinfo.io
location_ipinfo=$(curl -s "https://ipinfo.io/${ip}/json")
handle_error $? "Failed to retrieve location from ipinfo.io."
zip_code=$(echo "$location_ipinfo" | jq -r '.postal')

# Further check if the zip code is null or empty, set a default message
if [ "$zip_code" = "null" ] || [ -z "$zip_code" ]; then
    zip_code="Unavailable"
fi

# Determine device type
device_type=$(get_device_type "$ip")

timestamp=$(date +%s)
filename="location_${ip}_${timestamp}.html"

# Create map for firefox & /etc/loctrac/saves/
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

# Create and move files to /saves directory
mkdir -p /etc/loctrac/saves/
handle_error $? "Failed to create directory /etc/loctrac/saves/"

mv "$filename" /etc/loctrac/saves/
handle_error $? "Failed to move $filename to /etc/loctrac/saves/"

# Open the HTML file in Firefox
firefox /etc/loctrac/saves/$filename &

# Wait for Firefox window to appear
attempts=0        # Amount of attempts at the beginning
max_attempts=20   # Amount of attempts at the end
while true; do
    FIREFOX_WINDOW_ID=$(xdotool search --onlyvisible --class "firefox")
    if [ -n "$FIREFOX_WINDOW_ID" ]; then
        break
    fi
    if [ "$attempts" -ge "$max_attempts" ]; then
        handle_error 1 "Firefox window did not appear. Exiting."
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
    handle_error 1 "Firefox window not found."
fi

# Display IP location information
clear
echo -e "   |     \_|)   _   _ _|_  ,_   _,   _        "
echo -e "--(+)--    |   / \_/   |  /  | / |  /         "
echo -e "   |      (\__/\_/ \__/|_/   |/\/|_/\__/      "
echo
echo -e "${bg_color}       PENTAGONE GROUP - LOCTRAC SOFTWARE       ${clean}"
echo
echo -e "${text_color}[INFO]${clean} [+] IP Address   => $ip    "
echo -e "${text_color}[INFO]${clean} [+] Country      => $(echo "$location_ipapi" | jq -r '.country')"
echo -e "${text_color}[INFO]${clean} [+] Date & Time  => $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${text_color}[INFO]${clean} [+] Region code  => $(echo "$location_ipapi" | jq -r '.region')"
echo -e "${text_color}[INFO]${clean} [+] Region       => $(echo "$location_ipapi" | jq -r '.regionName')"
echo -e "${text_color}[INFO]${clean} [+] City         => $(echo "$location_ipapi" | jq -r '.city')"
echo -e "${text_color}[INFO]${clean} [+] Zip code     => $zip_code"
echo -e "${text_color}[INFO]${clean} [+] Time zone    => $(echo "$location_ipapi" | jq -r '.timezone')"
echo -e "${text_color}[INFO]${clean} [+] ISP          => $(echo "$location_ipapi" | jq -r '.isp')"
echo -e "${text_color}[INFO]${clean} [+] Organization => $(echo "$location_ipapi" | jq -r '.org')"
echo -e "${text_color}[INFO]${clean} [+] ASN          => $(echo "$location_ipapi" | jq -r '.as')"
echo -e "${text_color}[INFO]${clean} [+] Latitude     => $latitude"
echo -e "${text_color}[INFO]${clean} [+] Longitude    => $longitude"
echo -e "${text_color}[INFO]${clean} [+] Location     => $latitude,$longitude"
echo -e "${text_color}[INFO]${clean} [+] Device Type  => $device_type"
echo

read -p "Press Enter To Continue & Exit The Map GUI/UI..."
clear

# Kill all Firefox processes that are running
kill_firefox

# Clear the terminal screen
clear

# Print backup information
echo -e "${text_color}[MSG]${clean}"                                    # MSG type is used for tips and group informations
write "Support on BuyMeACoffee [https://buymeacoffee.com/trabbit0ne]"   # Url to the BuyMeACoffee account

echo -e "${text_color}[INFO]${clean}"                                   # MSG type is used for tips and group informations
write "Ended session is linked to an Ip address: $ip"                               # INFO type is used for program/tool informations

echo -e "${text_color}[INFO]${clean}"                                   # INFO type is used for program/tool informations
write "Backup Saved At /etc/loctrac/saves/"                             # Backup for html files

echo -e "${text_color}[INFO]${clean}"                                   # INFO type is used for program/tool informations
write "Backup Saved As Html"                                            # Type of code used for saved files (HTML)

echo -e "${text_color}[INFO]${clean}"                                   # INFO type is used for program/tool informations
write "File: $filename"                                                 # Name of the output file saved in .html extension

echo -e "${text_color}[INFO]${clean}"                                   # INFO type is used for program/tool informations
write "-- All Saved -- "                                                # All files are saved in /etc/loctrac/saves/

echo -e "${text_color}[INFO]${clean}"                                   # INFO type is used for program/tool informations
write "Saved By $(whoami) User"                                         # Who used the program/tool during the process

echo

sleep 0.8 # Wait 0.8 seconds before exiting

clear # Clear the terminal screen

# Exit the terminal
exit 0
