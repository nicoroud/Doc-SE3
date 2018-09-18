# Installation d'un serveur de backup dans le réseau du collège

## Objectif
Sauvegarder les "home" des utilisateurs avec rsnapshot sur le serveur de sauvegarde.
La sauvegarde sera incrémentielle

## 1. Préparation du serveur de sauvegarde
- Installation de debian jessie avec lxde
- Installation des composants nécessaires à la sauvegarde : ssh, rsync, rsnapshot...
- Gestion des clès ssh pour une connexion sans mot de passe

### 1.1. Installation et configuration de rsnapshot
```sh
apt install rsnapshot
nano /etc/rsnapshot.conf
```
```
# All snapshots will be stored under this root directory.
#
snapshot_root /srv/backup

backup  10.160.6.4:/home/ SE3/
```

### 1.2. crontab
```sh
0 4 * * * /usr/local/bin/backuprsnapshot daily
0 3 * * 1 /usr/local/bin/backuprsnapshot weekly
0 2 1 * * /usr/local/bin/backuprsnapshot monthly
```
sauvegarde tous les jours à 4h00
touts les lundi à 3h00
tous les 1er du mois à 2h00

## 2. Préparation sur le SE3
connexion en admin via ssh sans mot de passe.
#### 1. Générer une cle rsa sur le serveur de sauvegarde
```sh
ssh-keygen -t rsa
ssh-copy-id -i .ssh/id_rsa.pub admin@10.160.6.4
```
#### 2. 
