#!/bin/bash
. ${PENTAHO_HOME}/functions/postgres-functions

DB=${DASH_TARGET}

LOGFILE_JOB="/opt/pentaho/log_caricamenti/dash_operatore"
LOGFILE_QUAD="/opt/pentaho/log_caricamenti/quad_dash_operatore"
DATA=$(date +%Y/%m/%d)

echo "INIZIO DASH OPERATORE $(date)"

RETRY=0
CONNECTION=0
OK=0

while [ $CONNECTION -lt 4 ] && [ $RETRY -lt 2 ]; do

	echo "$(date) : CONNESSIONI = $CONNECTION RETRY = $RETRY"

        if [ -s ${LOGFILE_JOB}.log ]
         then mv ${LOGFILE_JOB}.log ${LOGFILE_JOB}_$(date +%H%m).log
        fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"J_DASH_OPERATORE_FAST" /dir:/SIRED/DASHBOARD/NEW_OPERATORE_FAST /user:admin /pass:admin /level:Basic &> ${LOGFILE_JOB}.log
	
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
                	grep "${DATA}.*J_DASH_OPERATORE_FAST\ -\ Terminata\ jobentry.*\(risultato=\[false\]\)" ${LOGFILE_JOB}.log
        		if [ $? -ne 0 ]
         	 	 then break
         	 	 else let "RETRY=$RETRY + 1"
        		fi
		fi
	fi
done

if [ $CONNECTION -eq 4 ]
 then echo -e "Job : J_DASH_OPERATORE_FAST \n Tentativi connessione esauriti" | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
	sleep 5
	exit 1
 elif [ $RETRY -eq 2 ]
	then echo -e "Job : J_DASH_OPERATORE_FAST \n Tentativi retry job esauriti : check log false o repo non letto " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI	
		sleep 5
		exit 1
fi

echo "#JOB QUADR MOV WEB CITT"
#mov_web
while [ $OK -lt 2 ]; do
        if [ -s ${LOGFILE_QUAD}.log ]
         then mv ${LOGFILE_QUAD}.log ${LOGFILE_QUAD}_$(date +%H%m).log
        fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"J_QUAD_ELASTIC_POSTGRES_WEB_OPE" /dir:/SIRED/QUERY_CHECK/WEB_BACK_POSTGRES_OPE /user:admin /pass:admin /level:Basic &>> ${LOGFILE_QUAD}.log

	grep "An\ error\ occured\ loading\ the\ directory\ tree\ from\ the\ repository" ${LOGFILE_QUAD}.log
        if [ $? -eq 0 ]
         then let "OK=$OK + 1"
         else break
        fi
done

if [ $OK -eq 2 ]
 then echo -e "Indice : movimenti \n Job : J_QUAD_ELASTIC_POSTGRES_WEB_OPE \n Tentativi retry job esauriti : repo non letto " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
       sleep 5
       exit 1
fi

#analizzo file di output di JOB QUADRATURA2, se fallito invio mail e stoppo il container
ls /opt/pentaho/check_files/quadratura_ko
if [ $? -eq 0 ]
 then
        echo -e "Indice : movimenti \n Job : J_QUAD_ELASTIC_POSTGRES_WEB_OPE \n I dati non sono allineati " | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
        sleep 5
        exit 1
fi

#se tutto ok faccio rename del DB
echo "alter DB"
alterDB $DB $SIRED_DASH_IP $SIRED_DASH_PORTA $SIRED_DASH_USR $SIRED_DASH_PSW
echo " Alter DB eseguito con successo " | mail -s " DASHBOARD OPERATORE - Nuovi dati online " $DESTINATARI
sleep 10
