# Script Config
	#Runpath ex. /home/teamspeak3 script has to be located here
		RP="/home/teamspeak3"
	#Servfolder ex. ts3server
		SRVF="ts3server"
	#Start Command ex. /etc/init.d/teamspeak3 start
		CSTART="/etc/init.d/teamspeak3 start"
	#Stop Command ex. /etc/init.d/teamspeak3 stop
		CSTOP="/etc/init.d/teamspeak3 stop"
	#Backupfilename ex. ts3backup
		BUFILE="ts3backup"
	#Download Url ex. http://dl.4players.de/ts/releases/
		DLURL="http://dl.4players.de/ts/releases/"
	#Download Name ex. teamspeak3-server_linux-amd64 or teamspeak3-server_linux-x86
		DLNAME="teamspeak3-server_linux-amd64"
	#Version to start check from ex. 3.0.10.0
		V1=3
		V2=0
		V3=10
		V4=0
	#Versions to check max ex. 200 will increase time
		CMAX=200
	#Sub Versions max ex. 20 -> 3.0.19.1 will not find 3.0.21.1
		SV=20
	#Backup 1 Path ex. example.com/backups
		BUP1="example.com"
	#Backup 1 User ex. user
		BUUSR1="user"
	#Backup 1 Password ex. secret
		BUPW1="password"

        #Backup 2 Path ex. example.com/backups
                BUP2="example.com/backup"
        #Backup 2 User ex. user
                BUUSR2="user"
        #Backup 2 Password ex. password
                BUPW2="password"

#-----------End Config -------------

LF=""
cd $RP

server_check() {
C=0
while [ $C -le $CMAX ]
do
        VC=$V1.$V2.$V3.$V4
        if wget --spider -q $DLURL$VC/$DLNAME-$VC.tar.gz; then
                LV=$DLURL$VC/$DLNAME-$VC.tar.gz
		LF=$VC
	fi
                if [ $V4 -ge $SV ]; then
                        if [ $V3 -ge $SV ]; then
				if [ $V2 -ge $SV ]; then
                                	if [ $V1 -ge $SV ]; then
                          		      C=$CMAX
                        		fi
					V1=$(($1 + 1))
                                	V2=0
                        	fi
                                V2=$(($V2 + 1))
                                V3=0
                        fi
			V3=$(($V3 + 1 ))
			V4=0
                fi
        V4=$(($V4 + 1 ))
        C=$(($C + 1 ))
done
echo "Last Version Found: $LF"
}

int_done() {
echo "----- Remove Temp Directory"
if [ -d "$RP/tmp" ]; then
	rm -R "$RP/tmp"
fi
}

int_update() {
	echo "----- Updating Server"
if [ -d "$RP/tmp/$DLNAME" ]; then
	mv $RP/tmp/$DLNAME $RP/tmp/$SRVF		#Rename Download Folder to Servername
	cp -r $RP/tmp/$SRVF $RP				#Copy new server files
	echo "----- Update done"
fi
}

int_backup() {
	echo "----- Starting Backup"
	if [ -f "$BUFILE.tar.gz" ]; then
		echo "----- Removing old Backup"
		rm "$BUFILE.tar.gz"
	fi
	tar -czf $BUFILE.tar.gz $SRVF
	if [ -f "$BUFILE.tar.gz" ]; then
		echo "----- Backup Done"
	else
		echo "----- Backup Failed"
	fi
}

int_bu() {
	if [ "$BUUSR1" != "user" ]; then
		echo "----- Starting External Backup 1"
		wput -uq $BUFILE.tar.gz "ftp://$BUUSR1:$BUPW1@$BUP1/$BUFILE.tar.gz"
	else
		echo "----- No User for External Backup 1"
	fi
        if [ "$BUUSR2" != "user" ]; then
                echo "----- Starting External Backup 2"
                wput -uq $BUFILE.tar.gz "ftp://$BUUSR2:$BUPW2@$BUP2/$BUFILE.tar.gz"
        else
                echo "----- No User for External Backup 2"
        fi
}

int_extract() {
	echo "----- Extracting File to $RP/tmp"
	mkdir "$RP/tmp"					#Create temp directory
	tar -xzf $DLNAME-$LF.tar.gz -C "$RP/tmp"	#Extract to temp
	echo "----- Removing Download File"
	rm $DLNAME-$LF.tar.gz				#Delete Download file
}

int_download() {
	echo "----- Downloading File"
	wget -q $DLURL$LF/$DLNAME-$LF.tar.gz		#Download new Version
	if [ -f "$DLNAME-$LF.tar.gz" ]; then
		echo "----- File Download Ok"
	else
		echo "----- File not found $DLNAME-$LF.tar.gz"
		exit 0
	fi
}



server_start() {
echo "----- Starting Server"
$CSTART
}

server_stop() {
echo "----- Stopping Server"
$CSTOP
}

server_update() {
server_check
int_download
int_extract
server_stop
int_backup
int_update
server_start
int_bu
int_done
}

server_help() {
echo "----- Commands -----"
echo "start		- Starting Teamspeak Server"
echo "stop		- Stopping Teamspeak Server"
echo "update		- Updating Teamspeak Server"
echo "backup		- Backup Teamspeak Server"
}

case "$1" in
 'start')
  server_start
 ;;

 'stop')
  server_stop
 ;;

 'check')
 server_check
 ;;

  'update')
  server_update
  ;;

  'backup')
  server_stop
  int_backup
  server_start
  int_bu
  ;;

  'help')
  server_help
  ;;

esac
