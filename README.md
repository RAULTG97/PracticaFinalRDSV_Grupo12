# Practica Final RDSV Grupo12
*Desarrollo de la práctica final de la asignatura RDSV - Curso 2020/2021*
## Autores :
- Raúl Torres García
- Alejandro Vargas Perez
- Victor Loureiro Sancho
------------

## Escenario:
![Escenario](https://github.com/RAULTG97/PracticaFinalRDSV_Grupo12/blob/main/images/PracticaFinalRDSV.png)

------------
## Lo que falta por hacer:
- IPv6: TO DO
- DHCPv6: TO DO

------------
## RECOMENDACIONES PREVIAS
1. Abrir un terminal y ejecutar:
  ```sh
   /lab/rdsv/rdsv-get-and-install-vnxsdnnfvlab
  ```
2. Acceder al directorio compartido y clonar el repositorio, para tenerlo accesible desde la máquina virtual arrancada en virtualbox:
  ```sh
    cd shared
	git clone https://github.com/RAULTG97/PracticaFinalRDSV_Grupo12
  ```
3. Antes de ejecutar ningún script, debemos modificar las imágenes utilizadas por VNX para que incluyan iperf3. Para ello (en la práctica, se pueden probar las colas de QoS con iperf normal):

	3.1. Arrancamos la imagen en modo directo
	  ```sh
   sudo vnx --modify-rootfs /usr/share/vnx/filesystems/vnx_rootfs_lxc_ubuntu64-18.04-v025-vnxlab/
  	```
	3.2. Hacemos login con root/xxxx e instalamos los paquetes deseados
	 ```sh
   sudo apt-get install iperf3
	  ```
	3.3. Paramos el contenedor:
	  ```sh
	   halt -p
 	 ```
------------
## ARRANCAR ESCENARIO
- Ejecutamos el script de creación del escenario:
	 ```sh
	  cd shared/PracticaFinalRDSV_Grupo12
	  ./createScenario.sh
	```

  ------------
## BORRAR ESCENARIO
- Ejecutamos el script de creación del escenario:
  ```sh
  cd shared/PracticaFinalRDSV_Grupo12
  ./destroyScenario.sh nombreInstanciaVCPE
  ```
- Ejemplo:
  ```sh
  ./destroyScenario.sh vcpe-1
  ```

------------
## REQUISITOS
- Utilizar un contenedor VyOS virtualizado como router residencial (vCPE)
- Conectividad IPv4 desde la red residencial hacia Internet. Uso de doble NAT: vCPE y r1 
- Sustituir el switch de vclass por un conmutador controlado por OpenFlow
- Añadir soporte de QoS implementado mediante SDN con Ryu. Gestión de la calidad de servicio en la red de acceso mediante la API REST de Ryu controlando vclass 
	- Para limitar el ancho de banda de bajada hacia la red residencial 
- Despliegue para dos redes residenciales
- Todo automatizado mediante OSM y scripts 
	- Incluyendo el on-boarding de NS/VNFs y la instanciación de NS mediante línea de comandos
- Añadir algunos servicios adicionales
	- Sustituir el switch de brgX por un conmutador controlado por OpenFlow desde el Ryu 
		- Incluyendo la gestión de la calidad de servicio desde Ryu, controlando el brgX, para limitar el ancho de banda de subida desde la red residencial
	- Soporte IPv6
	- DHCP para IPv6


------------
## PASOS SEGUIDOS

1. Modificar ficheros Dockerfile para generar las nuevas imagenes de Docker

	1.1. vnf-vyos basado en el router Vyos:
	
	```sh
	FROM vyos/rolling:1.3 
	RUN mkdir /config 
	CMD /sbin/init
	```
	
	1.2. vnf-img añadimos los nuevos paquetes necesarios:
	
		1.2.1.  Cambiar version a ubuntu:bionic
		1.2.2. Instalamos paquetes ryu-bin, iperf3 e iproute2

2. Cargamos los paquetes del directorio pck en OSM para modificar los descriptores y que utilicen las nuevas imágenes de Docker. Una vez modificados los descriptores, generamos los nuevos paquetes para que en las futuras ejecuciones se haga el onboarding a través de la línea de comandos de OSM.

3. Ejecución del script createScenario.sh por pasos:

	3.1. Iniciamos los OVS de AccessNet y ExtNet (idéntico a init.sh de la practica 4)
	
		sudo ovs-vsctl --if-exists del-br AccessNet
		sudo ovs-vsctl --if-exists del-br ExtNet
		sudo ovs-vsctl add-br AccessNet
		sudo ovs-vsctl add-br ExtNet
		
	3.2. Creamos las imagenes de docker
	
		sudo docker build -t vnf-vyos img/vnf-vyos
		sudo docker build -t vnf-img img/vnf-img
		
	3.3. Onboarding de OSM
	
		osm vnfd-create pck/vnf-vcpe.tar.gz
		osm vnfd-create pck/vnf-vclass.tar.gz
		osm nsd-create pck/ns-vcpe.tar.gz
		osm ns-create --ns_name vcpe-1 --nsd_name vCPE --vim_account emu-vim
		osm ns-create --ns_name vcpe-2 --nsd_name vCPE --vim_account emu-vim
		
	3.4. Arrancar escenarios de VNX
	
		sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
		sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
		
	3.5. Crear VXLAN entre red residencial y VCLASS
	
		Script vcpe_start.sh
		
	3.6. Configuracion de VyOS
	
		Script configureVyOS.sh
		
	3.7. Gestion de la calidad de servicio
	
		Script setQoS.sh
		TO DO!

4. Script vcpe_start.sh

	- Recibe como parametros el nombre de la instancia de vcpe, y las dos direcciones IP del tunel VXLAN a definir
	- Define en vclass dos VXLAN, para comunicarse con la red residencial y con el vcpe
	- Crea eth2 en vcpe VyOS, interfaz para conectarse con ExtNet

5. Script configureVyos.sh

	- Recibe como parametros el nombre de la instancia de vcpe, y las dos direcciones IP router vcpe (privada y publica)
	- Configura la VXLAN entre entre vcpe y vclass
	- Define la interfaz eth2 para conectarse a ExtNet y así poder comunicarse con la red de servidores de VNX e internet
	- Gestiona el servidor DHCP para que los hosts de las redes residenciales puedan obtener direcciones IP en la interfaz eth1 al ejecutar dhclient
	- Se define un SNAT en la eth2
	- Ruta IP por defecto hacia 10.2.3.254 (router r1)

6. Script setQoS.sh
**	TO DO
**
