#!/bin/bash
set -eux

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo "Installing openvpn"
    curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add
    echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" > /etc/apt/sources.list.d/openvpn-aptrepo.list
    apt update
    apt install -y openvpn

    echo ${ca_crt} | base64 -d > /etc/openvpn/ca.crt
    echo ${client_crt} | base64 -d > /etc/openvpn/client.crt
    echo ${client_key} | base64 -d > /etc/openvpn/client.key
    echo ${tls_key} | base64 -d > /etc/openvpn/tls.key

    cat <<EOF > /etc/openvpn/client.conf
client
pull-filter ignore redirect-gateway
dev tun
remote ${host} ${port} ${proto}  
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
ca ca.crt
cert client.crt
key client.key
tls-auth tls.key 1
cipher AES-256-CBC
comp-lzo no
EOF

    service openvpn start client > /dev/null 2>&1
    sleep 5
    
    if ifconfig | grep tun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  darwin*)
    echo "Configuring for Mac OS"

    echo ${ca_crt} | base64 -D -o ca.crt > /dev/null 2>&1
    echo ${client_crt} | base64 -D -o client.crt > /dev/null 2>&1
    echo ${client_key} | base64 -D -o client.key > /dev/null 2>&1

    cat <<EOF > client.conf
client
pull-filter ignore redirect-gateway
dev tun
remote ${host} ${port} ${proto}  
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
ca ca.crt
cert client.crt
key client.key
tls-auth tls.key 1
cipher AES-256-CBC
comp-lzo no
EOF

    sudo openvpn --config client.conf
    sleep 5

    if ifconfig -l | grep utun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
