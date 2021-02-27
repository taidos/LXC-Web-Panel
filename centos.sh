#!/bin/bash
echo ' _     __   _______  __          __  _       _____                 _ '
echo '| |    \ \ / / ____| \ \        / / | |     |  __ \               | |'
echo '| |     \ V / |       \ \  /\  / /__| |__   | |__) |_ _ _ __   ___| |'
echo "| |      > <| |        \ \/  \/ / _ \ '_ \  |  ___/ _\` | '_ \ / _ \ |"
echo '| |____ / . \ |____     \  /\  /  __/ |_) | | |  | (_| | | | |  __/ |'
echo '|______/_/ \_\_____|     \/  \/ \___|_.__/  |_|   \__,_|_| |_|\___|_|'
echo -e '\n\nAutomatic installer for CentOS\n'

if [[ "$UID" -ne "0" ]];then
        echo 'You must be root to install LXC Web Panel !'
        exit
fi

### BEGIN PROGRAM

INSTALL_DIR='/srv/lwp'

if [[ -d "$INSTALL_DIR" ]];then
        echo "You already have LXC Web Panel installed. You'll need to remove $INSTALL_DIR if you want to install"
        exit 1
fi

echo 'Installing requirement...'

yum -y update &> /dev/null

hash python &> /dev/null || {
        echo '+ Installing Python'
       yum install -y python > /dev/null
}

hash pip &> /dev/null || {
        echo '+ Installing Python pip'
       yum install -y python-pip > /dev/null
}

python -c 'import flask' &> /dev/null || {
        echo '| + Flask Python...'
       pip install flask==0.9 > /dev/null
       pip install "Werkzeug==0.16.1" > /dev/null
}


hash git &> /dev/null || {
        echo '+ Installing Git and Screen'
       yum install -y git screen > /dev/null
}

echo 'Cloning LXC Web Panel...'
git clone -b 0.2 https://github.com/lxc-webpanel/LXC-Web-Panel.git "$INSTALL_DIR"

echo -e '\nInstallation complete!\n\n'


echo 'Adding /etc/init.d/lwp...'

cat > '/etc/init.d/lwp' <<EOF
#!/bin/bash
# Copyright (c) 2013 LXC Web Panel
# All rights reserved.
#
# Author: Elie Deloumeau
# Editor: Carlos Faustino
#
# /etc/init.d/lwp
#
### BEGIN INIT INFO
# Provides: lwp
# Required-Start: $local_fs $network
# Required-Stop: $local_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: LWP Start script
### END INIT INFO


WORK_DIR="/srv/lwp"
SCRIPT="lwp.py"
DAEMON="/usr/bin/python $SCRIPT"
PIDFILE="/var/run/lwp.pid"
USER="root"

function start () {
        echo -n 'Starting server...'
        screen -dm bash -c 'cd $WORK_DIR; python $WORK_DIR/$SCRIPT'
        echo 'done.'
        }

function stop () {
        echo -n 'Stopping server...'
        kill -9 $(screen -ls | awk '/[0-9]{1,}\./ {print strtonum($1)}'); screen -wipe
        echo 'done.'
}


case "$1" in
        'start')
                start
                ;;
        'stop')
                stop
                ;;
        'restart')
                stop
                start
                ;;
        *)
                echo 'Usage: /etc/init.d/lwp {start|stop|restart}'
                exit 0
                ;;
esac

exit 0
EOF

mkdir -p /etc/lxc/auto
chmod +x '/etc/init.d/lwp'
update-rc.d lwp defaults &> /dev/null
echo 'Done'
#/etc/init.d/lwp start
python /srv/lwp/lwp.py &
echo 'Connect you on http://your-ip-address:5000/'
