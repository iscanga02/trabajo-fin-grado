# Actualizar el sistema
apt update && apt upgrade -y

# Instalar paquetes necesarios para iSCSI
apt install targetcli-fb iptables -y

# Limpiar paquetes no necesarios
apt autoremove -y

# Copia de seguridad del script que se encarga de bloquear/desbloquear el puerto 3260
cp /usr/lib/ocf/resource.d/heartbeat/portblock /usr/lib/ocf/resource.d/heartbeat/portblock.old

# Reeemplazar la función IptablesUNBLOCK
sed -i '/^IptablesUNBLOCK()/,/^}/c\
IptablesUNBLOCK() {\
  if [ "$4" = "in" ] || [ "$4" = "both" ]; then\
    DoIptables -D "$1" "$2" "$3" INPUT\
  fi\
  if [ "$4" = "out" ] || [ "$4" = "both" ]; then\
    DoIptables -D "$1" "$2" "$3" OUTPUT\
  fi\
\
  rc=$?\
\
  if [ "$4" = "in" ] || [ "$4" = "both" ]; then\
    $IPTABLES $wait -D INPUT -p "$1" -d "$3" -m multiport --dports "$2" -j DROP\
  fi\
\
  return "$rc"\
}' /usr/lib/ocf/resource.d/heartbeat/portblock
