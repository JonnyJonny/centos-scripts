echo "install nfs tools"
yum -y install nfs-utils nfs-utils-lib
 
echo "start nfs on startup"
chkconfig rpcbind on
chkconfig nfs on
 
echo "start service"
service rpcbind start
service nfs start
 
echo "add right to anonymous user NFS (id 65534)"
chown 65534:65534 /opt/nfs
chmod 755 /opt/nfs 
 
echo "add rule to enable connection for client 192.168.0.10 (must set ip address)"
cat >> /etc/exports << "EOF"
/opt/nfs           192.168.0.10(rw,sync) 
EOF
 
echo "enable rules"
exportfs -a