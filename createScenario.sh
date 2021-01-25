#!/bin/bash
# GRUPO 12 - RAUL | VICTOR | ALEJANDRO
# CURSO 2020/21 | RDSV

echo "ARRANCANDO ESCENARIO..."


#Switches OVS para AccessNet y ExtNet
sudo ovs-vsctl --if-exists del-br AccessNet
sudo ovs-vsctl --if-exists del-br ExtNet
sudo ovs-vsctl add-br AccessNet
sudo ovs-vsctl add-br ExtNet


#Creamos las imagenes de Docker
#vnf-vyos VyOS
sudo docker build -t vnf-vyos img/vnf-vyos
#vnf-img (Ryu)
sudo docker build -t vnf-img img/vnf-img


#Instalacion de descriptores en OSM
#VNFs
#vcpe vyos
osm vnfd-create pck/vnf-vcpe.tar.gz
#Ryu
osm vnfd-create pck/vnf-vclass.tar.gz
#NS
osm nsd-create pck/ns-vcpe.tar.gz
#Definir NS en OSM:
#Red residencial 1
VCPE1="vcpe-1"
osm ns-create --ns_name $VCPE1 --nsd_name vCPE --vim_account emu-vim
#Red residencial 2
VCPE2="vcpe-2"
osm ns-create --ns_name $VCPE2 --nsd_name vCPE --vim_account emu-vim
echo "OSM Onboarding..."
sleep 10


echo " "
echo "ESCENARIOS DE VNX..."
#LEVANTAR ESCENARIOS VNX
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t

#CONSTANTES
VCPEPRIVIP="192.168.255.1"
VCPEPUBIP1="10.2.3.1"
VCPEPUBIP2="10.2.3.2"
IPController1="10.255.0.1"
IPController2="10.255.0.3"
IPBRG1="10.255.0.2"
IPBRG2="10.255.0.4"


#CREAR VXLANs
echo " "
echo "VXLANs CONFIGURATION..."
./vcpe_start.sh $VCPE1 $IPController1 $IPBRG1 
./vcpe_start.sh $VCPE2 $IPController2 $IPBRG2 


#CONFIGURAR VYOS [NAT Y DHCP]
#Configuracion de tunel VXLAN entre vclass y vcpe (Desde NFV VyOS)
echo " "
echo "VyOS CONFIGURATION..."
./configureVyOS.sh $VCPE1 $VCPEPRIVIP $VCPEPUBIP1
./configureVyOS.sh $VCPE2 $VCPEPRIVIP $VCPEPUBIP2


echo "HOSTS IP CONFIGURATION... DHCLIENT..."
sleep 10
#DHCLIENT PARA LOS 4 HOSTS
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient-h11
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient-h12
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient-h21
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient-h22
#OBTENEMOS LAS IP ASIGNADAS
IPH11=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h11-ip | grep 192.168.255`
IPH12=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h12-ip | grep 192.168.255`
IPH21=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h21-ip | grep 192.168.255`
IPH22=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h22-ip | grep 192.168.255`
echo " "
echo "IPH11 --> $IPH11"
echo " "
echo "IPH12 --> $IPH12"
echo " "
echo "IPH21 --> $IPH21"
echo " "
echo "IPH22 --> $IPH22"
echo " "
echo "IPController1 --> $IPController1"
echo " "
echo "IPController2 --> $IPController2"
echo " "


#IPv6 y DHCP
#TO DO
#DHCLIENT -6 PARA LOS 4 HOSTS
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient6-h11
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient6-h12
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient6-h21
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x dhclient6-h22

#OBTENEMOS LAS IP ASIGNADAS
IPH11v6=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h11-ipv6 | grep 2001`
IPH12v6=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h12-ipv6 | grep 2001`
IPH21v6=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h21-ipv6 | grep 2001`
IPH22v6=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h22-ipv6 | grep 2001`
echo " "
echo "IPH11v6 --> $IPH11v6"
echo " "
echo "IPH12v6 --> $IPH12v6"
echo " "
echo "IPH21v6 --> $IPH21v6"
echo " "
echo "IPH22v6 --> $IPH22v6"
echo " "


#QoS
echo "QoS CONFIGURATION..."
echo "DOWNLOAD..."

#CAUDAL DE DOWNLOAD
echo "DOWNLOAD NET 1..."
./setQoSDownload.sh $VCPE1 $IPController1
echo " "
echo "CONFIGURADAS REGLAS QoS NET 1 DOWNLOAD..."
sleep 5
echo "DOWNLOAD NET 2..."
./setQoSDownload.sh $VCPE2 $IPController2
echo " "
echo "CONFIGURADAS REGLAS QoS NET 2 DOWNLOAD..."
sleep 5

#CAUDAL DE UPLOAD
echo "UPLOAD NET 1..."
./setQoSUpload.sh brg1 $IPBRG1 $IPController1
echo " "
echo "CONFIGURADAS REGLAS QoS NET 1 UPLOAD..."
sleep 5
echo "UPLOAD NET 2..."
./setQoSUpload.sh brg2 $IPBRG2 $IPController2
echo " "
echo "CONFIGURADAS REGLAS QoS NET 2 UPLOAD..."
sleep 5


#QoS UPLOAD CON VNX
#CAUDAL DE UPLOAD
#echo "UPLOAD NET 1..."
#sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x config-QoS-controller-net1
#echo " "
#read -p "Controlador configurado, pulsa cualquier tecla para configurar las reglas de QoS"
#sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x config-QoS-rules-net1
#echo " "
#echo "CONFIGURADAS REGLAS QoS NET 1 UPLOAD..."
#echo "UPLOAD NET 2..."
#sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x config-QoS-controller-net2
#echo " "
#read -p "Controlador configurado, pulsa cualquier tecla para configurar las reglas de QoS"
#sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x config-QoS-rules-net2
#sleep 5
#echo " "
#echo "CONFIGURADAS REGLAS QoS NET 2 UPLOAD..."



echo " "
echo "ESCENARIO LANZADO CORRECTAMENTE, PARA PROBARLO CON IPERF3: "
echo "Servidor: iperf3 -s -i 1"
echo "Cliente:  iperf3 -c direccionIPDestino -b capacidadMaximaCola[M] -l 1200"
echo "Ejemplo: "
echo "Cliente  [ VyOS ] -->  iperf3 -c 192.168.255.20 -b 12M -l 1200 "
echo "Servidor [ h11  ] -->  iperf3 -s -i 1"