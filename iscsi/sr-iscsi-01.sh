# Actualizar el sistema
apt update && apt upgrade -y

# Instalar paquetes necesarios para iSCSI
apt install targetcli-fb iptables -y

# Limpiar paquetes no necesarios
apt autoremove -y

# Copiar de manera local la configuración de Pacemaker
pcs clúster cib cib.xml

# Crear un recurso DRBD
pcs -f cib.xml resource create p_drbd_r0 ocf:linbit:drbd drbd_resource="r0" op monitor interval="29s" role="Promoted" op monitor interval="31s" role="Unpromoted"

# Clonar el recurso DRBD (1 copia por nodo)
pcs -f cib.xml resource clone p_drbd_r0 ms_drbd_r0 promoted-max=1 promoted-node-max=1 clone-max=3 clone-node-max=1 notify=true

# Crear la dirección IP virtual del recurso iSCSI
pcs -f cib.xml resource create p_iscsi_ip0 ocf:heartbeat:IPaddr2 ip="192.168.0.210" cidr_netmask="24" op start timeout=20 op stop timeout=20 op monitor interval="10s"

# Crear el recurso iSCSI que apunta al recurso DRBD
pcs -f cib.xml resource create p_iscsi_target_drbd0 ocf:heartbeat:iSCSITarget iqn="iqn.2024-04.com.example:drbd0" portals="192.168.0.210:3260" op start timeout=20 op stop timeout=20 op monitor interval=20 timeout=40

# Crear la unidad lógica iSCSI
pcs -f cib.xml resource create p_iscsi_lun_drbd0 ocf:heartbeat:iSCSILogicalUnit target_iqn="iqn.2024-04.com.example:drbd0" implementation=lio-t lun=0 path="/dev/drbd0" scsi_sn="aaaaaaa0" op start timeout=20 op stop timeout=20 op monitor interval=20 timeout=40

# Reglas para bloquear el puerto 3260 durante el failover
pcs -f cib.xml resource create p_iscsi_portblock_on_drbd0 ocf:heartbeat:portblock ip=192.168.0.210 portno=3260 protocol=tcp action=block op start timeout=20 op stop timeout=20 op monitor timeout=20 interval=20

# Reglas para desbloquear el puerto 3260 durante el failback
pcs -f cib.xml resource create p_iscsi_portblock_off_drbd0 ocf:heartbeat:portblock ip=192.168.0.210 portno=3260 protocol=tcp action=unblock op start timeout=20 op stop timeout=20 op monitor timeout=20 interval=20

# Unir los recursos en un grupo
pcs -f cib.xml resource group add g_iscsi_drbd0 p_iscsi_portblock_on_drbd0 p_iscsi_ip0 p_iscsi_target_drbd0 p_iscsi_lun_drbd0 p_iscsi_portblock_off_drbd0

# Establecer el orden de los recursos
pcs -f cib.xml constraint order ms_drbd_r0 then g_iscsi_drbd0

# Establecer la restricción de colocación de los recursos
pcs -f cib.xml constraint colocation add g_iscsi_drbd0 with promoted ms_drbd_r0

# Verificar la configuración de Pacemaker
pcs -f cib.xml clúster verify --full

# Aplicar la configuración de Pacemaker
pcs clúster cib-push cib.xml

# Verificar el estado del clúster
pcs status --full

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
