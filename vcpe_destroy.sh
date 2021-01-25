#!/bin/bash
# GRUPO 12 - RAUL | VICTOR | ALEJANDRO
# CURSO 2020/21 | RDSV

USAGE="
Usage:
    
vcpe_destroy <vcpe_name> 

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

sudo ovs-docker del-port AccessNet veth0 $VNF1
sudo ovs-docker del-port ExtNet eth2 $VNF2

osm ns-delete $1