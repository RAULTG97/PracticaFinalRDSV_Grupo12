#!/bin/bash
#COMANDOS UTILES

# check if the emulator is running in the container
docker exec vim-emu vim-emu datacenter list

# list vims
osm vim-list

# You can now check OSM's Launchpad to see the VNFs and NS in the catalog. Or:
osm vnfd-list

osm nsd-list

osm vnf-list

osm ns-list

docker exec vim-emu vim-emu compute list

# connect to ping VNF container:
docker exec -it mn.dc1_test-nsi.ping.1.ubuntu /bin/bash

VNF1="mn.dc1_$VCPE1-1-ubuntu-1"
VNF2="mn.dc1_$VCPE1-2-ubuntu-1"
VNF3="mn.dc1_$VCPE2-1-ubuntu-1"
VNF4="mn.dc1_$VCPE2-2-ubuntu-1"

VCPE-1-VCLASS
sudo docker exec -it mn.dc1_vcpe-1-1-ubuntu-1 /bin/bash
VCPE-1-VYOS
sudo docker exec -it mn.dc1_vcpe-1-2-ubuntu-1 /bin/bash
VCPE-2-VCLASS
sudo docker exec -it mn.dc1_vcpe-2-1-ubuntu-1 /bin/bash
VCPE-2-VYOS
sudo docker exec -it mn.dc1_vcpe-2-2-ubuntu-1 /bin/bash