#!/bin/bash

# Arret du script en cas d'erreur
set -e

# Vérifier si l'utilisateur a les droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Erreur : Ce script nécessite les droits root."
    exit 1
fi

# Installation des paquets nécessaires
apt update
apt install -y vim tree curl wget openssh-server ufw git unattended-upgrades

# Fonction pour vérifier si les paquets sont installés
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
check_pkg unattended-upgrades

# Ajout du usr/sbin dans le PATH si il n'y est pas, le temps du script
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

# Désactivation de l'authentification par mot de passe
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config


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
    fi
fi

systemctl restart ssh

# Configuration du pare-feu UFW
ufw default deny incoming
ufw allow ssh
ufw allow http
ufw allow https
ufw enable


# Configuration des mises à jour automatiques des paquets de sécurité
echo "Configuration des mises à jour automatiques des paquets de sécurité..."



#  Vérifie la destribution et la version
distro_id=$(lsb_release -si)
distro_codename=$(lsb_release -sc)

# Vérifier et ajouter la configuration pour les mises à jour automatiques
if ! grep -q "APT::Periodic::Update-Package-Lists" /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "APT::Periodic::Update-Package-Lists \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
fi

# Vérification des mise a jour non surveillées
if ! grep -q "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "APT::Periodic::Unattended-Upgrade \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
fi


# Vérification des origines autorisées pour les mise à jour automatique
if ! grep -q "Unattended-Upgrade::Allowed-Origins" /etc/apt/apt.conf.d/50unattended-upgrades; then
    echo "Unattended-Upgrade::Allowed-Origins {" >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo "    \"${distro_id}:${distro_codename}-security\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo "};" >> /etc/apt/apt.conf.d/50unattended-upgrades
fi

# Vérifier le service
systemctl enable unattended-upgrades

echo "Script terminé avec succès !"