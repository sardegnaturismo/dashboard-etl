#!/bin/bash

. ${PENTAHO_HOME}/functions/elastic-functions

INDEX="movimenti"
TYPE="mov"
LOGFILE_JOB="/opt/pentaho/log_caricamenti/regime_mov_web"
LOGFILE_QUAD="/opt/pentaho/log_caricamenti/quad_mov_web"
DATA=$(date +%Y/%m/%d)

echo "INIZIO MOV WEB $(date)"

copyToWork $INDEX

changeAliasToWork $INDEX

aliasInWork $INDEX
if [ $? -eq 0 ]
 then let "MESI=$MESI - 1"
	DELETE=$(date -d "$MESI months ago" +%Y)
	YEAR=$(date +%Y)
	while [ $DELETE -le $YEAR ]; do
		deleteMapping $INDEX $TYPE $DELETE
		let "DELETE=$DELETE + 1"
	done
 else echo -e "Indice : movimenti \n Il controllo degli alias su Elastic non è andato a buon fine." | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
	sleep 10
	exit 1
fi

echo "#JOB ETL1"
RETRY=0
CONNECTION=0
OK=0

while [ $CONNECTION -lt 4 ] && [ $RETRY -lt 2 ]; do

        echo "$(date) : CONNESSIONI = $CONNECTION RETRY = $RETRY"

        if [ -s ${LOGFILE_JOB}.log ]
         then mv ${LOGFILE_JOB}.log ${LOGFILE_JOB}_$(date +%H%m).log
        fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"JOB_REGIME_MOVIMENTI_MOV" /dir:/SIRED/REGIME/MOVIMENTI /user:admin /pass:admin /level:Basic &> ${LOGFILE_JOB}.log
	
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
                	grep "${DATA}.*JOB_REGIME_MOVIMENTI_MOV\ -\ Terminata\ jobentry.*\(risultato=\[false\]\)" ${LOGFILE_JOB}.log
        		if [ $? -ne 0 ]
         	 	 then break
         	 	 else let "RETRY=$RETRY + 1"
        		fi
		fi
	fi
done

if [ $CONNECTION -eq 4 ]
 then echo -e "Indice : movimenti \n Job : JOB_REGIME_MOVIMENTI_MOV \n Tentativi connessione esauriti" | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
	sleep 5
	changeAliasToLive $INDEX
        closeCopyWork $INDEX
        deleteWork $INDEX
	exit 1
 elif [ $RETRY -eq 2 ]
	then echo -e "Indice : movimenti \n Job : JOB_REGIME_MOVIMENTI_MOV \n Tentativi retry job esauriti : check log false o repo non letto " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
		sleep 5
		changeAliasToLive $INDEX
        	closeCopyWork $INDEX
	        deleteWork $INDEX
		exit 1
 else
	echo "inizio JOB QUADRATURA1"
	while [ $OK -lt 2 ]; do
                if [ -s ${LOGFILE_QUAD}.log ]
                 then mv ${LOGFILE_QUAD}.log ${LOGFILE_QUAD}_$(date +%H%m).log
                fi

		nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"J_QUAD_MONGO_ELASTIC_WEB" /dir:/SIRED/QUERY_CHECK/WEB_MONGO_ELASTIC /user:admin /pass:admin /level:Basic&>> ${LOGFILE_QUAD}.log

		grep "An\ error\ occured\ loading\ the\ directory\ tree\ from\ the\ repository" ${LOGFILE_QUAD}.log
                if [ $? -eq 0 ]
                 then let "OK=$OK + 1"
                 else break
                fi
        done
        if [ $OK -eq 2 ]
	 then echo -e "Indice : movimenti \n Job : J_QUAD_MONGO_ELASTIC_WEB \n Tentativi retry job esauriti : repo non letto " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
                sleep 5
                exit 1
         else
                sleep 10
                changeAliasToLive $INDEX
        fi
fi

#analizzo file di output di JOB QUADRATURA1, se fallito invio mail e stoppo il container
ls /opt/pentaho/check_files/quadratura_ko
if [ $? -eq 0 ]
 then
	echo -e "Indice : movimenti \n Job : J_QUAD_MONGO_ELASTIC_WEB \n I dati non sono allineati " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
	sleep 5
	exit 1
fi
echo "MOV WEB FINITO"
