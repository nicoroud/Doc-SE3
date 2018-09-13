## Ajouter un disque physique pour déplacer `/tftpboot` et son contenu

Cette procédure nécessite à priori d'éteindre le serveur, d'y ajouter un disque physique, puis de redémarrer le serveur.

Ce disque n'a pas besoin d'être d'un volume important. À la limite, une clé `USB` branchée sur un port interne pourrait suffire !


### Repérer le nouveau disque

La commande suivante devrait vous indiquer le nom du disque ajouté.
```sh
lsblk
```

À priori, si vous n'aviez qu'un seul disque (repéré par `sda`), cela devrait être `sdb` pour le nouveau disque. Repérez bien cette référence pour adapter les commandes ci-dessous.

**Remarque :** selon les versions de Debian, il se peut que cette commande soit indisponible. Il faudra alors utiliser la commande `fdisk -l`. Dans cette commande, les disques sont repérés par `/dev/sda`, `/dev/sdb`,…


### Créer une partition sur l'ensemble du disque

Si ce n'est pas déjà le cas, créer une partition primaire occupant la totalité du disque : 
```sh
fdisk /dev/sdb
```

Répondre aux questions…

…puis formater cette partition en `ext3` :
```sh
mkfs.ext3 /dev/sdb1
```


### Déplacer le contenu de `/tftpboot` dans le disque

Monter ce disque provisoirement dans `/mnt/disque` :
```sh
mkdir /mnt/disque
mount /dev/sdb1 /mnt/disque
```

Déplacer le contenu de `/tftpboot` sur ce nouveau disque :
```sh
mv /tftpboot/* /mnt/disque
```

Vérifier que `/tftpboot` est vide :
```sh
ls -alh /tftpboot
```

Démonter le disque :
```sh
umount /mnt/disque
rmdir /mnt/disque
```


### Monter le disque sur `/tftpboot`

Modifier le fichier `/etc/fstab` en ajoutant la ligne suivante à la fin du fichier :
```sh
/dev/sdb1 /tftpboot     ext3    defaults        0       2
UUID=xxx /tftpboot ext3 defaults 0 2
```
**Remarque :** Dans cette ligne, vous remplacerez xxx par la valeur de l’UUID du disque dur. Pour connaître la valeur de l'UUID, vous pouvez utiliser la commande suivante :
```sh
blkid | grep /dev/sdb1
```

Effectuer les montages contenus dans `/etc/fstab` avec la commande :
```sh
mount -a
```

Vérifier que le contenu de `/tftpboot` est bien là :
```sh
ls -alh /tftpboot
```

**Et voilà !** Un petit coup de la commande suivante (ou bien une petite visite de l'interface web)…
```sh
df -h
```
…pour vérifier que `/` a plus de place, et **vous pouvez respirer !**

Source : https://github.com/SambaEdu/se3-docs/blob/master/se3-migration/AugmenterRacine.md
