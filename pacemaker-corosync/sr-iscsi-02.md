# Actualizar el sistema
apt update && apt upgrade -y

# Instalar paquetes necesarios para Pacemaker y Corosync
apt install corosync pacemaker pcs resource-agents fence-agents -y

# Limpiar paquetes no necesarios
apt autoremove -y

# Habilitar los servicios de Pacemaker y Corosync
systemctl enable corosync
systemctl enable pacemaker
systemctl enable pcsd

# Cambiar la contraseña del usuario hacluster
echo "hacluster:clúster" | chpasswd
