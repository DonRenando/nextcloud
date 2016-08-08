# !/bin/sh
#---------------------------------------------------------------------#
#@(#) SCRIPT : UpToNext.ksh
#---------------------------------------------------------------------#
#@(#)  Easy way to upgrade Nextcloud version
#@(#) the only thing to do is to change the variables (if necessary)

#---------------------------------------------------------------------#
#		1.00	DonRenando	05/07/2016	script creation
#---------------------------------------------------------------------#

path=/var/www
ncpath=/var/www/nextcloud
htuser=www-data
htgroup=www-data
version=9.0.53
url=https://download.nextcloud.com/server/releases/nextcloud-$version.zip

#Lancement de la maintenance
sudo -u www-data php $ncpath/occ maintenance:mode --on

#stop apache
sudo service apache2 stop
echo "INFO ;STOP Apache"

#deplacement dans /var/www/
cd $path

#renommage nextcloud en nextcloud_old
sudo mv nextcloud nextcloud_old

#verification de la creation de nextcloud_old
if [ -r nextcloud_old ]
then
	echo "INFO ; nextcloud renamed nextcloud_old"

else	
	echo "ERROR ; directory nextcloud_old not found"
	exit 1
fi

#deplacement dans /var/www/
cd $path

#telechargement de la nouvelle version
sudo wget -q $url

#verification de la presence et de la validite du zip
if [ ! -f nextcloud-$version.zip ] || [ gzip -t nextcloud-$version.zip -ne  0 ]
then
	echo "ERROR ; nextcloud-$version.zip could not be downloaded or is not valid"
	exit 1
fi

#decompression
sudo unzip nextcloud-$version.zip 2>&1 | 
    while read line; do
        x=$((x+1))
        echo -en "$x extracted\r"
    done

#test nouveau chemin nextCloud
if [ -r nextcloud ]
then
	echo "INFO ; nextcloud directory created"

else	
	echo "ERROR ; directory nextcloud not found"
	exit 1
fi

#supression du zip
sudo rm nextcloud-$version.zip

#recuperation fichier de config
echo "INFO ; copy configuration file"
sudo cp $path/nextcloud_old/config/config.php $path/nextcloud/config/config.php

#deplacement fichier data
echo "INFO ; move data files"
sudo mv $path/nextcloud_old/data $path/nextcloud/data

#recuperation theme
echo "INFO ; copy theme files"
sudo cp -R /var/www/nextcloud_old/themes/* /var/www/nextcloud/themes


#chagement des droits
sudo chown -R ${htuser}:${htgroup} ${ncpath}

#demarrage apache
sudo service apache2 start

#deplacement sur /var/www/nextcloud
cd $ncpath

#upgrade occ
sudo -u www-data php $ncpath/occ upgrade

#stop de la maintenance
sudo -u www-data php $ncpath/occ maintenance:mode --off
