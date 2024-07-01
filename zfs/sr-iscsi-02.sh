# Obtener el codename de la distribución
codename=$(lsb_release -cs)

# Comprobar si el repositorio backports ya está en sources.list
if ! grep -q "^deb .*${codename}-backports" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian $codename-backports main contrib non-free" | tee -a /etc/apt/sources.list
fi

# Actualizar el sistema
apt update && apt upgrade -y

# Instalar encabezados del kernel
apt install linux-headers-$(uname -r) -y

# Instalar paquetes necesarios para ZFS
apt install -t stable-backports zfsutils-linux -y

# Limpiar paquetes no necesarios
apt autoremove -y

# Listar los discos disponibles
lsblk

# Crear un pool de almacenamiento con los discos /dev/sdb y /dev/sdc
zpool create tank mirror /dev/sdb /dev/sdc -f

# Listar los pools de almacenamiento
zpool list

# Verificar el estado del pool
zpool status tank

# Crear un volumen ZFS en modo sparse que ocupe todo el espacio disponible
free_space=$(zpool list -H -o free tank | awk '{print $1}')
zfs create -s -V $free_space tank/zvol
