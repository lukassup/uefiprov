#!/usr/bin/env bash
sudo sysctl -w net.inet.ip.forwarding=1
#sudo sysctl -w net.inet6.ip6.forwarding=1
sudo ipconfig set bridge100 MANUAL 192.168.122.1
sudo pfctl -F nat
echo 'nat on en0 from 192.168.122.0/24 to any -> en0' | sudo pfctl -f -
#sudo pfctl -s nat
