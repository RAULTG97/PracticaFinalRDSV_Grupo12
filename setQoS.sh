#!/bin/bash

USAGE="
Usage:
    
setQoS <vcpe_name>
    being:
        <vcpe_name>: the name of the network service instance in OSM 
"

if [[ $# -ne 1 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi



VNF1="mn.dc1_$1-1-ubuntu-1"
VNF2="mn.dc1_$1-2-ubuntu-1"

#VARIABLE PARA UTILIZAR UN UNICO CONTROLLER [EN PRINCIPIO NO SE UTILIZA]
#UNA ALTERNATIVA A ESTO ES UTILIZAR UN DHCP QUE ASIGNE DIRECCIONES ESTATICAS (VER VYOS)
IPVCLASSETH0=`sudo docker exec -it $VNF1 hostname -I | tr " " "\n" | grep 172.17.0`
#DIRECCIONES IP ASIGNADAS A LOS HOSTS
IPH11=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h11-ip | grep 192.168.255`
IPH12=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h12-ip | grep 192.168.255`
IPH21=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h21-ip | grep 192.168.255`
IPH22=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h22-ip | grep 192.168.255`


sudo docker exec -it $VNF1 sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' /usr/lib/python3/dist-packages/ryu/app/simple_switch_13.py > qos_simple_switch_13.py
sudo docker exec -it $VNF1 ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py
sudo docker exec -it $VNF1 ovs-vsctl set bridge br0 protocols=OpenFlow10,OpenFlow12,OpenFlow13
sudo docker exec -it $VNF1 ovs-vsctl set-fail-mode br0 secure
sudo docker exec -it $VNF1 ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000002
sudo docker exec -it $VNF1 ovs-vsctl set-controller br0 tcp:127.0.0.1:6633
sudo docker exec -it $VNF1 ovs-vsctl set-manager ptcp:6632


#DEFINIR VARIAS REGLAS, CON UN PUERTO, SIN PUERTO, SIN PROTOCOLO....
#CAUDAL DE BAJADA
#OBTENER LAS DIRECCIONES IP Y PASARLAS COMO PARAMETROS (SWITCHES Y HOSTS)
sudo docker exec -it $VNF1 curl -X PUT -d '"tcp:127.0.0.1:6632"' http://127.0.0.1:8080/v1.0/conf/switches/0000000000000002/ovsdb_addr 
sudo docker exec -it $VNF1 curl -X POST -d '{"port_name": "vxlan1", "type": "linux-htb", "max_rate": "12000000", "queues": [{"max_rate": "4000000"}, {"min_rate": "8000000"}]}' http://127.0.0.1:8080/qos/queue/0000000000000002
sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.20", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000002
sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.21", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "0"}}' http://127.0.0.1:8080/qos/rules/0000000000000002
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.20"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000002
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.21"}, "actions":{"queue": "0"}}' http://127.0.0.1:8080/qos/rules/0000000000000002


#CAUDAL DE SE SUBIDA - ESTOY HAY QUE LLEVARLO A LA PARTE DE VNX DEL BRGX
#curl -X PUT -d '"tcp:172.17.0.2:6632"' http://172.17.2.100:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr 
#curl -X POST -d '{"port_name": "eth1", "type": "linux-htb", "max_rate": "6000000", "queues": [{"max_rate": "2000000"}, {"min_rate": "4000000"}]}' http://172.17.2.100:8080/qos/queue/0000000000000001 
#curl -X POST -d '{"match": {"nw_src": "192.168.255.20", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "1"}}' http://172.17.2.100:8080/qos/rules/0000000000000001 
#curl -X POST -d '{"match": {"nw_src": "192.168.255.21", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "0"}}' http://172.17.2.100:8080/qos/rules/0000000000000001