#!/bin/bash
DATA=$(date +%Y%m%d)

sudo /etc/init.d/postfix start
sudo netstat -ntlp

#create_repo.sh -> crea repositories.xml
${PENTAHO_HOME}/setup/create_repo.sh
#ls -la ${PENTAHO_HOME}/.kettle
echo "repositories.xml MODIFICATO"
echo " -------------------------------------------- "
cat ${PENTAHO_HOME}/.kettle/repositories.xml

#create_properties.sh -> crea kettle.properties
${PENTAHO_HOME}/setup/create_properties.sh
echo "kettle.properties MODIFICATO"
echo " -------------------------------------------- "
cat ${PENTAHO_HOME}/.kettle/kettle.properties

#script di trasformazioni notturne
mkdir ${PENTAHO_HOME}/log_caricamenti
echo "inizio esecuzione script"
#da web service a elastic
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_strutture_estese.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_solid.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_back.sh

#da elastic a dashboard pentaho
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_operatore/dash_operatore.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_cittadino/dash_cittadino.sh

# FINE SCRIPT - Invio mail
#zip dei log e file di configurazione
zip -r ContainerKettle_${DATA}.zip ${PENTAHO_HOME}/.kettle/repositories.xml ${PENTAHO_HOME}/.kettle/kettle.properties  ${PENTAHO_HOME}/log_caricamenti
echo "zip fatto"
{ echo " In allegato i file di configurazione di Kettle e i log dei caricamenti ETL " ; uuencode ContainerKettle_${DATA}.zip ContainerKettle_${DATA}.zip ; } | mail -s "Report LOG - Container Kettle Sired" "$DESTINATARI" ;
sleep 300
echo "mail inviata - kill del container"

