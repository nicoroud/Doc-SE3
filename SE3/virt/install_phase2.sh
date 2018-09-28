#!/bin/bash
# installation se3 phase 2
# version pour wheezy - franck molle
# maj 03-2017 - fonction dl - qq correctifs mineurs
# maj 11-2016 - no testing - modif sur commandes makepasswd
# version adaptée cd27 05 - 2017 v1.01 - Ajout restauration ldap

#Couleurs
COLTITRE="\033[1;35m"   # Rose
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLCMD="\033[1;37m"     # Blanc
COLERREUR="\033[1;31m"  # Rouge
COLTXT="\033[0;37m"     # Gris
COLINFO="\033[0;36m"	# Cyan
COLPARTIE="\033[1;34m"	# Bleu

ERREUR()
{
	echo -e "$COLERREUR"
	echo "ERREUR!"
	echo -e "$1"
	echo -e "$COLTXT"
	exit 1
}



POURSUIVRE()
{
        REPONSE=""
        while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
        do
                echo -e "$COLTXT"
                echo -e "Peut-on poursuivre? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
                read REPONSE
                if [ -z "$REPONSE" ]; then
                        REPONSE="o"
                fi
        done

        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
                ERREUR "Abandon!"
        fi
}

GENSOURCELIST()
{
cat >/etc/apt/sources.list <<END
# Sources standard:
deb http://ftp.fr.debian.org/debian/ wheezy main non-free contrib

# Security Updates:
deb http://security.debian.org/ wheezy/updates main contrib non-free

# wheezy-updates
deb http://ftp.fr.debian.org/debian/ wheezy-updates main contrib non-free

# wheezy-backports
#deb http://ftp.fr.debian.org/debian/ wheezy-backports main


END
}

GENSOURCESE3()
{

cat >/etc/apt/sources.list.d/se3.list <<END
# sources pour se3
deb http://wawadeb.crdp.ac-caen.fr/debian wheezy se3

#### Sources testing desactivee en prod ####
#deb http://wawadeb.crdp.ac-caen.fr/debian wheezy se3testing

#### Sources backports smb41  ####
deb http://wawadeb.crdp.ac-caen.fr/debian wheezybackports smb41
END
}


GENNETWORK()
{
echo "saisir l'ip de la machine"
read NEW_SE3IP
echo "saisir le masque"
read NEW_NETMASK
echo "saisir l'adresse du réseau"
read NEW_NETWORK
echo "saisir l'adresse de brodcast"
read NEW_BROADCAST
echo "saisir l'adresse de la passerrelle"
read NEW_GATEWAY

echo -e "$COLINFO"
echo "Vous vous apprêtez à modifier les paramètres suivants:"
echo -e "IP:		$NEW_SE3IP"
echo -e "Masque:		$NEW_NETMASK"
echo -e "Réseau:		$NEW_NETWORK"
echo -e "Broadcast:	$NEW_BROADCAST"
echo -e "Passerelle:	$NEW_GATEWAY"

POURSUIVRE

cat >/etc/network/interfaces <<END
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback

# The first network card - this entry was created during the Debian installation
# (network, broadcast and gateway are optional)
auto eth0
iface eth0 inet static
        address $NEW_SE3IP
        netmask $NEW_NETMASK
        network $NEW_NETWORK
        broadcast $NEW_BROADCAST
        gateway $NEW_GATEWAY
END

cat >/etc/hosts <<END
127.0.0.1       localhost
$NEW_SE3IP    se3pdc.domaine.ac-rouen.fr        se3pdc

# The following lines are desirable for IPv6 capable hosts
# (added automatically by netbase upgrade)

::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
END

cat >/etc/hostname <<END
se3pdc
END

cat >/etc/resolv.conf<<END
search etab.ac-rouen.fr
nameserver $NEW_GATEWAY
END

}

show_title()
{

clear

echo -e "$COLTITRE"
echo "--------------------------------------------------------------------------------"
echo "L'installeur est maintenant sur le point de configurer SambaEdu3."
echo "--------------------------------------------------------------------------------"
echo -e "$COLTXT"
}

test_ecard()
{
ECARD=$(/sbin/ifconfig | grep eth | sort | head -n 1 | cut -d " " -f 1)
if [ -z "$ECARD" ]; then
  ECARD=$(/sbin/ifconfig -a | grep eth | sort | head -n 1 | cut -d " " -f 1)

	if [ -z "$ECARD" ]; then
		echo -e "$COLERREUR"
		echo "Aucune carte réseau n'a été détectée."
		echo "Il n'est pas souhaitable de poursuivre l'installation."
		echo -e "$COLTXT"
		echo -e "Voulez-vous ne pas tenir compte de cet avertissement (${COLCHOIX}1${COLTXT}),"
		echo -e "ou préférez-vous interrompre le script d'installation (${COLCHOIX}2${COLTXT})"
		echo -e "et corriger le problème avant de relancer ce script?"
		REPONSE=""
		while [ "$REPONSE" != "1" -a "$REPONSE" != "2" ]
		do
			echo -e "${COLTXT}Votre choix: [${COLDEFAUT}2${COLTXT}] ${COLSAISIE}\c"
			read REPONSE
	
			if [ -z "$REPONSE" ]; then
				REPONSE=2
			fi
		done
		if [ "$REPONSE" = "2" ]; then
			echo -e "$COLINFO"
			echo "Pour résoudre ce problème, chargez le pilote approprié."
			echo "ou alors complétez le fichier /etc/modules.conf avec une ligne du type:"
			echo "   alias eth0 <nom_du_module>"
			echo -e "Il conviendra ensuite de rebooter pour prendre en compte le changement\nou de charger le module pour cette 'session' par 'modprobe <nom_du_module>"
			echo -e "Vous pourrez relancer ce script via la commande:\n   /var/cache/se3_install/install_se3.sh"
			echo -e "$COLTXT"
			exit 1
		fi
	else
	cp /etc/network/interfaces /etc/network/interfaces.orig
	sed -i "s/eth[0-9]/$ECARD/" /etc/network/interfaces
	ifup $ECARD
	fi

fi
}

installbase()
{

echo -e "$COLPARTIE"


# mv /etc/apt/sources.list /etc/apt/sources.list.sav2
# cp /etc/se3/se3.list /etc/apt/sources.list.d/

echo "Mise à jour des dépots et upgrade si necessaire, quelques mn de patience..."
echo -e "$COLTXT"
# tput reset
apt-get -qq update
apt-get upgrade --quiet --assume-yes

echo -e "$COLPARTIE"
echo "installation de ssmtp, ntpdate, makepasswd, ssh, etc...."
echo -e "$COLTXT"
apt-get install --quiet --assume-yes ssmtp ntpdate makepasswd ssh vim screen lshw atop htop smartmontools nmap tcpdump dos2unix
}


while :; do
	case $1 in
		-d|--download)
		download="yes"
		;;
		
		-n|--network)
		network="yes"
		;;
		
		--debug)
		touch /root/debug
		;;
  
		--)
		shift
		break
		;;
     
		-?*)
		printf 'Attention : option inconnue ignorée: %s\n' "$1" >&2
		;;
  
		*)
		break
		esac
 		shift
done

if [ "$download" = "yes" ]; then
	show_title
	test_ecard
	echo -e "$COLINFO"
	echo "Pré-téléchargement des paquets uniquement"
	echo -e "$COLTXT"
	installbase
	GENSOURCELIST
	GENSOURCESE3
	echo -e "$COLINFO"
	echo "Ajout du support de l'architecture i386 pour dpkg" 
	echo -e "$COLCMD\c"

	dpkg --add-architecture i386
	echo "Mise à jour des dépots"
	apt-get -qq update

	echo -e "$COLINFO"
	echo "Téléchargement de Wine:i386" 
	echo -e "$COLCMD\c"

	apt-get install wine-bin:i386 -y -d 


	echo -e "$COLINFO"
	echo "Téléchargement du backport samba 4.4" 
	echo -e "$COLCMD\c"

	apt-get install samba smbclient --allow-unauthenticated -y -d


	echo -e "$COLPARTIE"
	echo "Téléchargement du paquet se3 et de ses dependances"
	echo -e "$COLTXT"
	/usr/bin/apt-get --yes --force-yes --allow-unauthenticated install se3 se3-domain se3-logonpy se3-dhcp se3-clonage -d
	echo -e "$COLTITRE"
	echo "Phase de Téléchargement est terminée !"
	echo -e "$COLTXT"
	exit 0
fi


if [ "$network" = "yes" ]; then
	show_title
	test_ecard
	echo -e "$COLINFO"
	echo "Mofification de l'adressage IP"
	echo -e "$COLTXT"
	GENNETWORK
	service networking restart
	echo "Modification Ok" 
	echo "Testez la connexion internet avant de relancer le script sans option afin de procéder à l'installation"
	exit 0
fi

show_title
echo "Appuyez sur Entree pour continuer"
read dummy


echo -e "$COLPARTIE"

DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export  DEBIAN_FRONTEND
export  DEBIAN_PRIORITY

test_ecard
# LADATE=$(date +%d-%m-%Y)
# fichier_log="/etc/se3/install-wheezy-$LADATE.log"
# touch $fichier_log

[ -e /root/debug ] && DEBUG="yes"

GENSOURCELIST

GENSOURCESE3

installbase
echo -e "$COLPARTIE"
echo "Prise en compte de setup_se3.data"
echo -e "$COLTXT"

echo -e "$COLINFO"
if [ -e /etc/se3/setup_se3.data ] ; then
 	echo "/etc/se3/setup_se3.data est bien present sur la machine"
	. /etc/se3/setup_se3.data
	echo -e "$COLTXT"
else
	echo "/etc/se3/setup_se3.data ne se trouve pas sur la machine"
	echo -e "$COLTXT"
fi

#generation pass en automatique
if [ "$MYSQLPW" == "AUTO" ] ; then
		echo -e "$COLINFO"
		echo "Changement mot de passe root sql"
		echo -e "$COLTXT"
		MYSQLPW=$(makepasswd | LC_ALL=C sed -r 's/[^a-zA-Z0-9]//g')
		echo "$MYSQLPW"
		sed "s/MYSQLPW=\"AUTO\"/MYSQLPW=\"$MYSQLPW\"/" -i /etc/se3/setup_se3.data 
		sleep 2
fi


if [ "$ADMINPW" == "AUTO" ] ; then
		echo -e "$COLINFO"
		echo "Changement mot de passe admin ldap"
		echo -e "$COLTXT"
		ADMINPW=$(makepasswd | LC_ALL=C sed -r 's/[^a-zA-Z0-9]//g')
		echo "$ADMINPW"
		echo -e "$COLTXT"
		sed "s/ADMINPW=\"AUTO\"/ADMINPW=\"$ADMINPW\"/" -i /etc/se3/setup_se3.data 
		sleep 2
fi


if [ "$ADMINSE3PW" == "AUTO" ] ; then
		echo -e "$COLINFO"
		echo "Changement mot de passe adminse3"
		echo -e "$COLTXT"
		ADMINSE3PW=$(makepasswd | LC_ALL=C sed -r 's/[^a-zA-Z0-9]//g')
		echo "$ADMINSE3PW"
		sed "s/ADMINSE3PW=\"AUTO\"/ADMINSE3PW=\"$ADMINSE3PW\"/" -i /etc/se3/setup_se3.data 
		sleep 2
fi


if [ "$FQHN" != "" ] ; then
  echo "verif nom de domaine" 
  if [ "$FQHN" != "$(hostname -f)" ] ; then
    echo "Correction du domaine selon valeur setup_se3.data"
    sed "s/${SE3IP}.*/${SE3IP}\t$FQHN\t$SERVNAME/" -i /etc/hosts
  else
    echo "nom de domaine OK"  
  fi

fi

sed -i "s/etab.ac-rouen.fr/$(hostname -d)/" /etc/resolv.conf
### Verification que le serveur ldap est bien sur se3 et non pas déporté"

echo -e "$COLPARTIE"
echo "Type de configuration Ldap et mise a l'heure"
echo -e "$COLTXT"

		
if [ "$SE3IP" == "$LDAPIP" ] ; then
		echo "L'annuaire ldap sera installé sur le serveur se3"
		
else	
	while [ "$REP_CONFIRM" != "o" -a "$REP_CONFIRM" != "n" ]
	do
		echo -e "$COLINFO\c"
		echo -e "Vous avez demandé à installer le serveur ldap sur une machine distante."
		echo -e "Il est vivement recommandé de laisser l'annuaire en local."
		echo -e "Etes vous certain de vouloir conserver votre choix ? ${COLCHOIX}o/n${COLTXT}) $COLSAISIE\c"
		read REP_CONFIRM 
	done
	if [ "$REP_CONFIRM" != "o" ]; then
		echo -e "$COLINFO"
		echo -e "L'annuaire sera installé en local, modification de setup_se3.data"
		sed  -i "s/LDAPIP=\"$LDAPIP\"/LDAPIP=\"$SE3IP\"/" /etc/se3/setup_se3.data
		LDAPIP="$SE3IP"
	else
		echo -e "$COLINFO"
		echo -e "Vous désirez installer l'annuaire sur une machine distante, \nVérification de votre configuration en cours......"
		echo -e "$COLTXT"
		
		TST_CNX=$(ldapsearch -xLLL -b $BASEDN -h $LDAPIP 2>&1 | grep "Can't contact LDAP server")
		if [ -n "$TST_CNX" ] ; then
		ERREUR "Impossible de contacter le serveur ldap distant sur lequel vous désirez installer votre annuaire\nL'installation doit être abandonnée. Vérifiez vos connexions réseau et relancez le script d'installation, soit en rebootant la machine soit en tapant $0\n\nIl se peut également que vous aillez saisie une adresse eronée pour l'annuaire ldap dans le fichier de configuration.\nIl s'agit du paramètre LDAPIP : $LDAPIP Vous pouvez l'éditer en tapant vim /etc/se3/setup_se3.data"
		fi
		
		TST_BASEDN=$(ldapsearch -xLLL -b $BASEDN -h $LDAPIP 2>&1 | grep "No such object")
		if [ -n "$TST_BASEDN" ] ; then
		ERREUR "Problème d'acces à l'annuaire distant. L'installation doit être abandonnée\nIl semble que le paramètre BASEDN : $BASEDN soit eronné. Editez votre fichier setup_se3.data en tapant vim /etc/se3/setup_se3.data, corrigez le paramètre puis relancez le script d'installation en tapant $0 ou en rebootant la machine"
		fi
		
		TST_BIND=$(ldapsearch -xLLL -D $ADMINRDN,$BASEDN -b $BASEDN -h $LDAPIP -w $ADMINPW 2>&1 | grep "Invalid credentials")
		if [ -n "$TST_BIND" ] ; then
		ERREUR "Problème de droit d'acces à l'annuaire distant. L'installation doit être abandonnée\nIl semble que le paramètre ADMINRDN : $ADMINRDN ou ADMINPW  : $ADMINPW:  soit eronné\nEditez votre fichier setup_se3.data en tapant vim /etc/se3/setup_se3.data,\ncorriger le paramètre puis relancez le script d'installation en tapant $0"
		fi
		
		echo -e "$COLINFO"
		echo "Votre configuration semble correcte, l'installation peut se poursuivre"
		echo -e "$COLTXT"	
	fi
fi

echo -e "$COLINFO"

if [ -n "$GATEWAY" ]; then
	echo "Tentative de Mise à l'heure automatique du serveur sur $GATEWAY..."
	ntpdate -b $GATEWAY
	if [ "$?" = "0" ]; then
		heureok="yes"
	fi
fi

if [ "$heureok" != "yes" ];then

	echo "Mise à l'heure automatique du serveur sur internet..."
	echo -e "$COLCMD\c"
	ntpdate -b fr.pool.ntp.org
	if [ "$?" != "0" ]; then
		echo -e "${COLERREUR}"
		echo "ERREUR: mise à l'heure par internet impossible"
		echo -e "${COLTXT}Vous devez donc vérifier par vous même que celle-ci est à l'heure"
		echo -e "le serveur indique le$COLINFO $(date +%c)"
		echo -e "${COLTXT}Ces renseignements sont-ils corrects ? (${COLCHOIX}O/n${COLTXT}) $COLSAISIE\c"
		read rep
		[ "$rep" = "n" ] && echo -e "${COLERREUR}Mettez votre serveur à l'heure avant de relancer l'installation$COLTXT" && exit 1
	fi
fi

if [ ! -e /root/migration ]; then
	if [ ! -e /etc/se3/setup_se3.data ]; then
	echo -e "$COLINFO"
       	echo -e "Attention, si vous migrez un serveur sur un autre et que vous désirez intégrer\nun fichier secret.tdb, arrétez le script par un Control-C et copiez votre\nfichier dans /var/lib/samba.\nDans le cas contraire, vous pouvez continuer en appuyant sur entrée"
	echo -e "$COLTXT"
	read
	fi
fi



echo -e "$COLPARTIE"
echo "Installation de wine et Samba 4.4" 
echo -e "$COLTXT"



echo -e "$COLINFO"
echo "Ajout du support de l'architecture i386 pour dpkg" 
echo -e "$COLCMD\c"

dpkg --add-architecture i386
apt-get -qq update

echo -e "$COLINFO"
echo "Installation de Wine:i386" 
echo -e "$COLCMD\c"

apt-get install wine-bin:i386 -y



echo -e "$COLINFO"
echo "Installation du backport samba 4.4" 
echo -e "$COLCMD\c"

apt-get install samba smbclient --allow-unauthenticated -y

# 
# echo -e "$COLINFO"
# echo "On stopppe le service winbind" 
# echo -e "$COLCMD\c"
# service winbind stop
# insserv -r winbind


echo -e "$COLPARTIE"
echo "Installation du paquet se3 et de ses dependances"
echo -e "$COLTXT"
# /usr/bin/apt-get --yes --force-yes install se3-debconf
/usr/bin/apt-get --yes --force-yes install se3 se3-domain se3-logonpy

# modifs pour SE3 installer
# /usr/bin/apt-get install se3 --allow-unauthenticated



echo -e "$COLINFO"
echo "Suppression du paquet nscd" 
echo -e "$COLCMD\c"
/usr/bin/apt-get --yes remove nscd

# maj departementale 
cd /var/cache/se3_install/depmaj
./installdepmaj.sh
cd /

POSTINST_SCRIPT="/etc/se3/post_inst.sh"
if [ -e "$POSTINST_SCRIPT" ]; then
	echo -e "$COLINFO"
       	echo -e "Script de post-installation détecté, lancement du script"
	echo -e "$COLTXT"
	chown root "$POSTINST_SCRIPT"
	chmod 700 "$POSTINST_SCRIPT"
	"$POSTINST_SCRIPT"
fi

# Restauration ldap de sauvegarde

if [ -e "/root/save/ldap_se3_sav.ldif" ]; then
	echo -e "$COLINFO"
	echo -e "Une sauvegarde de l'annuaire est disponible dans /root/save/, lancement de la restauration"
	echo -e "$COLTXT"
	mkdir -p /var/se3/save/ldap/
	cp /root/save/ldap_se3_sav.ldif /var/se3/save/ldap/
	/usr/share/se3/sbin/restaure_ldap.sh
fi	
	
while [ "$TEST_PASS" != "OK" ]
do
echo -e "$COLCMD"
echo -e "Entrez un mot de passe pour le compte super-utilisateur root $COLTXT"
passwd
    if [ $? != 0 ]; then
        echo -e "$COLERREUR"
        echo -e "Attention : mot de passe a été saisi de manière incorrecte"
        echo "Merci de saisir le mot de passe à nouveau"
        sleep 1
    else
        TEST_PASS="OK"
        echo -e "$COLINFO\nMot de passe root changé avec succès :)"
        sleep 1
    fi
done
echo -e "$COLTXT"

echo -e "$COLTITRE"
echo "L'installation est terminée. Bonne utilisation de SambaEdu3 !"
echo -e "$COLTXT"

script_absolute_path=$(readlink -f "$0")
[ "$DEBUG" != "yes" ] &&  mv "$script_absolute_path" /root/install_phase2.done 
[ -e /root/install_phase2.sh ] && mv /root/install_phase2.sh  /root/install_phase2.done
. /etc/profile

DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog" 
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND
exit 0

