![image](https://github.com/PENTAGONE-GROUP/loctrac/assets/142556460/bc162688-acd2-4e6c-82f7-0135a60185f4)

# LOCTRAC SOFTWARE DEVELOPEMENT
LOCTRACs Softwares are programs developed by PENTAGONE GROUP 
and created in goal to provide advanced location tracking software.

![image](https://github.com/PENTAGONE-GROUP/loctrac/assets/142556460/64b4aa06-401d-4c84-ba44-d9c7d4bda115)


## PENTAGONE GROUP
software developement institut.

## LOCTRAC SOFTWARE INSTALLATION

LINUX COMPATIBLES DISTROS:
- Kali Linux
- ubuntu
- Debian (untested)

``
apt update && apt upgrade && apt-get install git && apt-get install xdotool && apt-get install gnome-browser-connector && apt-get install x11-utils && apt-get install jq
``

``
git clone https://github.com/PENTAGONE-GROUP/loctrac.git
``

``
cd loctrac | chmod +x main.sh
``

``
./main.sh
``
OR
``
cp main.sh /usr/bin/loctrac && chmod +x /usr/bin/loctrac
``

### SINGLE LINE INSTALLATION
```
clear; echo -e "\e[42mUPDATING...\e[0m" && apt update && apt upgrade && echo -e "\e[42mINSTALLING NECESSARY PACKAGES...\e[0m" && apt-get install git && apt-get install xdotool && apt-get install gnome-browser-connector && apt-get install x11-utils && apt-get install jq && echo -e "\e[42mCLONING REPO...\e[0m" && git clone https://github.com/PENTAGONE-GROUP/loctrac.git && cd loctrac && chmod +x main.sh && echo -e "\e[42mINSTALLATION...\e[0m" && sleep 1 && cp main.sh /usr/bin/loctrac && chmod +x /usr/bin/loctrac && loctrac
```
OR

### WGET INSTALLATION METHOD
```
wget https://trabbit.neocities.org/loctrac/installer.txt && mv installer.txt installer.sh && chmod +x installer.sh && ./installer.sh
```
