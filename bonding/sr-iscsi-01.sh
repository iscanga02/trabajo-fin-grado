# Actualizar el sistema
apt update && apt upgrade -y

# Instalar paquetes necesarios para el bonding
apt install -y ifenslave kmod

# Limpiar paquetes no necesarios
apt autoremove -y

# Agregar el directorio /usr/sbin al PATH
echo 'export PATH=$PATH:/usr/sbin' >> ~/.bashrc
source ~/.bashrc

# Cargar el módulo de bonding
modprobe bonding

# Crear archivo de configuración de la red
cat <<EOF > /etc/network/interfaces
# Cargar configuraciones de interfaces adicionales
source /etc/network/interfaces.d/*

# Interfaz de red loopback
auto lo
iface lo inet loopback

# Configuración para la interfaz virtual bond0 (red de gestión)
auto bond0
iface bond0 inet static
    address 192.168.0.211
    netmask 255.255.255.0
    gateway 192.168.0.1
    bond-slaves enp1s0 enp2s0
    bond-mode active-backup
    bond-miimon 100

# Configuración para la interfaz enp1s0
auto enp1s0
iface enp1s0 inet manual
    bond-master bond0

# Configuración para la interfaz enp2s0
auto enp2s0
iface enp2s0 inet manual
    bond-master bond0

# Configuración para la interfaz virtual bond0:1 (red de clúster)
auto bond0:1
iface bond0:1 inet static
    address 172.16.0.211
    netmask 255.255.255.0
EOF

# Agregar entradas al archivo de hosts con las direcciones IP de los nodos del clúster
cat <<EOF >> /etc/hosts
172.16.0.211 sr-iscsi-01
172.16.0.212 sr-iscsi-02
172.16.0.213 sr-iscsi-03
EOF

# Agregar entradas al archivo de DNS con las direcciones IP de los servidores DNS
cat <<EOF > /etc/resolv.conf
nameserver 193.144.193.11
nameserver 193.144.193.22
nameserver 192.168.202.221
EOF

# Reiniciar el servicio de red
systemctl reboot
