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

# Autenticar los nodos del clúster
pcs host auth sr-iscsi-01 sr-iscsi-02 sr-iscsi-03 -u hacluster -p clúster

# Configurar el clúster
pcs clúster setup mycluster sr-iscsi-01 addr=172.16.0.211 sr-iscsi-02 addr=172.16.0.212 sr-iscsi-03 addr=172.16.0.213 --force

# Iniciar el clúster
pcs clúster start --all

# Habilitar el clúster en el arranque
pcs clúster enable --all

# Deshabiliar el fence
pcs property set stonith-enabled=false

# Configurar la política de quórum
pcs property set no-quorum-policy=stop
