#!/bin/bash
# GRUPO 12 - RAUL | VICTOR | ALEJANDRO
# CURSO 2020/21 | RDSV

USAGE="
Usage:
    
setQoSUpload <brgX_name> <ip-bridge> <ip_controller>
    being:
        <brgX_name>: brg1(homeNet1) or brg2(homeNet2)
        <ip_bridge>: the ip address for the bridge
        <ip_controller>: the ip address for the controller
"

if [[ $# -ne 3 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi


BRGX="$1"
IPBridge="$2"
IPController="$3"


if [ $BRGX == "brg1" ]
then 
	echo "VCPE-1 QOS UPLOAD CONFIGURATION"
	IP1=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h11-ip | grep 192.168.255`
	IP2=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h12-ip | grep 192.168.255`
fi

if [ $BRGX == "brg2" ]
then
	echo "VCPE-2 QOS UPLOAD CONFIGURATION"
	IP1=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h21-ip | grep 192.168.255`
	IP2=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h22-ip | grep 192.168.255`
fi

sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set bridge br0 protocols=OpenFlow10,OpenFlow12,OpenFlow13"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set-fail-mode br0 secure"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000001"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set-controller br0 tcp:$IPController:6633"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set-manager ptcp:6632"

echo " "
read -p "Controlador configurado, pulsa INTRO para configurar las reglas de QoS"

sleep 2
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X PUT -d '\"tcp:$IPBridge:6632\"' http://$IPController:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr"
sleep 2
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"port_name\": \"vxlan1\", \"type\": \"linux-htb\", \"max_rate\": \"6000000\", \"queues\": [{\"max_rate\": \"2000000\"}, {\"min_rate\": \"2000000\"}]}' http://$IPController:8080/qos/queue/0000000000000001" 
sleep 2
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"match\": {\"nw_src\": \"$IP1\"}, \"actions\":{\"queue\": \"1\"}}' http://$IPController:8080/qos/rules/0000000000000001"
sleep 2
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"match\": {\"nw_src\": \"$IP2\"}, \"actions\":{\"queue\": \"0\"}}' http://$IPController:8080/qos/rules/0000000000000001"


#BACKUP
#sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"match\": {\"nw_src\": \"192.168.255.20\"}, \"actions\":{\"queue\": \"1\"}}' http://127.0.0.1:8080/qos/rules/0000000000000001"
#sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"match\": {\"nw_src\": \"192.168.255.21\"}, \"actions\":{\"queue\": \"0\"}}' http://127.0.0.1:8080/qos/rules/0000000000000001"

#CAUDAL DE SE SUBIDA - codigo de ejemplo
#curl -X PUT -d '"tcp:172.17.0.2:6632"' http://172.17.2.100:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr 
#curl -X POST -d '{"port_name": "eth1", "type": "linux-htb", "max_rate": "6000000", "queues": [{"max_rate": "2000000"}, {"min_rate": "4000000"}]}' http://172.17.2.100:8080/qos/queue/0000000000000001 
#curl -X POST -d '{"match": {"nw_src": "192.168.255.20", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "1"}}' http://172.17.2.100:8080/qos/rules/0000000000000001 
#curl -X POST -d '{"match": {"nw_src": "192.168.255.21", "nw_proto": "UDP", "udp_dst": "5002"}, "actions":{"queue": "0"}}' http://172.17.2.100:8080/qos/rules/0000000000000001