#!/bin/bash

# Vérification des droits d'accès
if [ "$(id -u)" != "0" ]; then
    echo "Ce script doit être exécuté en tant que root!"
    exit 1
fi

# Installation des paquets nécessaires
apt update
apt install -y vim tree curl wget openssh-server ufw git

# Vérification de l'installation des paquets
check_pkg vim
check_pkg tree
check_pkg curl
check_pkg git
check_pkg wget
check_pkg openssh-server
check_pkg ufw

# Configuration du service SSH
systemctl enable ssh --now

# Désactivation de l'accès root via SSH
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl ssh restart

# Désactivation de l'authentification par mot de passe
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl ssh restart

# Liste blanche d'adresses IP autorisées
allowed_ips="192.168.1.0/24 10.0.0.0/8"

# Configuration de la liste blanche d'adresses IP
echo "Match Address $allowed_ips" >> /etc/ssh/sshd_config
echo "  PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "  PermitRootLogin no" >> /etc/ssh/sshd_config
service ssh restart

# Configuration du répertoire SSH
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
fi
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
fi
chmod 600 ~/.ssh/authorized_keys

# Génération des clés SSH
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# Création du groupe ssh_users si possible
if ! getent group ssh_users > /dev/null; then
    if getent group 1001 > /dev/null; then
        echo "Le GID 1001 est déjà utilisé, impossible de créer le groupe ssh_users"
    else
        groupadd -g 1001 ssh_users
        echo "AllowGroups ssh_users" >> /etc/ssh/sshd_config
        echo "DenyGroups *" >> /etc/ssh/sshd_config
        service ssh restart
    fi
fi

# Configuration du pare-feu UFW
ufw default deny incoming
ufw allow ssh
ufw allow http
ufw allow https
ufw enable



echo "Script terminé avec succès !"