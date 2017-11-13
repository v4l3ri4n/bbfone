#!/bin/bash

# Tested on Raspbian Jessie Lite 2016-11-25
# Tested on Raspbian Jessie Lite 2017-01-11
# Tested on Raspbian Jessie Lite 2017-07-05

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
HOSTNAME_DIFFUSER="baby"
HOSTNAME_RECEIVER="daddy"
# Utilisateur
USERNAME="bbfone"
USERPASS="bbfone"
# WAN (Wide Area Network) interface
WAN_INTERFACE="eth0"
# Keyboard language
KBLANG="fr"
# Control app
NODEAPP_ROOT="/var/www/bbfone"
# Bbfone variables
BBFONE_PORT=4000
BBFONE_RECEIVER="daddy.local"
BBFONE_DIFFUSER="baby.local"

read -p 'Install diffuser or receiver d/r ? ' -n 1 INSTALL_TYPE

if [ $INSTALL_TYPE == "r" ] || [ $INSTALL_TYPE == "R" ] ; then
    INSTALL_TYPE="R"
    HOSTNAME=$HOSTNAME_RECEIVER
    # Install PhatDAC
    INSTALL_PHATDAC=1
else
    HOSTNAME=$HOSTNAME_DIFFUSER
    INSTALL_PHATDAC=0
fi


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

# Install PhatDAC
if [ $INSTALL_PHATDAC -eq 1 ]; then
    display_message "Installing phatdac"
    curl -sS get.pimoroni.com/phatdac | bash
    
    if [ $? -ne 0 ]; then
        display_message ""
        display_message "Phatdac not installed, you may need to run the phatdac installer manually"
        display_message ""
    fi
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
check_returned_code $?

execute_command "systemctl restart dhcpcd" true "Restarting dhcpcd service"
execute_command "systemctl restart networking" true "Restarting networking service"
execute_command "ifdown $WAN_INTERFACE" true "Shuting down the WAN interface"
execute_command "ifup $WAN_INTERFACE" true "Activating the WAN interface"

#*
#* Node.js install
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install -y build-essential" true "Installing build tools"

# form pi 2
if $(uname -m | grep -Eq ^armv6); then
    execute_command "wget https://nodejs.org/dist/v6.9.4/node-v6.9.4-linux-armv6l.tar.xz -O ~/node.tar.xz" true "Downloading nodejs tarball"
    execute_command "cd /usr/local" true "Changing working dir to /usr/local"
    execute_command "tar --strip-components 1 -xvf ~/node.tar.xz" true "Decompressing nodejs tarball"
    execute_command "cd $SCRIPTPATH" true "Changing working dir to install script dir"
else
    execute_command "curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -" true "Prepare node.js install"
    execute_command "apt-get install -y nodejs" true "Installing node.js"
fi

execute_command "npm install pm2 -g" true "Installing PM2"

execute_command "usermod -a -G gpio root" true "Adding root user to gpio group"

display_message "Configuring udev"
cat >/etc/udev/rules.d/20-gpiomem.rules <<EOF
SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
EOF
check_returned_code $?

#*
#* audio and streaming tools
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install -y alsa-tools alsa-utils" true "Installing alsa tools"
execute_command "apt-get install -y gstreamer-tools gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly gstreamer0.10-alsa" true "Installing gstreamer"

#*
#* bbfone start script
#*--------------------------------------------------------------------------------------------

if [ $INSTALL_TYPE == "R" ] ; then
#---------RECEIVER--------------
display_message "Creating bbfone start script"
cat > /usr/local/bin/bbfone-start.sh << EOT
#!/bin/sh
cd $NODEAPP_ROOT
pm2 start receiver.js
EOT
    
display_message "Adding sound control with softvol alsa plugin"

cat > /etc/asound.conf << EOT
pcm.!default {
    type plug
    slave.pcm "softvol"
}
ctl.!default {
    type hw
    card 0
}
pcm.softvol {
    type softvol
    slave.pcm "sysdefault"
    control.name "Softmaster"
    control.card 0
}
EOT

check_returned_code $?

execute_command "speaker-test -Dsoftvol -c2 -twav -l2" true "Testing sound control to store it"

    # TO REMOVE ASOUND CONF :
    #rm /var/lib/alsa/asound.state # remove the state file
    #chmod -x /usr/sbin/alsactl # make alsactl non-executable to prevent settings being written on shutdown
    #<REBOOT>
    #chmod +x /usr/sbin/alsactl
else
#---------DIFFUSER-------------
display_message "Creating bbfone start script"
cat > /usr/local/bin/bbfone-start.sh << EOT
#!/bin/sh
cd $NODEAPP_ROOT
pm2 start diffuser.js
EOT
fi

execute_command "chmod +x /usr/local/bin/bbfone-start.sh" true "Making bbfone shell script executable"
    
#*
#* Node.js app install
#*--------------------------------------------------------------------------------------------

execute_command "apt-get install incron -y --force-yes" true "Adding incron package"

display_message "Allow incron for root"
echo "root" > /etc/incron.allow
check_returned_code $?

NUMOFFIELDS=$(echo $NODEAPP_ROOT | grep -o / | wc -l)
PATHTOCREATE=$(echo $NODEAPP_ROOT | cut -d / -f -$NUMOFFIELDS)
execute_command "mkdir -p $PATHTOCREATE" true "Creating node app parent dir"
execute_command "cp -R $SCRIPTPATH/node-app $NODEAPP_ROOT" true "Copying node app files"
#execute_command "chown -Rf www-data:www-data $NODEAPP_ROOT" true "Changing owner of node app directory"
execute_command "cd $NODEAPP_ROOT"
execute_command "npm install" true "Installing npm packages"
execute_command "cd $SCRIPTPATH"

display_message "Creating incrontab for node app"
echo "$NODEAPP_ROOT/commands/shutdown IN_CLOSE_WRITE /usr/local/bin/bbfone-shutdown.sh" > /etc/incron.d/bbfone
echo "$NODEAPP_ROOT/commands/reboot IN_CLOSE_WRITE /usr/local/bin/bbfone-reboot.sh" >> /etc/incron.d/bbfone

if [ $INSTALL_TYPE == "R" ] ; then
    echo "$NODEAPP_ROOT/commands/stream-play IN_CLOSE_WRITE /usr/local/bin/bbfone-stream-play.sh" >> /etc/incron.d/bbfone
    echo "$NODEAPP_ROOT/commands/volume IN_CLOSE_WRITE /usr/local/bin/bbfone-volume.sh" >> /etc/incron.d/bbfone
    execute_command "sed -i 's/BBFONE_DIFFUSER/$BBFONE_DIFFUSER/' $NODEAPP_ROOT/receiver.js" true "Updating bbfone diffuser host"
else
    echo "$NODEAPP_ROOT/commands/stream-emit IN_CLOSE_WRITE /usr/local/bin/bbfone-stream-emit.sh" >> /etc/incron.d/bbfone
fi
check_returned_code $?

#---------SHUTDOWN AND REBOOT -------------

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

#---------STREAM PLAY-------------

if [ $INSTALL_TYPE == "R" ] ; then
display_message "Creating script for streaming play"
cat > /usr/local/bin/bbfone-stream-play.sh << EOT
#!/bin/bash

PORT=$BBFONE_PORT
VOLUME=\$(cat $NODEAPP_ROOT/commands/volume)

# on start, set volume
if [ -n \$VOLUME ]; then
    amixer sset Softmaster \$VOLUME\%
fi

killall -9 gst-launch
nohup gst-launch -v udpsrc port=\$PORT ! audio/x-opus, multistream=false ! opusdec ! audioconvert ! rgvolume pre-amp=60 ! audioconvert ! autoaudiosink &
EOT
execute_command "chmod +x /usr/local/bin/bbfone-stream-play.sh" true "Making bbfone stream-play shell script executable"
fi

#---------VOLUME-------------

if [ $INSTALL_TYPE == "R" ] ; then
display_message "Creating script for volume"
cat > /usr/local/bin/bbfone-volume.sh << EOT
#!/bin/bash

VOLUME=\$(cat $NODEAPP_ROOT/commands/volume)

if [ -n \$VOLUME ]; then
    amixer sset Softmaster \$VOLUME\%
fi
EOT
execute_command "chmod +x /usr/local/bin/bbfone-volume.sh" true "Making bbfone volume shell script executable"
fi

#---------STREAM EMIT-------------

if [ $INSTALL_TYPE != "R" ] ; then
display_message "Creating script for streaming emitter"
cat > /usr/local/bin/bbfone-stream-emit.sh << EOT
#!/bin/bash

DEVICE="hw:1,0" # sound card
PORT=$BBFONE_PORT
RECEIVER="$BBFONE_RECEIVER"

# launch gst-launch in background
killall -9 gst-launch
gst-launch -v gstrtpbin alsasrc device="\$DEVICE" ! opusenc audio=false ! udpsink port=\$PORT host="\$RECEIVER" &
EOT
execute_command "chmod +x /usr/local/bin/bbfone-stream-emit.sh" true "Making bbfone stream-emit shell script executable"
fi

#*
#* Finishing startup script
#*--------------------------------------------------------------------------------------------

display_message "Ending startup script"
cat >> /etc/init.d/bbfone << EOT
case "\$1" in
    start)
        # startup action
        bbfone-start.sh
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




