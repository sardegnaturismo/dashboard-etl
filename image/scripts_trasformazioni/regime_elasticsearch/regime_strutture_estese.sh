#!/bin/bash

. ${PENTAHO_HOME}/functions/elastic-functions

INDEX="strutture_estese"
TYPE="ricettive"
LOGFILE_JOB="/opt/pentaho/log_caricamenti/regime_strutt_estese"
DATA=$(date +%Y/%m/%d)

echo "INIZIO STRUTTURE ESTESE $(date)"

copyToWork $INDEX

changeAliasToWork $INDEX

aliasInWork $INDEX
if [ $? -eq 0 ]
 then let "MESI=$MESI - 1"
	echo "MESI scalati = $MESI"
	DELETE=$(date -d "$MESI months ago" +%Y)
	YEAR=$(date +%Y)
	while [ $DELETE -le $YEAR ]; do
		deleteMapping $INDEX $TYPE $DELETE
		let "DELETE=$DELETE + 1"
	done
 else echo -e "Indice : strutture_estese \n Il controllo degli alias su Elastic non è andato a buon fine. " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
        sleep 5
	exit 1
fi

echo "#JOB ETL1"
RETRY=0
CONNECTION=0

while [ $CONNECTION -lt 4 ] && [ $RETRY -lt 2 ]; do

	echo "$(date) : CONNESSIONI = $CONNECTION RETRY = $RETRY"

	if [ -s ${LOGFILE_JOB}.log ] 
 	 then mv ${LOGFILE_JOB}.log ${LOGFILE_JOB}_$(date +%H%m).log
	fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"JOB_REGIME_STRUTTURE" /dir:/SIRED/REGIME/STRUTTURA_ESTESA /user:admin /pass:admin /level:Basic &> ${LOGFILE_JOB}.log
	
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
               		grep "${DATA}.*JOB_REGIME_STRUTTURE\ -\ Terminata\ jobentry.*\(risultato=\[false\]\)" ${LOGFILE_JOB}.log
       			if [ $? -ne 0 ]
       	 	 	 then break
       	 	 	 else let "RETRY=$RETRY + 1"
			fi
		fi
	fi
done

if [ $CONNECTION -eq 4 ]
 then echo -e "Indice : strutture_estese \n Job : JOB_REGIME_STRUTTURE \n Tentativi connessione esauriti" | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI 
	sleep 5
	changeAliasToLive $INDEX
	closeCopyWork $INDEX
	deleteWork $INDEX	
	exit 1
 elif [ $RETRY -eq 2 ]
	then echo -e "Indice : strutture_estese \n Job : JOB_REGIME_STRUTTURE \n Tentativi retry job esauriti : check log false o repo non letto " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI 
		sleep 5
		changeAliasToLive $INDEX
        	closeCopyWork $INDEX
        	deleteWork $INDEX
		exit 1   
 else
	changeAliasToLive $INDEX
fi

echo "STR EST FINITO $(date)"
