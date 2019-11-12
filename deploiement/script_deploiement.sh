#!/bin/bash

echo "---------------------------------------------------------------\n"
echo "          updating..."
echo "\n"

apt-get update -y
apt-get upgrade -y

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          installing package..."
echo "\n"

apt-get install sudo -y
apt-get install git -y
apt-get install apache2 -y
apt-get install sendmail -y
apt-get install portsentry -y
apt-get install fail2ban -y
apt-get install ufw -y
apt-get install vim -y

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          debian disk info :"
echo "\n"

sudo fdisk -l                                   ??? sudo ou pas ?

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          installing folder..."
echo "\n"

sudo cd /root                                    ??? sudo ou pas ?
git clone https://github.com/Cracky-Kroll /roger-skyline/root/roger-skyline

echo "\n"
echo "------------------------------------\n"
echo "          user creation..."
echo "\n"

echo "adding sudo user... Username ? (default: 'roger')"
read Username
Username=${Username:-"roger"}                                 ?
sudo adduser $Username
sudo adduser $Username sudo

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          interfaces"
echo "\n"

mv /etc/network/interfaces /etc/network/interfaces_save
cp /root/roger-skyline/deploiement/files/interfaces /etc/network/

cp /root/roger-skyline/deploiement/files/enp0s3 /etc/network/interfaces.d/

sudo service networking restart

echo "check ip address\n"
ip addr

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          SSHD config..."
echo "\n"

mv /etc/ssh/sshd_config /etc/ssh/sshd_config_save

cp /root/roger-skyline/deploiement/files/sshd_config /etc/ssh/
mkdir -pv /home/$Username/.ssh
cat /root/roger-skyline/deploiement/files/id_rsa.pub >> /home/$Username/.ssh/authorized_keys
#// PAS SUR ! ID_RSA PUB OU AUTHORIZED_KEYS//

sudo service sshd restart

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          setup Firewall..."
echo "\n"

sudo ufw enable
sudo ufw allow sshd
#ssh
sudo ufw allow 51001/tcp
#http
sudo ufw allow 80/tcp
#https
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw reload
sudo ufw status verbose

sudo systemctl start ufw
sudo systemctl enable ufw

#/*///////////////////////////////////////////////////////////////////// sais plus !!!!!
#sudo apt-get iptables
#sudo iptables -t filter -A INPUT -p tcp --dport 51001 -j ACCEPT
#sudo iptables -t filter -A OUTPUT -p tcp --dport 51001 -j ACCEPT
#*///////////////////////////////////////////////////////////////////

sudo apt-get install iptables-persistent
sudo iptables-save > /etc/iptables/rules.v6

echo "done"

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          DOS protection..."
echo "\n"

cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
#rm /etc/fail2ban/fail2ban.conf
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
rm /etc/fail2ban/jail.conf
cp /root/roger-skyline/deploiement/files/jail.conf /etc/fail2ban/
cp /root/roger-skyline/deploiement/files/apache-dos.conf /etc/fail2ban/filter.d/
sudo systemctl restart fail2ban
#start la jail
sudo fail2ban-client start
echo "check jail status\n"
sudo fail2banclient status
#verif status prison sshd avec nombre de tentative echouees et liste ip bannies
echo "check sshd's jail\n"
sudo fail2ban-client status sshd
#de-bannir une ip d'une jail
#fail2ban-client set [nom de jail] unbanip [IP concernee]
#bannir manuellement une IP sur une jail
#fail2ban-client set [nom de jail] banip [IP a bannir]

echo "done"

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          protection against Port Scans..."
echo "\n"

#config portsentry
mv /etc/default/portsentry /etc/default/portsentry_save
cp /root/roger-skyline/deploiement/files/portsentry /etc/default/
mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf_save
cp /root/roger-skyline/deploiement/files/portsentry.conf /etc/portsentry/

sudo service portsentry restart

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          Mail server"
echo "\n"

yes 'Y' | sudo sendmailconfig

echo "\n"
echo "---------------------------------------------------------------\n"
echo "          update Script"
echo "\n"
#met a jour ensemble des packages, qui log l'ensemble ds un fichier 
#/var/log/update_script.log. A chaque reboot et 1 fois par semaine a 4h du mat.

mkdir /root/script
cp /root/roger-skyline/deploiement/files/update_script.sh /root/script
chmod 755 /root/script/update_script.sh
chown root /root/script/update_script.sh

echo "0  4  * * 1	root    /root/script/update_script.sh\n" >> /etc/crontab
echo "@reboot	root    /root/script/update_script.sh\n" >> /etc/crontab

echo "0  4  * * 1	root    /root/script/update_script.sh\n" >> /var/spool/cron/crontabs/root
echo "@reboot	root    /root/script/update_script.sh\n" >> /var/spool/cron/crontabs/root

echo "\n"
echo "---------------------------------------------------------------\n"
echo "			crontab script"
echo"\n"

#script qui permet de surveiller modifications du fichier /etc/crontab et 
#envoie un mail a root si modifie. tache planifie tous les jour a minuit.

cp /root/roger-skyline/files/script_modif_crontab.sh /root/script/
cp /root/roger-skyline/files/mail_type.txt /root/script/
chmod 755 /root/script/script_modif_crontab.sh
chown root /root/script/script_modif_crontab.sh
chown root /root/script/mail_type.txt

echo "done\n"

echo "0  0  * * *	root    /root/script/script_modif_crontab.sh\n" >> /etc/crontab
echo "0  0  * * *	root    /root/script/script_modif_crontab.sh\n" >> /var/spool/cron/crontabs/root

systemctl enable cron

touch /root/script/tmp
cat /etc/crontab > /root/script/tmp

echo "\n"
echo "---------------------------------------------------------------\n"
echo "			web server..."
echo "\n"

sudo systemctl start apache2

echo "done"

echo "\n"
echo "---------------------------------------------------------------\n"
echo "			virtual host..."
echo "\n"

mkdir -p /var/www/login.fr/html
chown -R $Username:$Username /var/www/login.fr/html
chmod -R 755 /var/www/login.fr/html

cp /root/roger-skyline/deploiement/files/index.html /var/www/login.fr/html
cp /root/roger-skyline/deploiement/files/styles.css /var/www/login.fr/html

cp /root/roger-skyline/deploiement/files/default-ssl.conf /etc/apache2/sites-available

rm /etc/apache2/sites-available/000-default.conf
cp /root/roger-skyline/deploiement/files/000-default.conf /etc/apache2/sites-available/
ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled

echo "done"

echo "\n"
echo "---------------------------------------------------------------\n"
echo "			SSL certificat..."
echo "\n"

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=FR/ST=IDF/O=42/OU=Project-roger/CN=10.11.200.247" -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

sudo a2enmod SSL
sudo service apache2 restart

echo "\n"
echo "---------------------------------------------------------------\n"
echo "			cleaning..."
echo "\n"

apt-get remove git -y
apt-get purge git -y
rm -rf /root/roger-skyline

echo "subject: Install done for $Username." | sudo sendmail -v ccarole@student.42.fr
echo "\n"
echo "FINISH."