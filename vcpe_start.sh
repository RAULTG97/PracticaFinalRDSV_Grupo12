#!/bin/bash

USAGE="
Usage:
    
vcpe_start <vcpe_name> <vnf_tunnel_ip> <home_tunnel_ip> <ip_controller>
    being:
        <vcpe_name>: the name of the network service instance in OSM 
        <vnf_tunnel_ip>: the ip address for the vnf side of the tunnel
        <home_tunnel_ip>: the ip address for the home side of the tunnel
        <ip_controller>: the ip address for the controller 
"

if [[ $# -ne 4 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi

VNF1="mn.dc1_$1-1-ubuntu-1"
VNF2="mn.dc1_$1-2-ubuntu-1"

VNFTUNIP="$2"
HOMETUNIP="$3"
IPController="$4"


ETH11=`sudo docker exec -it $VNF1 ifconfig | grep eth1 | awk '{print $1}' | tr -d ':'`
ETH21=`sudo docker exec -it $VNF2 ifconfig | grep eth1 | awk '{print $1}' | tr -d ':'`
IP11=`sudo docker exec -it $VNF1 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`
IP21=`sudo docker exec -it $VNF2 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`

##################### VNFs Settings #####################
## 0. Iniciar el Servicio OpenVirtualSwitch en cada VNF:
echo "--"
echo "--OVS Starting..."
sudo docker exec -it $VNF1 /usr/share/openvswitch/scripts/ovs-ctl start

echo "--"
echo "--Connecting vCPE service with AccessNet and ExtNet..."

sudo ovs-docker add-port AccessNet veth0 $VNF1
sudo ovs-docker add-port QoS eth2 $VNF1
sudo ovs-docker add-port ExtNet eth2 $VNF2
sudo docker exec -it $VNF1 ifconfig eth2 $IPController/24

echo "--"
echo "--Setting VNF..."
echo "--"
echo "--Bridge Creating..."

##En VNF:vclass agregar un bridge y asociar interfaces.
sudo docker exec -it $VNF1 ovs-vsctl add-br br0
sudo docker exec -it $VNF1 ifconfig veth0 $VNFTUNIP/24
sudo docker exec -it $VNF1 ip link add vxlan1 type vxlan id 0 remote $HOMETUNIP dstport 4789 dev veth0
sudo docker exec -it $VNF1 ip link add vxlan2 type vxlan id 1 remote $IP21 dstport 8472 dev $ETH11
sudo docker exec -it $VNF1 ovs-vsctl add-port br0 vxlan1
sudo docker exec -it $VNF1 ovs-vsctl add-port br0 vxlan2
sudo docker exec -it $VNF1 ifconfig vxlan1 up
sudo docker exec -it $VNF1 ifconfig vxlan2 up