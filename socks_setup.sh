#!/bin/bash

# Enter the username
username=""
while [[ $username = "" ]]; do
    echo "Enter the proxy username"
    read -p "username: " username
    if [ -z "$username" ]; then
      echo "The username cannot be empty"
    else
        # Check if user already exists.
        grep -wq "$username" /etc/passwd
        if [ $? -eq 0 ]
            then
            echo "User $username already exists"
            username=
        fi
    fi
done

# Enter the proxy user password
password=""
while [[ $password = "" ]]; do
    echo "Enter the proxy password"
    read -p "password: " password
    if [ -z "$password" ]; then
        echo "Password cannot be empty"
    fi
done

# Install  dante-server
apt-get install wget dante-server -y

# determine default int
default_int="$(ip route list |grep default |grep -o -P '\b[a-z]+\d+\b')" #Because net-tools in debian, ubuntu are obsolete already
# determine external ip
external_ip="$(wget ipinfo.io/ip -q -O -)"

# create system user for dante
useradd --shell /usr/sbin/nologin $username && echo "$username:$password" | chpasswd

# dante conf
cat <<EOT > /etc/danted.conf
logoutput: /var/log/socks.log
internal: 0.0.0.0 port = 80
external: $default_int
socksmethod: username
clientmethod: none
user.privileged: root
user.notprivileged: nobody
user.libwrap: nobody
client pass {
        from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
        log: connect disconnect error
}
socks pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        protocol: tcp udp
}
EOT
# And we have a little bit problem with this message from `systemctl status danted.service`
#               danted.service: Failed to read PID from file /var/run/danted.pid: Invalid argument
systemctl restart danted.service

#information
echo "--------------------------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------------------------"
echo "--------------------------------------------------------------------------------------------------"
echo "Proxy IP: $external_ip"
echo "SOCKS5 port: 80"
echo "Username: $username"
echo "Password: $password"
