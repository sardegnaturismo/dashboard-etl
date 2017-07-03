#!/bin/bash

. ${PENTAHO_HOME}/functions/elastic-functions

INIZIO=$(date +%c)
STR_EST_INDEX=strutture_estese
BACK_INDEX=movimenti_back_office
WEB_BACK_INDEX=movimenti_web_back
WEB_INDEX=movimenti

sudo /etc/init.d/postfix start
 
echo "Inizio esecuzione : $INIZIO" | mail -s " DASHBOARD OPERATORE - Inizio aggiornamento " $DESTINATARI

#permessi di scrittura per l'utente pentaho sulla directory persistente dei logs
#e sulla directory persistente dei file di output su cui fare i check
sudo chown -R pentaho:pentaho ${PENTAHO_HOME}/log_caricamenti ${PENTAHO_HOME}/check_files

#create_repo.sh -> crea repositories.xml
${PENTAHO_HOME}/setup/create_repo.sh
echo "repositories.xml GENERATO"
echo " -------------------------------------------- "

#modifiche al kettle.properties
${PENTAHO_HOME}/setup/sed_env_var.sh
echo "kettle.properties e repositories.xml MODIFICATI"
echo " -------------------------------------------- "

#update IP ElasticSearch in Postgres
${PENTAHO_HOME}/setup/update_ip.sh
if [ $? -eq 0 ]
 then
        echo "ip/porta/clustername AGGIORNATI"
        echo " -------------------------------------------- "
 else exit
fi

cp ${PENTAHO_HOME}/.kettle/repositories.xml ${PENTAHO_HOME}/.kettle/kettle.properties ${PENTAHO_HOME}/log_caricamenti
cd ${PENTAHO_HOME}/log_caricamenti
zip $(date +%Y%m%d).zip *.log  
rm -f *.log

#trasformazioni ETL - Dashboard OPERATORE
echo "inizio esecuzione trasformazioni $(date)"
echo " -------------------------------------------- "
# ETL 1: Mongo ---> ElasticSearch
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_strutture_estese.sh

if [ $? -eq 0 ]
 then ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_back.sh
 else 
        echo "revert index str-est $(date)"
        revertIndexes $STR_EST_INDEX
	exit
fi

if [ $? -eq 0 ]
 then ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web_back.sh
 else 
	echo "revert index str-est/back/web-back $(date)"
        revertIndexes $STR_EST_INDEX
        revertIndexes $BACK_INDEX
        revertIndexes $WEB_BACK_INDEX
	exit
fi

if [ $? -eq 0 ]
 then ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web.sh
 else
        echo "revert index str-est/back/web-back $(date)"
        revertIndexes $STR_EST_INDEX
        revertIndexes $BACK_INDEX
        revertIndexes $WEB_BACK_INDEX
        exit
fi

#se tutti gli script sono andati a buon fine ----> sposto tutti gli alias da _live a _work
#ed eseguo ETL 2: ElasticSearch ---> PostgreSQL
if [ $? -eq 0 ]
 then
	echo "change AliasToWork"
	changeAliasToWork $STR_EST_INDEX
	changeAliasToWork $BACK_INDEX
	changeAliasToWork $WEB_BACK_INDEX
	changeAliasToWork $WEB_INDEX
	aliasInWork $STR_EST_INDEX
	VAL=$?
	aliasInWork $BACK_INDEX
	let "VAL = $VAL + $?"
	aliasInWork $WEB_BACK_INDEX
	let "VAL = $VAL + $?"
        aliasInWork $WEB_INDEX
        let "VAL = $VAL + $?"
	if [ $VAL -eq 0 ]
 	 then 
		echo "Eseguo dash operatore - inizio : $(date)"
		echo " -------------------------------------------- "
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_operatore/dash_operatore.sh
		#se è andato tutto bene copiare live in old, droppare live, copiare work in live e doppare work (per ogni indice)
		#oppure spostare l'alias da work a live e droppare work
		if [ $? -eq 0 ]
	 	then
        		echo "prepare index $(date)"
        		prepareIndexes $STR_EST_INDEX
        		prepareIndexes $BACK_INDEX
        		prepareIndexes $WEB_BACK_INDEX
        		prepareIndexes $WEB_INDEX
                        echo -e "Inizio esecuzione : $INIZIO \n Fine esecuzione : $(date +%c) \n Controllare l'esito dell'alter DB nella mail precedente " | mail -s " DASHBOARD OPERATORE - Aggiornamento terminato " $DESTINATARI
			sleep 5
         	else
			# Ramo else delle quadrature operatore fallite
        		echo "revert index str-est/back/web-back/web $(date)"
			revertIndexes $STR_EST_INDEX
	        	revertIndexes $BACK_INDEX
			revertIndexes $WEB_BACK_INDEX
			revertIndexes $WEB_INDEX
		fi
 	 else
	        echo "revert index str-est/back/web-back/web $(date)"
        	revertIndexes $STR_EST_INDEX
	        revertIndexes $BACK_INDEX
        	revertIndexes $WEB_BACK_INDEX
        	revertIndexes $WEB_INDEX
                echo -e "Job : J_DASH_OPERATORE_FAST non eseguito \n Probabile errore di comunicazione con Elastic" | mail -s " DASHBOARD OPERATORE - Aggiornamento fallito " $DESTINATARI
        	sleep 5
	fi
 else
        echo "revert index str-est/back/web-back/web $(date)"
        revertIndexes $STR_EST_INDEX
        revertIndexes $BACK_INDEX
        revertIndexes $WEB_BACK_INDEX
        revertIndexes $WEB_INDEX
fi

echo "FINE $(date)"
