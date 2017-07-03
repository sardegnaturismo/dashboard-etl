#!/bin/bash
. ${PENTAHO_HOME}/functions/postgres-functions

DB=${DASH_TARGET}

LOGFILE_JOB="/opt/pentaho/log_caricamenti/dash_cittadino"
LOGFILE_QUAD_SOLID="/opt/pentaho/log_caricamenti/quad_solid_dash_cittadino"
LOGFILE_QUAD_WEB="/opt/pentaho/log_caricamenti/quad_web_dash_cittadino"
LOGFILE_ALTERDB="/opt/pentaho/log_caricamenti/alterdb.log"
DATA=$(date +%Y/%m/%d)

echo "INIZIO DASH CITTADINO $(date)"

RETRY=0
CONNECTION=0
OK_SOLID=0
OK_WEB=0

while [ $CONNECTION -lt 4 ] && [ $RETRY -lt 2 ]; do

	echo "$(date) : CONNESSIONI = $CONNECTION RETRY = $RETRY"

        if [ -s ${LOGFILE_JOB}.log ]
         then mv ${LOGFILE_JOB}.log ${LOGFILE_JOB}_$(date +%H%m).log
        fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"J_DASH_CITTADINO_FAST_V1" /dir:/SIRED/DASHBOARD/NEW_CITTADINO_FAST /user:admin /pass:admin /level:Basic &> ${LOGFILE_JOB}.log
	
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
                	grep "${DATA}.*J_DASH_CITTADINO_FAST_V1\ -\ Terminata\ jobentry.*\(risultato=\[false\]\)" ${LOGFILE_JOB}.log
        		if [ $? -ne 0 ]
         	 	 then break
         	 	 else let "RETRY=$RETRY + 1"
        		fi
		fi
	fi
done

if [ $CONNECTION -eq 4 ]
 then echo -e "Job : J_DASH_CITTADINO_FAST_V1 \n Tentativi connessione esauriti" | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
	sleep 5
	exit 1
 elif [ $RETRY -eq 2 ]
	then echo -e "Job : J_DASH_CITTADINO_FAST_V1 \n Tentativi retry job esauriti : check log false o repo non letto " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI	
		sleep 5
		exit 1
fi

echo "#JOB QUADR MOV SOLID CITT"
#mov_solid
while [ $OK_SOLID -lt 2 ]; do
	if [ -s ${LOGFILE_QUAD_SOLID}.log ]
  	 then mv ${LOGFILE_QUAD_SOLID}.log ${LOGFILE_QUAD_SOLID}_$(date +%H%m).log
 	fi

 	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"J_QUAD_POSTGRES_ELASTIC_SOLID_ELAP" /dir:/SIRED/QUERY_CHECK/SOLID_POSTGRES /user:admin /pass:admin /level:Basic &>> ${LOGFILE_QUAD_SOLID}.log

	grep "An\ error\ occured\ loading\ the\ directory\ tree\ from\ the\ repository" ${LOGFILE_QUAD_SOLID}.log
        if [ $? -eq 0 ]
         then let "OK_SOLID=$OK_SOLID + 1"
         else break
        fi
done

if [ $OK_SOLID -eq 2 ]
 then echo -e "Indice : movimenti_solid \n Job : J_QUAD_POSTGRES_ELASTIC_SOLID_ELAP \n Tentativi retry job esauriti : repo non letto " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
       sleep 5
       exit 1
fi

#analizzo file di output di JOB QUADRATURA2, se fallito invio mail e stoppo il container
ls /opt/pentaho/check_files/quadratura_ko
if [ $? -eq 0 ]
 then
	echo -e "Indice : movimenti \n Job : J_QUAD_POSTGRES_ELASTIC_SOLID_ELAP \n I dati non sono allineati " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
        sleep 5
        exit 1
fi

echo "#JOB QUADR MOV WEB CITT"
#mov_web
while [ $OK_WEB -lt 2 ]; do
        if [ -s ${LOGFILE_QUAD_WEB}.log ]
         then mv ${LOGFILE_QUAD_WEB}.log ${LOGFILE_QUAD_WEB}_$(date +%H%m).log
        fi

	nohup /opt/pentaho/data-integration/kitchen.sh /rep:"${POSTGRES_REPO}" /job:"J_QUAD_POSTGRES_WEB" /dir:/SIRED/QUERY_CHECK/WEB_POSTGRES /user:admin /pass:admin /level:Basic &>> ${LOGFILE_QUAD_WEB}.log

	grep "An\ error\ occured\ loading\ the\ directory\ tree\ from\ the\ repository" ${LOGFILE_QUAD_WEB}.log
        if [ $? -eq 0 ]
         then let "OK_WEB=$OK_WEB + 1"
         else break
        fi
done

if [ $OK_WEB -eq 2 ]
 then echo -e "Indice : movimenti \n Job : J_QUAD_POSTGRES_WEB \n Tentativi retry job esauriti : repo non letto " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
       sleep 5
       exit 1
fi

#analizzo file di output di JOB QUADRATURA2, se fallito invio mail e stoppo il container
ls /opt/pentaho/check_files/quadratura_ko
if [ $? -eq 0 ]
 then
        echo -e "Indice : movimenti \n Job : J_QUAD_POSTGRES_WEB \n I dati non sono allineati " | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI
        sleep 5
        exit 1
fi

#se tutto ok faccio rename del DB
${PENTAHO_HOME}/setup/alter_db.sh

if [ $? -eq 0 ]; then
    echo " Alter DB eseguito con successo " | mail -s " DASHBOARD CITTADINO - Nuovi dati online " $DESTINATARI
    echo " alterDB() eseguito con successo " > ${LOGFILE_ALTERDB}
else
    cat ${PENTAHO_HOME}/setup/alter_db_ko.txt | mail -s " DASHBOARD CITTADINO - Dati validati, alter DB fallito " $DESTINATARI
    cat ${PENTAHO_HOME}/setup/alter_db_ko.txt > ${LOGFILE_ALTERDB} 
fi
sleep 10
