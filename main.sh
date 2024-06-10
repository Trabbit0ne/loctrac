#----------------------------------------
#     .:: Made by Pentagone Group ::.
#----------------------------------------
# Date - 2024.06.01
#----------------------------------------
#     Location Tracking Software
#----------------------------------------

# Ensure necessary packages are installed
install_package() {
    if ! command -v "$1" &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y "$1"
    fi
}

install_package "xdotool"
install_package "xdpyinfo"
install_package "xwininfo"
install_package "jq"

# Clear the screen
clear

# Check if the IP address is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: loctrac <ip>"
    exit 1
fi

ip=$1

# Get the location based on IP address
location=$(curl -s "https://ipinfo.io/${ip}/json")
latitude=$(echo "$location" | jq -r '.loc' | cut -d',' -f1)
longitude=$(echo "$location" | jq -r '.loc' | cut -d',' -f2)
timestamp=$(date +%s)
filename="location_${ip}_${timestamp}.html"

# Create a Folium map
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


# Move the file to saves
mkdir -p /etc/loctrac/saves/
mv $filename /etc/loctrac/saves/

# Open the HTML file in Firefox
firefox /etc/loctrac/saves/$filename &

# Use xdotool to arrange windows
sleep 3.5  # Wait for Firefox to open

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
FIREFOX_WINDOW_ID=$(get_window_id "firefox")

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
echo "[+] IP Address   => $(echo "$location" | jq -r '.ip')"
echo "[+] Country code => $(echo "$location" | jq -r '.country')"
echo "[+] Country      => $(echo "$location" | jq -r '.country_name')"
echo "[+] Date & Time  => $(date +'%Y-%m-%d %H:%M:%S')"
echo "[+] Region code  => $(echo "$location" | jq -r '.region')"
echo "[+] Region       => $(echo "$location" | jq -r '.region_name')"
echo "[+] City         => $(echo "$location" | jq -r '.city')"
echo "[+] Zip code     => $(echo "$location" | jq -r '.postal')"
echo "[+] Time zone    => $(echo "$location" | jq -r '.timezone')"
echo "[+] ISP          => $(echo "$location" | jq -r '.org')"
echo "[+] Organization => $(echo "$location" | jq -r '.org_name')"
echo "[+] ASN          => $(echo "$location" | jq -r '.asn')"
echo "[+] Latitude     => $latitude"
echo "[+] Longitude    => $longitude"
echo "[+] Location     => $(echo "$location" | jq -r '.loc')"
echo
