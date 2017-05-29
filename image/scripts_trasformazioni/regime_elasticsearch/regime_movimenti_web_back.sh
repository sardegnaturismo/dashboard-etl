#!/bin/bash

. ${PENTAHO_HOME}/functions/elastic-functions

INDEX="movimenti_web_back"
LOGFILE_JOB="/opt/pentaho/log_caricamenti/regime_mov_web_back"
DATA=$(date +%Y/%m/%d)

echo "INIZIO MOV WEB BACK $(date)"

echo "#JOB ETL1"
RETRY=0
CONNECTION=0
OK=0

while [ $CONNECTION -lt 4 ] && [ $RETRY -lt 2 ]; do

        echo "$(date) : CONNESSIONI = $CONNECTION RETRY = $RETRY"

        if [ -s ${LOGFILE_JOB}.log ]
         then mv ${LOGFILE_JOB}.log ${LOGFILE_JOB}_$(date +%H%m).log
        fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"sired_pdi_repo" /job:"JOB_REGIME_MOVIMENTI_WEB_BACK" /dir:/SIRED/REGIME/MOVIMENTI_WEB_BACK /user:admin /pass:admin /level:Basic &> ${LOGFILE_JOB}.log
	
	grep "An\ error\ occured\ loading\ the\ directory\ tree\ from\ the\ repository" ${LOGFILE_JOB}.log
        if [ $? -eq 0 ]
         then let "RETRY=$RETRY + 1"
         else
		#analizzo file di output check connessioni
		ls /opt/pentaho/check_files/connessione_ko
		if [ $? -eq 0 ]
	 	 then let "CONNECTION=$CONNECTION + 1"	
	      	 	sleep 10
	 	 else  
			#analizzo file di log 
                	grep "${DATA}.*JOB_REGIME_MOVIMENTI_WEB_BACK\ -\ Terminata\ jobentry.*\(risultato=\[false\]\)" ${LOGFILE_JOB}.log
        		if [ $? -ne 0 ]
         	 	 then break
         	 	 else let "RETRY=$RETRY + 1"
        		fi
		fi
	fi
done

if [ $CONNECTION -eq 4 ]
 then echo -e "Indice : movimenti_web_back \n Job : JOB_REGIME_MOVIMENTI_WEB_BACK \n Tentativi connessione esauriti" | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
	sleep 5
	changeAliasToLive $INDEX
        closeCopyWork $INDEX
        deleteWork $INDEX
	exit 1
 elif [ $RETRY -eq 2 ]
	then echo -e "Indice : movimenti_web_back \n Job : JOB_REGIME_MOVIMENTI_WEB_BACK \n Tentativi retry job esauriti : check log false o repo non letto " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
		sleep 5
		changeAliasToLive $INDEX
        	closeCopyWork $INDEX
	        deleteWork $INDEX
		exit 1
  else
        changeAliasToLive $INDEX
fi
echo "MOV WEB BACK FINITO"
