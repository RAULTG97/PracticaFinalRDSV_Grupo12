# PracticaFinalRDSV_Grupo12
Desarrollo de la práctica final de la asignatura RDSV - Curso 2020/2021

PREPARACION ESCENARIO OSM-VNX

PASOS DE INICIO:

	1. Iniciar y enlazar vim-emu con OSM (si no ha sido arrancado)

	2. Crear imagen Docker mediante fichero Dockerfile que se encuentra en el Directorio "vnf-img". Es la imagen que utilizan las VNFs en OSM.

		NOTA: El nombre que se le asigna al imagen debe ser: vnf-img

		Comando para crear imagen: "sudo docker build -t vnf-img ."

    3. Ejecutar init.sh para crear los switches "externos" a OSM: AccessNet y ExtNet

    4. Arrancar los escenarios VNX de la red de residencial (*home*) y del servidor (*server*)

	4. Realizar el proceso de onboarding de los paquetes VNF del escenario en OSM

   	5. Instanciar el servicio para home1 en OSM

		NOTA: El nombre del servicio debe ser "vcpe-1" para que el script se ejecute correctamente

	6. Ejecutar script "vcpe1.sh" para configurar y enlazar el servicio desplegado en OSM con los escenariois VNX

	7. Verificar en los Hosts de home1 (H11, H12) de VNX si han sido asignadas las direcciones IP en interfaz "Eth1" por el servidor DHCP.

	8. Si no poseen direcciones IP, ejecutar en cada Host el comando: dhclient

	9. Verificar conectividad entre Hosts (H11, H12) con el servidor (S1)

    10. Instanciar, configurar y verificar para home2


FINALIZAR ESCENARIO:

	11. Ejecutar vcpe_destroy.sh con parámetro el nombre de servicio que se quiere parar

    12. Parar los escnarios VNX

