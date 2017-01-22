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
HOSTNAME="baby"
# Utilisateur
USERNAME="bbfone"
USERPASS="bbfone"
# WAN (Wide Area Network) interface
WAN_INTERFACE="eth0"
# Keyboard language
KBLANG="fr"


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
# Short-Description: Start bbfone listener services
# Description:       Starts bbfone listener required services at boot time.
### END INIT INFO
" >> /etc/init.d/bbfone
check_returned_code $?

# Change keyboard to Azerty
execute_command "sed -i '/XKBLAYOUT=\"gb\"/c\XKBLAYOUT=\"$KBLANG\"' /etc/default/keyboard" true "Changing keyboard config"
execute_command "systemctl restart keyboard-setup" true "Reload keyboard service"

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

execute_command "apt-get install -y nginx php" true "Installing build tools"

#*
#* bbfone part install
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install -y python git" true "Installing python and git"
execute_command "wget -O ~/get-pip.py https://bootstrap.pypa.io/get-pip.py" true "Downloading get-pip"
execute_command "python ~/get-pip.py" true "Installing get-pip"
execute_command "pip install RPi.GPIO" true "Installing RPi.GPIO"

execute_command "cp bbfone-diffuser.sh /usr/local/bin/bbfone-diffuser.sh" true "Copying bbfone shell script to /usr/local/bin"
execute_command "chmod +x /usr/local/bin/bbfone-diffuser.sh" true "Making bbfone shell script executable"
execute_command "cp bbfone-diffuser.py /usr/local/bin/bbfone-diffuser.py" true "Copying bbfone python script to /usr/local/bin"
execute_command "chmod +x /usr/local/bin/bbfone-diffuser.py" true "Making bbfone python script executable"

#*
#* Finishing startup script
#*--------------------------------------------------------------------------------------------

display_message "Ending startup script"
cat >> /etc/init.d/bbfone << EOT
case "\$1" in
    start)
        # startup action
        bbfone-diffuser.sh
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

