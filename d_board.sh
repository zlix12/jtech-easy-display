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
    dpkg -s $1 &> /dev/null

    if [ $? -eq 0 ]; then
        echo "Missing dependency, run d_board install"
    else
        echo "$(1) installed."
    fi
}

#-----------------------------User Commands--------------------------
help()
{
    echo "This is help"
}

create_autostart()
{
    pkg_is_installed xdotool

    #Create autostart chromium script
    {
        echo '#Run browser after boot to desktop'
        echo '/bin/sleep 3'
        echo 'sudo -u pi chromium-browser --kiosk --incognito ' $1 ' &'
    } > autostart_chromium.sh

    sudo chmod +x "autostart_chromium.sh"

    #Create auto refresh script
    {
        echo '#Refresh browser every 90 seconds'
        echo '/bin/sleep 6'
        echo '/usr/bin/lxterminal --command watch -n 90 xdotool key ctrl+F5 &'
    } > start_url_refresh.sh

    sudo chmod +x "start_url_refresh.sh"

    as=/home/pi/.config/lxsession/LXDE-pi/autostart

    add_to_file "@xset s off" $as
    add_to_file "@xset -dpms" $as
    add_to_file "@xset s noblank" $as
    add_to_file "@$(pwd)/autostart_chromium.sh" $as
    add_to_file "@$(pwd)/start_url_refresh.sh" $as
    
    #Comment out xscreensaver line
    sed -i '/@xscreensaver -no-splash/s/^/#/' $as
}

install()
{
    echo This will install packages to your device, continue? y or n
    read response

    if [ $response = "y" ]; then
        echo "Installing Packages."
	    apt-get update
        apt-get install xdotool
    else
        echo "Reverting."
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
    *)
        echo "Remember to enable SSH and change default password. \n Use the -h or --help for help."
        ;;
    esac
}

main_switch $1 $2