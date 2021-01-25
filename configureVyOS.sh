#!/bin/bash
# GRUPO 12 - RAUL | VICTOR | ALEJANDRO
# CURSO 2020/21 | RDSV

USAGE="
Usage:

configureVyOS <vcpe_name> <vcpe_private_ip> <vcpe_public_ip>
    being:
        <vcpe_name>: the name of the network service instance in OSM 
        <vcpe_private_ip>: the private ip address for the vcpe
        <vcpe_public_ip>: the public ip address for the vcpe (10.2.2.0/24)
"

if [[ $# -ne 3 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi

#VARIABLES
VNF1="mn.dc1_$1-1-ubuntu-1"
VNF2="mn.dc1_$1-2-ubuntu-1"
VCPEPRIVIP="$2"
VCPEPUBIP="$3"
HNAME='vyos'


ETH11=`sudo docker exec -it $VNF1 ifconfig | grep eth1 | awk '{print $1}'`
ETH21=`sudo docker exec -it $VNF2 ifconfig | grep eth1 | awk '{print $1}'`
IP11=`sudo docker exec -it $VNF1 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`
IP21=`sudo docker exec -it $VNF2 hostname -I | awk '{printf "%s\n", $1}{print $2}' | grep 192.168.100`
IPETH0=`sudo docker exec -it mn.dc1_vcpe-1-2-ubuntu-1 hostname -I | tr " " "\n" | grep 172.17.0`

sudo docker exec -ti $VNF2 /bin/bash -c "
sudo sysctl net.ipv6.conf.all.disable_ipv6=0
source /opt/vyatta/etc/functions/script-template
configure
set system host-name $HNAME
set interfaces ethernet eth2 address $VCPEPUBIP/24
set interfaces ethernet eth2 description 'VCPE PUBLIC IP'
set interfaces ethernet eth2 mtu 1400
# IPv4 vxlan1
set interfaces vxlan vxlan1 address $VCPEPRIVIP/24
# IPv6 vxlan1
set interfaces vxlan vxlan1 address 2001:db8::1/64
set interfaces vxlan vxlan1 description 'VXLAN entre vclass OpenFlow y vcpe VyOS'
set interfaces vxlan vxlan1 mtu 1400
set interfaces vxlan vxlan1 ip arp-cache-timeout 180
set interfaces vxlan vxlan1 vni 1
set interfaces vxlan vxlan1 port 8472
set interfaces vxlan vxlan1 remote $IP11
set service ssh port '22'
#DHCPv4 server functionality
set service dhcp-server shared-network-name LAN subnet 192.168.255.0/24 default-router $VCPEPRIVIP
set service dhcp-server shared-network-name LAN subnet 192.168.255.0/24 dns-server $VCPEPRIVIP
set service dhcp-server shared-network-name LAN subnet 192.168.255.0/24 domain-name 'internal-network'
set service dhcp-server shared-network-name LAN subnet 192.168.255.0/24 lease '86400'
set service dhcp-server shared-network-name LAN subnet 192.168.255.0/24 range 0 start 192.168.255.20
set service dhcp-server shared-network-name LAN subnet 192.168.255.0/24 range 0 stop '192.168.255.30'
#DHCPv6 server functionality
set service dhcpv6-server
set service dhcpv6-server preference 0
set service dhcpv6-server shared-network-name LAN6 subnet 2001:db8::/64 address-range start 2001:db8::100 stop 2001:db8::199
set service dhcpv6-server shared-network-name LAN6 subnet 2001:db8::/64 name-server 2001:db8:111::ffff
set service dhcpv6-server shared-network-name LAN6 subnet 2001:db8::/64 nis-server 2001:db8:111::ffff
set nat source rule 100 outbound-interface eth2
set nat source rule 100 source address '192.168.255.0/24'
set nat source rule 100 translation address masquerade
set protocols static route 0.0.0.0/0 next-hop 10.2.3.254 distance '1'
set interfaces ethernet eth0 disable
commit
save
exit
"

#PODEMOS CONFIGURAR DHCP PARA ASIGNAR DIRECCIONES ESTATICAS EN FUNCION DE LA MAC DEL HOST (VER  DOCUMENTACION DE VYOS)
#HEMOS UTILIZADO UN PLANTEAMIENTO BASADO EN VNX, PARA OBTENER LAS DIRECCIONES IP ASIGNADAS A LOS HOSTS

#set service dns forwarding cache-size '0'
#set service dns forwarding listen-on 'vxlan1'
#set service dns forwarding name-server '8.8.8.8'
#set service dns forwarding name-server '8.8.4.4'
#set service dns forwarding listen-address '192.168.255.1'
#set service dns forwarding allow-from '192.168.255.0/24'

#set protocols static route 10.2.3.0/24 next-hop $VCPEPUBIP distance '1'
#set protocols static route 172.17.0.0/16 next-hop $IPETH0 distance '1'
#set protocols static route 192.168.100.0/24 next-hop $IP21 distance '1'
#set protocols static route 192.168.255.0/24 next-hop $VCPEPRIVIP distance '1'
#set protocols static route 10.2.2.0/24 next-hop 10.2.3.254 distance 1
