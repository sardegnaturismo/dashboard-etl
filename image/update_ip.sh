#!/bin/bash

. ${PENTAHO_HOME}/functions/postgres-functions

IP=$(host $ELASTIC_IP | grep 'has address' | awk '{ print $4}')
echo "IP è $IP"
if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
	updateIP $POSTGRES_REPO $POSTGRES_IP $POSTGRES_PORTA $POSTGRES_USR $POSTGRES_PSW $IP 
else 
	echo -e "In fase di update dell'IP di ElasticSearch nel DB Postgres non è stato possibile determinare l'IP di $ELASTIC_IP" | mail -s " DASHBOARD CITTADINO - Aggiornamento fallito " $DESTINATARI	
	sleep 10
	exit 1
fi

updatePORT $POSTGRES_REPO $POSTGRES_IP $POSTGRES_PORTA $POSTGRES_USR $POSTGRES_PSW $ELASTIC_INT_PORT

updateCLUSTERNAME $POSTGRES_REPO $POSTGRES_IP $POSTGRES_PORTA $POSTGRES_USR $POSTGRES_PSW $ELASTIC_CLUSTERNAME
