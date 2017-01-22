#!/bin/bash

# Tested on Raspbian Jessie Lite 2016-11-25

# ********************************************************************************************
#
# Script configuration
# EDIT LINES BELOW TO CHANGE THE CONFIG BEFORE INSTALL
#
# ********************************************************************************************

# Install log filename
LOGNAME="bbfone.log"
# Log storage directory (with trailing slash)
LOGPATH="/var/log/"
HOSTNAME="daddy"
# Utilisateur
USERNAME="bbfone"
USERPASS="bbfone"
# WAN (Wide Area Network) interface
WAN_INTERFACE="eth0"
# Keyboard language
KBLANG="fr"
# Control app
CONTROL_ROOT="/var/www/control"
# Bbfone variables
BBFONE_PORT=4000
# Install PhatDAC
INSTALL_PHATDAC=1


# ********************************************************************************************
#
# Helpers
#
# ********************************************************************************************

LOGFILE="$LOGPATH$LOGNAME"
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

check_returned_code() {
    RETURNED_CODE=$@
    if [ $RETURNED_CODE -ne 0 ]; then
        display_message ""
        display_message "Error with latest command, please check log file"
        display_message ""
        exit 1
    fi
}

display_message() {
    MESSAGE=$@
    # Display on console
    echo "** $MESSAGE"
    # Save to log file
    echo "** $MESSAGE" >> $LOGFILE
}

execute_command() {
    display_message "$3"
    COMMAND="$1 >> $LOGFILE 2>&1"
    eval $COMMAND
    COMMAND_RESULT=$?
    if [ "$2" != "false" ]; then
        check_returned_code $COMMAND_RESULT
    fi
}

prepare_logfile() {
    echo "** Preparing log file"
    if [ -f $LOGFILE ]; then
        echo "** Log file already exist. Creating a backup."
        execute_command "mv $LOGFILE $LOGFILE.`date +%Y%m%d.%H%M%S`"
    fi
    echo "** Creating the log file"
    execute_command "touch $LOGFILE"
    display_message "Log file created : $LOGFILE"
    display_message "Use command 'tail -f $LOGFILE' in a new console to get installation details"
}


# ********************************************************************************************
#
# Install start
#
# ********************************************************************************************

prepare_logfile

#*
#* System configuration
#*--------------------------------------------------------------------------------------------

# Update system

execute_command "apt-get update" true "Updating packages list"
execute_command "apt-get install -y --force-yes apt-transport-https" true "Adding HTTPS support for apt-get (Raspbian Lite compatibility)"
execute_command "apt-get upgrade -y --fix-missing" true "Updating all packages"

# Create $USERNAME user (sudoer) and disable pi user
execute_command "grep '$USERNAME' /etc/passwd" false "Checking if $USERNAME user exists"
if [ $COMMAND_RESULT -ne 0 ]; then
    display_message "$USERNAME don t exists"
    execute_command "adduser --disabled-password --gecos \"\" $USERNAME" true "Creating $USERNAME user"
    execute_command "usermod -aG sudo $USERNAME" true "Adding $USERNAME to sudo group"
    execute_command "echo -e \"$USERPASS\n$USERPASS\" | passwd $USERNAME" true "Changing $USERNAME user password"
    execute_command "echo -e \"$USERPASS\n$USERPASS\" | passwd pi" false "Changing pi user password"
    execute_command "passwd pi -l" true "Lock pi user account"
fi

# Create startup script
execute_command "touch /etc/init.d/bbfone" true "Create startup script"
execute_command "chmod 755 /etc/init.d/bbfone" true "Make startup script executable"
display_message "Initializing startup script"
echo -e "#!/bin/sh
### BEGIN INIT INFO
# Provides:          bbfone
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start bbfone receiver services
# Description:       Starts bbfone receiver required services at boot time.
### END INIT INFO
" >> /etc/init.d/bbfone
check_returned_code $?

# Change keyboard to Azerty
execute_command "sed -i '/XKBLAYOUT=\"gb\"/c\XKBLAYOUT=\"$KBLANG\"' /etc/default/keyboard" true "Changing keyboard config"
execute_command "systemctl restart keyboard-setup" true "Reload keyboard service"

# Install PhatDAC
if [ $INSTALL_PHATDAC -eq 1 ]; then
    execute_command "curl -sS get.pimoroni.com/phatdac | bash" true "Installing phatdac"
fi

#*
#* Network configuration
#*--------------------------------------------------------------------------------------------

# Configure network
display_message "Update dhcpcd configuration" # In newer Raspian versions, interface configuration is handled by dhcpcd by default
echo "denyinterfaces $LAN_INTERFACE" >> /etc/dhcpcd.conf
check_returned_code $?

display_message "Update hostname file"
echo "$HOSTNAME" > /etc/hostname
check_returned_code $?

display_message "Update hosts file"
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
check_returned_code $?

display_message "Update interface configuration"
cat > /etc/network/interfaces << EOT
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

auto $WAN_INTERFACE
iface $WAN_INTERFACE inet dhcp
EOT
check_returned_code $?*

execute_command "systemctl restart dhcpcd" true "Restarting dhcpcd service"
execute_command "systemctl restart networking" true "Restarting networking service"
execute_command "ifdown $WAN_INTERFACE" true "Shuting down the WAN interface"
execute_command "ifup $WAN_INTERFACE" true "Activating the WAN interface"

#*
#* Webserver install
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install -y nginx php5-fpm" true "Installing nginx and php"

display_message "Configuring nginx default site"
cat > /etc/nginx/sites-enabled/default << EOT
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root $CONTROL_ROOT;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name _;
    
    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass localhost:9000;
        fastcgi_index index.php;
        charset utf8;
        include fastcgi_params;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
    }
}
EOT
check_returned_code $?

#*
#* bbfone part install
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install -y alsa-tools alsa-utils" true "Installing alsa tools"
execute_command "apt-get install -y gstreamer-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-alsa" true "Installing gstreamer"

execute_command "apt-get install -y python python-alsaaudio" true "Installing python"

execute_command "cp bbfone-receiver.sh /usr/local/bin/bbfone-receiver.sh" true "Copying bbfone shell script to /usr/local/bin"
execute_command "sed -i 's/BBFONE_PORT/$BBFONE_PORT/' /usr/local/bin/bbfone-receiver.sh" true "Updating bbfone shell script : udp port"
execute_command "chmod +x /usr/local/bin/bbfone-receiver.sh" true "Making bbfone shell script executable"

execute_command "cp bbfone-receiver.py /usr/local/bin/bbfone-receiver.py" true "Copying bbfone python script to /usr/local/bin"
execute_command "chmod +x /usr/local/bin/bbfone-receiver.py" true "Making bbfone python script executable"

#*
#* Control page install
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install incron -y --force-yes" true "Adding incron package"

display_message "Allow incron for root"
echo "root" > /etc/incron.allow
check_returned_code $?

execute_command "cp -R $SCRIPTPATH/control-app $CONTROL_ROOT" true "Copying control page files"
execute_command "chown -Rf www-data:www-data $CONTROL_ROOT" true "Changing owner of control page directory"

display_message "Creating incrontab for control page"
echo "$CONTROL_ROOT/shutdown IN_CLOSE_WRITE /usr/local/bin/bbfone-shutdown.sh" > /etc/incron.d/bbfone
echo "$CONTROL_ROOT/reboot IN_CLOSE_WRITE /usr/local/bin/bbfone-reboot.sh" >> /etc/incron.d/bbfone
check_returned_code $?

display_message "Creating script for shutdown listening"
cat > /usr/local/bin/bbfone-shutdown.sh << EOT
#!/bin/sh
halt
EOT

display_message "Creating script for reboot listening"
cat > /usr/local/bin/bbfone-reboot.sh << EOT
#!/bin/sh
reboot
EOT

execute_command "chmod +x /usr/local/bin/bbfone-shutdown.sh" true "Making bbfone shutdown shell script executable"
execute_command "chmod +x /usr/local/bin/bbfone-reboot.sh" true "Making bbfone reboot shell script executable"

#*
#* Finishing startup script
#*--------------------------------------------------------------------------------------------

display_message "Ending startup script"
cat >> /etc/init.d/bbfone << EOT
case "\$1" in
    start)
        # startup action
        bbfone-receiver.sh
    ;;

    stop)
        # shutdown action
    ;;

    *)
        # Help on how to use script if no arg given
        echo 'Usage: /etc/init.d/bbfone {start|stop}'
        exit 1
    ;;
esac
EOT
check_returned_code $?

# End of startup script
display_message "Ending startup script"
echo "exit 0" >> /etc/init.d/bbfone
check_returned_code $?

# Link the startup script
execute_command "update-rc.d bbfone defaults" true "Linking bbfone startup script"

# Last message to display once installation ended successfully
display_message ""
display_message ""
display_message "Congratulation ! You now have your bbfone ready !"
display_message "Reboot now :-)"

