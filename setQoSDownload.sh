#!/bin/bash

USAGE="
Usage:
    
setQoS <vcpe_name> <ip_controller>
    being:
        <vcpe_name>: the name of the network service instance in OSM 
        <ip_controller>: the ip address for the controller
"

if [[ $# -ne 2 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi


VNF1="mn.dc1_$1-1-ubuntu-1"
VNF2="mn.dc1_$1-2-ubuntu-1"
VCPE=$1
IPController="$2"

if [ $VCPE == "vcpe-1" ]
then 
	echo "VCPE-1 QOS DOWNLOAD CONFIGURATION"
	IP1=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h11-ip | grep 192.168.255`
	IP2=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h12-ip | grep 192.168.255`
fi

if [ $VCPE == "vcpe-2" ]
then
	echo "VCPE-2 QOS DOWNLOAD CONFIGURATION"
	IP1=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h21-ip | grep 192.168.255`
	IP2=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h22-ip | grep 192.168.255`
fi


sudo docker exec -it $VNF1 ovs-vsctl set bridge br0 protocols=OpenFlow10,OpenFlow12,OpenFlow13
sudo docker exec -it $VNF1 ovs-vsctl set-fail-mode br0 secure
sudo docker exec -it $VNF1 ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000002
sudo docker exec -it $VNF1 ovs-vsctl set-controller br0 tcp:$IPController:6633
sudo docker exec -it $VNF1 ovs-vsctl set-manager ptcp:6632
sudo docker exec -ti $VNF1 /bin/bash -c "sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' /usr/lib/python3/dist-packages/ryu/app/simple_switch_13.py > qos_simple_switch_13.py"
sudo docker exec -d $VNF1 ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py

#echo "Controlador DOWNLOAD configurado, para iniciarlo acceda a vclass de la red correspondiente y ejecute: "
#echo "ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py"
#echo " "
read -p "Controlador configurado, pulsa cualquier tecla para configurar las reglas de QoS"

#REGLAS SIN PUERTO Y CON PARAMETROS
sudo docker exec -it $VNF1 curl -X PUT -d '"tcp:127.0.0.1:6632"' http://$IPController:8080/v1.0/conf/switches/0000000000000002/ovsdb_addr
sudo docker exec -it $VNF1 curl -X POST -d '{"port_name": "vxlan1", "type": "linux-htb", "max_rate": "12000000", "queues": [{"max_rate": "4000000"}, {"min_rate": "8000000"}]}' http://$IPController:8080/qos/queue/0000000000000002
sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "'$IP1'"}, "actions":{"queue": "1"}}' http://$IPController:8080/qos/rules/0000000000000002
sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "'$IP2'"}, "actions":{"queue": "0"}}' http://$IPController:8080/qos/rules/0000000000000002







#REGLAS CON PUERTO Y SIN PARAMETROS
#sudo docker exec -it $VNF1 curl -X PUT -d '"tcp:127.0.0.1:6632"' http://127.0.0.1:8080/v1.0/conf/switches/0000000000000002/ovsdb_addr 
#sudo docker exec -it $VNF1 curl -X POST -d '{"port_name": "vxlan1", "type": "linux-htb", "max_rate": "12000000", "queues": [{"max_rate": "4000000"}, {"min_rate": "8000000"}]}' http://127.0.0.1:8080/qos/queue/0000000000000002
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.20", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000002
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.21", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "0"}}' http://127.0.0.1:8080/qos/rules/0000000000000002

#REGLAS SIN PUERTO Y SIN PARAMETROS
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.20"}, "actions":{"queue": "1"}}' http://127.0.0.1:8080/qos/rules/0000000000000002
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.21"}, "actions":{"queue": "0"}}' http://127.0.0.1:8080/qos/rules/0000000000000002