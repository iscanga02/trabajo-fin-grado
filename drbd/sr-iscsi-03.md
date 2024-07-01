# Actualizar el sistema
apt update && apt upgrade -y

# Instalar paquetes necesarios para la compilación del módulo kernel de DRBD
apt install automake build-essential wget -y

# Instalar paquetes necesarios para la utilería de DRBD (drbdadm)
apt install drbd-utils -y

# Compilar la versión 9.2.5 de DRBD (kernel module)
ver=9.2.5
wget https://pkg.linbit.com//downloads/drbd/9/drbd-$ver.tar.gz
tar xzf drbd-$ver.tar.gz
cd drbd-$ver/drbd/
make distclean
make clean
echo $MAKEFLAGS
make > ../../drbd.log && echo BUILT
make install >/dev/null && echo DEPLOYED
depmod -a

# Limpiar paquetes no necesarios
apt autoremove -y

# Comprobar el módulo kernel de DRBD
modinfo drbd

# Crear un recurso DRBD
cat <<EOF > /etc/drbd.d/r0.res
resource r0 {
  protocol C;
  device    /dev/drbd0;
  disk      /dev/zvol/tank/zvol;
  meta-disk internal;

  on sr-iscsi-01 {
    address 172.16.0.211:7789;
    node-id 1;
  }

  on sr-iscsi-02 {
    address 172.16.0.212:7789;
    node-id 2;
  }

  on sr-iscsi-03 {
    address 172.16.0.213:7789;
    node-id 3;
  }

  connection-mesh {
    hosts sr-iscsi-01 sr-iscsi-02 sr-iscsi-03;
  }
}
EOF

# Inicializar el recurso DRBD
drbdadm create-md r0

# Habilitar el recurso DRBD
drbdadm up r0

# Verificar el estado del recurso DRBD
drbdadm status r0
