#!/bin/bash

# Arret du script en cas d'erreur
set -e

# Vérification des droits d'accès
if [ "$(id -u)" != "0" ]; then
    echo "Ce script doit être exécuté en tant que root!"
    exit 1
fi

# Installation des paquets nécessaires
apt update
apt install -y vim tree curl wget openssh-server ufw git

# Fonction pour vérifier l'installation des paquets
check_pkg() {
    if ! dpkg -l | grep -q "$1"; then
        echo "Le paquet $1 n'est pas installé."
    else
        echo "Le paquet $1 est déjà installé."
    fi
}

# Vérification de l'installation des paquets
check_pkg vim
check_pkg tree
check_pkg curl
check_pkg git
check_pkg wget
check_pkg openssh-server
check_pkg ufw

# Ajout du usr/sbin dans le PATH si il n'y est pas
if [[ ":$PATH:" != *":/usr/sbin:"* ]]; then
    export PATH="$PATH:/usr/sbin"
fi

# Vérification si le service SSH écoute sur le port 22
if ss -tuln | grep -q ':22'; then
    echo "Le service SSH écoute sur le port 22."
else
    echo "Le service SSH ne écoute pas sur le port 22."
    echo "Vérifiez si le service SSH est en cours d'exécution et s'il est correctement configuré."
    exit 1
fi

# Configuration du service SSH
systemctl enable ssh --now

# Configuration du répertoire SSH
if [ ! -d ~/.ssh ]; then
    mkdir ~/.ssh
fi
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
fi
chmod 600 ~/.ssh/authorized_keys



# Désactivation de l'accès root via SSH
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh 

# Désactivation de l'authentification par mot de passe
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh



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
        systemctl restart ssh
    fi
fi

# Configuration du pare-feu UFW
ufw default deny incoming
ufw allow ssh
ufw allow http
ufw allow https
ufw enable



echo "Script terminé avec succès !"