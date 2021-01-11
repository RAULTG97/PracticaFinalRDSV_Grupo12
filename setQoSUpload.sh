#!/bin/bash

USAGE="
Usage:
    
setQoSUpload <brgX_name>
    being:
        <brgX_name>: brg1(homeNet1) or brg2(homeNet2)
"

if [[ $# -ne 1 ]]; then
        echo ""       
    echo "ERROR: incorrect number of parameters"
    echo "$USAGE"
    exit 1
fi


BRGX="$1"

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

sudo lxc-attach --clear-env -n $BRGX -- bash -c "sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' /usr/lib/python3/dist-packages/ryu/app/simple_switch_13.py > qos_simple_switch_13.py"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py &"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set bridge br0 protocols=OpenFlow10,OpenFlow12,OpenFlow13"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set-fail-mode br0 secure"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000001"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set-controller br0 tcp:127.0.0.1:6633"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "ovs-vsctl set-manager ptcp:6632"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X PUT -d '\"tcp:127.0.0.1:6632\"' http://127.0.0.1:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"port_name\": \"vxlan1\", \"type\": \"linux-htb\", \"max_rate\": \"6000000\", \"queues\": [{\"max_rate\": \"2000000\"}, {\"min_rate\": \"2000000\"}]}' http://127.0.0.1:8080/qos/queue/0000000000000001" 
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"match\": {\"nw_src\": \"192.168.255.20\", \"nw_proto\": \"UDP\", \"udp_dst\": \"5002\"}, \"actions\":{\"queue\": \"1\"}}' http://127.0.0.1:8080/qos/rules/0000000000000001"
sudo lxc-attach --clear-env -n $BRGX -- bash -c "curl -X POST -d '{\"match\": {\"nw_src\": \"192.168.255.21\", \"nw_proto\": \"UDP\", \"udp_dst\": \"5002\"}, \"actions\":{\"queue\": \"0\"}}' http://127.0.0.1:8080/qos/rules/0000000000000001"