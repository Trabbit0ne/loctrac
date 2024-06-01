#!/usr/bin/env python3
#----------------------------------------
#     .:: Made by Pentagone Group ::.
#----------------------------------------
# Date - 2024.06.01
#----------------------------------------
#     Location Tracking Software
#----------------------------------------
import geocoder
import folium
import os
import time
import sys
import subprocess
import json
import requests

os.system("cp main.py /bin/loctrac && chmod +x /bin/loctrac")

# Function to check if a command is available
def command_exists(command):
    return subprocess.run(['command', '-v', command], stdout=subprocess.PIPE, shell=True).returncode == 0

# Function to install a package using apt-get (Linux)
def install_package(package):
    print(f"Installing {package}...")
    subprocess.run(['sudo', 'apt-get', 'install', '-y', package])

# Check if wmctrl is available
if not command_exists('wmctrl'):
    install_package('wmctrl')

# Check if xdotool is available
if not command_exists('xdotool'):
    install_package('xdotool')

# Clear the screen
os.system("clear")

# Function to get the location based on IP address
def get_location(ip_address):
    location = geocoder.ip(ip_address)
    return location

# Function to get IP information
def get_ip_info(ip_address):
    url = f"https://ipinfo.io/{ip_address}/json"
    response = requests.get(url)
    if response.status_code == 200:
        return json.loads(response.text)
    else:
        return None

# Check if the IP address is provided
if len(sys.argv) != 2:
    print("Usage: python3 program.py <ip>")
    sys.exit(1)

ip = sys.argv[1]

# Get location information
location_info = get_location(ip)

# Create a Folium map
coordinate = [location_info.latlng[0], location_info.latlng[1]]
myloc = folium.Map(location=coordinate, zoom_start=14, popup='My Location')

# Add a marker to the map
folium.Marker(coordinate, icon=folium.Icon(color='red', icon_color='white', prefix='fa', icon='male')).add_to(myloc)

# Add a circle around the location
folium.Circle(color='red', location=coordinate, radius=200).add_to(myloc)

# Generate a unique file name based on timestamp
timestamp = int(time.time())
filename = f'location_{ip}_{timestamp}.html'

# Save the map as an HTML file
myloc.save(filename)

# Print IP information
ip_info = get_ip_info(ip)
if ip_info:
    print("PENTAGONE GROUP - LOCTRAC SOFTWARE")
    print("[+]IP Address   =>   ", ip_info.get('ip', 'N/A'))
    print("[+]Country code =>   ", ip_info.get('country', 'N/A'))
    print("[+]Country      =>   ", ip_info.get('country_name', 'N/A'))
    print("[+]Date & Time  =>   ", time.strftime('%Y-%m-%d %H:%M:%S', time.localtime()))
    print("[+]Region code  =>   ", ip_info.get('region', 'N/A'))
    print("[+]Region       =>   ", ip_info.get('region_name', 'N/A'))
    print("[+]City         =>   ", ip_info.get('city', 'N/A'))
    print("[+]Zip code     =>   ", ip_info.get('postal', 'N/A'))
    print("[+]Time zone    =>   ", ip_info.get('timezone', 'N/A'))
    print("[+]ISP          =>   ", ip_info.get('org', 'N/A'))
    print("[+]Organization =>   ", ip_info.get('org_name', 'N/A'))
    print("[+]ASN          =>   ", ip_info.get('asn', 'N/A'))
    print("[+]Latitude     =>   ", ip_info.get('loc', 'N/A').split(',')[0])
    print("[+]Longitude    =>   ", ip_info.get('loc', 'N/A').split(',')[1])
    print("[+]Location     =>   ", ip_info.get('loc', 'N/A'))

# Move the file to saves
os.system(f"mv {filename} saves/")

# Open the HTML file in Firefox
os.system(f"firefox saves/{filename} &")

# Use wmctrl and xdotool to arrange windows
time.sleep(2)  # Wait for Firefox to open

# Get the screen resolution
screen_resolution = os.popen('xdotool getdisplaygeometry').read().strip().split()
screen_width = int(screen_resolution[0])
screen_height = int(screen_resolution[1])

# Calculate half screen width
half_screen_width = screen_width // 2

# Position Firefox window on the right half of the screen
firefox_window_id = os.popen("xdotool search --onlyvisible --class firefox").read().strip().split()
if firefox_window_id:
    firefox_window_id = firefox_window_id[0]
    os.system(f"wmctrl -ir {firefox_window_id} -b remove,maximized_vert,maximized_horz")  # Unmaximize Firefox if needed
    os.system(f"wmctrl -ir {firefox_window_id} -e 0,{half_screen_width},0,{half_screen_width},{screen_height}")  # Move Firefox to the right half of the screen
    os.system(f"wmctrl -ir {firefox_window_id} -b add,maximized_vert")  # Maximize Firefox vertically
else:
    sys.exit(1)

# Try to find the terminal window dynamically
terminal_window_id = None
terminal_class_names = ["gnome-terminal", "xfce4-terminal", "konsole", "mate-terminal", "lxterminal", "terminator"]

for terminal_class in terminal_class_names:
    terminal_window_id = os.popen(f"xdotool search --onlyvisible --class {terminal_class}").read().strip().split()
    if terminal_window_id:
        terminal_window_id = terminal_window_id[0]
        break

if terminal_window_id:
    os.system(f"wmctrl -ir {terminal_window_id} -b remove,maximized_vert,maximized_horz")  # Unmaximize terminal if needed
    os.system(f"wmctrl -ir {terminal_window_id} -e 0,0,0,{half_screen_width},{screen_height}")  # Move terminal to the left half of the screen
    os.system(f"wmctrl -ir {terminal_window_id} -b add,maximized_vert")  # Maximize the terminal vertically
else:
    sys.exit(1)
