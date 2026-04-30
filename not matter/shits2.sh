useradd sysadm 
useradd dbadm 
groupadd sysadmin
groupadd dbadmin
usermod -aG sysadmin sysadm
usermod -aG dbadmin dbadm

visudo 
#%sysadmin ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart /usr/bin/systemctl start /usr/bin/systemctl stop
#dbadmin ALL=(ALL) NOPASSWD: /usr/bin/

mkdir -p /var/storage 
mkdir -p /var/backup

cat>>/var/backup.sh
pg_dumpall -U postgres > /var/backup:Z/data_$(date +%F).sql
#end of baclup.sh 

cat>>/etc/audit/rules.d/backup.rules
-w /var/backup.sh -p wa -k backup_change 
#end of file 
sudo augenrules --load
sudo service audit reload 

podman run -d --name postgres --cpus="2" --memory="1g" --restart always -e POSTGRES_PASSWORD=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -v /var/root/storage/data:/var/lib/postgresql/data:Z postgres:latest

cat>>check.sh
if ! podman exec postgres pg_isready -U postgres; then
    podman restart postgres 
fi

chmod +x /root/chech.sh

echo "* * * * * root /root/check.sh" | sudo tee /etc/cron.d/check


