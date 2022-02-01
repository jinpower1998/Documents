#!/bin/bash
# READ !
# Make sure to run this script as root !
# Make sure, that you have granted ssh access to your backup server/host !
# Always use absolute path names !
# This script can be run as a cron job

while getopts ":d:s:b:" opt; do
	case ${opt} in
		d ) #Directory or file
		     DIR=$OPTARG
		    ;;
		s ) #Server/host
		     BACKUP_HOST=$OPTARG
		    ;;
		b ) #path to Backup-Directory on Server/host
		    BACKUP_PATH=$OPTARG
	        ;;

	    \? ) echo "please specify the directoy or file you want to backup with [-d], the host/server where you want to sync the archive with [-s] and the included backup-path with [-b]"
		    exit
		    ;;
    esac
done


##CHECK ROOT##
check_root=$(cat /etc/passwd | grep '0:0'| cut -d: -f1) 

if [[ $check_root == $USER ]]

	then
		echo "user is root, operation permitted !" 
	else
		echo "operation not permitted, user is not root !"
		echo "operation aborted"
		exit

fi &>> /var/log/backup_$DIR_$(date --rfc-3339=date).log


##CHECK DATA SIZE##

data_size=$(du -sch  --exclude=/proc/kcore/  $DIR | cut -f1)
echo $DIR 
echo ''$data_size' total size of data to create backup' &>> /var/log/backup_$DIR_$(date --rfc-3339=date).log

##CREATE ARCHIVE##

DIR_ARCHIVE=$DIR-$(date --rfc-3339=date).bak.tar.gz
tar -P --ignore-failed-read -czvf $DIR_ARCHIVE --exclude=$DIR_ARCHIVE --exclude=/proc/kcore $DIR  &>> /var/log/backup_$DIR_$(date --rfc-3339=date).log

##SYNC DATA##

sync_proc(){

	rsync -HasPv --numeric-ids $DIR_ARCHIVE $BACKUP_HOST:$BACKUP_PATH &>> /var/log/backup_$DIR_$(date --rfc-3339=date).log
	rm -rf $DIR_ARCHIVE

}

if sync_proc;

then
	echo 'backup completed at '$(date)' !'

else
	echo "backup failed at '$(date)', see /var/log/backup_<DIRECTORY/FILE>_<DATE>.log for more details"

fi &>> /var/log/backup_$DIR_$(date --rfc-3339=date).log

#EOF

