#!/bin/bash
# GRUPO 12 - RAUL | VICTOR | ALEJANDRO
# CURSO 2020/21 | RDSV

./vcpe_destroy.sh vcpe-1
./vcpe_destroy.sh vcpe-2

sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -P
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -P

sudo ovs-vsctl --if-exists del-br ExtNet 
sudo ovs-vsctl --if-exists del-br AccessNet 