#!/bin/sh

# 1 - File
delete_last_line()
{
    head -n -1 $1 > temp.txt ; mv temp.txt $1
}

# 1 - Line, 2 - File
add_to_file()
{
    sudo grep -qF -- "$1" "$2" || echo "$1" >> "$2"
}

# 1 - Package Name
pkg_is_installed()
{
    #Fix package check

    dpkg -s $1 &> /dev/null

    if [ $? -eq 0 ]; then
        echo "Missing dependency, run d_board install"
    else
        echo "$(1) installed."
    fi
}

# 1 - File, 2 - Old Line, 3 - New Line 
replaceappend()
{
    if ! sed -i "/.*$2.*/{s//$3/;h};"'${x;/./{x;q0};x;q1}' $1
    then
        echo "$3" >> $1
    fi
}

#-----------------------------User Commands--------------------------
help()
{
    cat help.txt
}

create_autostart()
{
    #add --force-device-scale-factor=0.5
    #add incognito option

    pkg_is_installed xdotool

    mkdir -p bin

    #Create autostart chromium script
    {
        echo '#Run browser after boot to desktop'
        echo '/bin/sleep 3'
        echo 'sudo -u pi chromium-browser --kiosk --app=' $1 ' &'
    } > bin/autostart_chromium.sh

    sudo chmod +x "bin/autostart_chromium.sh"

    #Create auto refresh script
    {
        echo '#Refresh browser every 90 seconds'
        echo '/bin/sleep 6'
        echo '/usr/bin/lxterminal --command watch -n 90 xdotool key ctrl+F5 &'
    } > bin/start_url_refresh.sh

    sudo chmod +x "bin/start_url_refresh.sh"

    #Create Directory if not exist
    mkdir -p /home/pi/.config/lxsession/LXDE-pi/
    as=/home/pi/.config/lxsession/LXDE-pi/autostart
    touch $as

    add_to_file "@xset s off" $as
    add_to_file "@xset -dpms" $as
    add_to_file "@xset s noblank" $as
    add_to_file "@$(pwd)/bin/autostart_chromium.sh" $as
    add_to_file "@$(pwd)/bin/start_url_refresh.sh" $as
    
    #Comment out xscreensaver line
    sed -i '/@xscreensaver -no-splash/s/^/#/' $as
}

install()
{
    echo This will install packages to your device, continue? [Y/n]
    read response

    if [ $response = "y" ] || [ $response = "Y" ]; then
        echo "Installing Packages."
	    apt-get update
        apt-get install xdotool
    else
        echo "Reverting."
    fi
}

# 1 - New Rotation
set_rotation()
{
    case "$1" in
    0)
        replaceappend /boot/config.txt display_rotate= display_rotate=0
        ;;
    90)
        replaceappend /boot/config.txt display_rotate= display_rotate=1
        ;;
    180)
        replaceappend /boot/config.txt display_rotate= display_rotate=2
        ;;
    270)
        replaceappend /boot/config.txt display_rotate= display_rotate=3
        ;;
    esac
}

connect_wifi()
{
    echo Is this a hidden network? [Y/n]
    read response

    echo Enter the WiFi SSID:
    read ssid

    echo Enter the Wifi Passkey:
    read passkey

    wpa=/etc/wpa_supplicant/wpa_supplicant.conf
    rm -f $wpa
    touch $wpa
    add_to_file "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" $wpa
    add_to_file "update_config=1" $wpa
    add_to_file "country=US" $wpa
    echo "network={" >> $wpa
    echo    ssid=\"$ssid\" >> $wpa
    if [ $response = "y" ] || [ $response = "Y" ]; then
        echo "   scan_ssid=1" >> $wpa
    fi
    echo    psk=\"$passkey\" >> $wpa
    echo "}" >> $wpa
}

change_overscan()
{
	echo If there is a black box around your screen, disable overscan. 
	echo If you cannot see the edges of your display, enable overscan.
	echo Would you like to have overscan enabled?
	read response
	
	#Dual copies with each config to overwrite original.
	osoncfg=/boot/config1.txt
	osoffcfg=/boot/config2.txt
	osorig=/boot/config.txt
	if [ $response = "y" ] || [ $response = "Y" ]; then
		cp $osoncfg $osorig
	else
		cp $osoffcfg $osorig
	fi
}

#---------------------------------------Main---------------------------
main_switch()
{
    case "$1" in
    -h|--help)
        help
        ;;
    autostart)
        create_autostart $2
        ;;
    install)
        install
        ;;
    rotation)
        set_rotation $2
        ;;
    wifi)
        connect_wifi
        ;;
	overscan)
		change_overscan
		;;
    *)
        echo "Remember to enable SSH and change default password. \n Use the -h or --help for help."
        ;;
    esac
}

main_switch $1 $2
