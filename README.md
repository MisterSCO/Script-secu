# README pour le Script d'Installation et de Configuration

## Description
Ce script Bash automatise l'installation et la configuration de plusieurs paquets essentiels pour un serveur. Il inclut la configuration de SSH, la mise en place d'un pare-feu UFW, la création d'un groupe d'utilisateurs SSH, et la configuration des mises à jour automatiques des paquets de sécurité.

## Prérequis
Le script doit être exécuté avec des droits root.
Un système basé sur Debian (comme Ubuntu) est recommandé.
Fonctionnalités
Installation des paquets suivants :
* vim
* tree
* curl
* wget
* openssh-server
* ufw
* git
* unattended-upgrades

## Étape d'execution

* Vérification de l'installation des paquets.
* Configuration du service SSH :
    * Activation et démarrage du service SSH.
    * Désactivation de l'accès root via SSH.
    * Désactivation de l'authentification par mot de passe.
    * Génération des clés SSH si elles n'existent pas.
    * Création d'un groupe ssh_users avec GID 1001 si ce GID n'est pas déjà utilisé.
* Configuration du pare-feu UFW pour autoriser uniquement le trafic SSH, HTTP et HTTPS.
* Configuration des mises à jour automatiques pour les paquets de sécurité.