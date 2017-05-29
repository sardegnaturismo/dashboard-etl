#!/bin/bash

. ${PENTAHO_HOME}/functions/elastic-functions

INDEX_BACK="movimenti_back_office"
INDEX_WEB_BACK="movimenti_web_back"
TYPE_BACK="mov_back"
TYPE_WEB_BACK="mov_web_back"

LOGFILE_JOB="/opt/pentaho/log_caricamenti/regime_mov_back"
LOGFILE_QUAD="/opt/pentaho/log_caricamenti/quad_mov_back"
DATA=$(date +%Y/%m/%d)

echo "INIZIO MOV BACK $(date)"

copyToWork $INDEX_BACK

changeAliasToWork $INDEX_BACK

aliasInWork $INDEX_BACK
if [ $? -eq 0 ]
 then let "MESI=$MESI - 1"
	DELETE=$(date -d "$MESI months ago" +%Y)
	YEAR=$(date +%Y)
	while [ $DELETE -le $YEAR ]; do
		deleteMapping $INDEX_BACK $TYPE_BACK $DELETE
		let "DELETE=$DELETE + 1"
	done
 else echo -e "Indice : movimenti_back_office \n Il controllo degli alias su Elastic non è andato a buon fine. " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
        sleep 5
	exit 1
fi

copyToWork $INDEX_WEB_BACK

changeAliasToWork $INDEX_WEB_BACK

aliasInWork $INDEX_WEB_BACK
if [ $? -eq 0 ]
 then let "MESI=$MESI - 1"
        DELETE=$(date -d "$MESI months ago" +%Y)
        YEAR=$(date +%Y)
        while [ $DELETE -le $YEAR ]; do
                deleteMapping $INDEX_WEB_BACK $TYPE_WEB_BACK $DELETE
                let "DELETE=$DELETE + 1"
        done
 else echo -e "Indice : movimenti_web_back \n Problema con spostamento alias " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
        sleep 5
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

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"sired_pdi_repo" /job:"JOB_REGIME_MOVIMENTI_BACK" /dir:/SIRED/REGIME/MOVIMENTI_BACK_OFFICE /user:admin /pass:admin /level:Basic &> ${LOGFILE_JOB}.log
	
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
                	grep "${DATA}.*JOB_REGIME_MOVIMENTI_BACK\ -\ Terminata\ jobentry.*\(risultato=\[false\]\)" ${LOGFILE_JOB}.log
        		if [ $? -ne 0 ]
         	 	 then break
         	 	 else let "RETRY=$RETRY + 1"
        		fi
		fi
	fi
done

if [ $CONNECTION -eq 4 ]
 then echo -e "Indice : movimenti_back_office e movimenti_web_back \n Job : JOB_REGIME_MOVIMENTI_BACK \n Tentativi connessione esauriti" | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
	sleep 5
	changeAliasToLive $INDEX_BACK
        closeCopyWork $INDEX_BACK
        deleteWork $INDEX_BACK
	changeAliasToLive $INDEX_WEB_BACK
        closeCopyWork $INDEX_WEB_BACK
        deleteWork $INDEX_WEB_BACK
	exit 1
 elif [ $RETRY -eq 2 ]
	then echo -e "Indice : movimenti_back_office e movimenti_web_back \n Job : JOB_REGIME_MOVIMENTI_BACK \n Tentativi retry job esauriti : check log false o repo non letto " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
		sleep 5
	        changeAliasToLive $INDEX_BACK
        	closeCopyWork $INDEX_BACK
        	deleteWork $INDEX_BACK
        	changeAliasToLive $INDEX_WEB_BACK
        	closeCopyWork $INDEX_WEB_BACK
        	deleteWork $INDEX_WEB_BACK
		exit 1
 else
	echo "inizio JOB QUADRATURA1"
	while [ $OK -lt 2 ]; do
                if [ -s ${LOGFILE_QUAD}.log ]
                 then mv ${LOGFILE_QUAD}.log ${LOGFILE_QUAD}_$(date +%H%m).log
                fi

		nohup /opt/pentaho/data-integration/kitchen.sh /rep:"sired_pdi_repo" /job:"J_QUAD_MONGO_ELASTIC_BACK" /dir:/SIRED/QUERY_CHECK/BACK_MONGO_ELASTIC /user:admin /pass:admin /level:Basic&>> ${LOGFILE_QUAD}.log

		grep "An\ error\ occured\ loading\ the\ directory\ tree\ from\ the\ repository" ${LOGFILE_QUAD}.log
                if [ $? -eq 0 ]
                 then let "OK=$OK + 1"
                 else break
                fi
        done
        if [ $OK -eq 2 ]
	 then echo -e "Indice : movimenti_back_office \n Job : J_QUAD_MONGO_ELASTIC_BACK \n Tentativi retry job esauriti : repo non letto " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
                sleep 5
                exit 1
         else
                sleep 10
                changeAliasToLive $INDEX_BACK
        fi
fi

#analizzo file di output di JOB QUADRATURA1, se fallito invio mail e stoppo il container
ls /opt/pentaho/check_files/quadratura_ko
if [ $? -eq 0 ]
 then
	echo -e "Indice : movimenti_back_office \n Job : J_QUAD_MONGO_ELASTIC_BACK \n I dati non sono allineati " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
	sleep 5
	exit 1
fi
echo "MOV BACK FINITO"
