#!/bin/bash

#permessi di scrittura per l'utente pentaho sulla directory persistente dei logs
sudo chown -R pentaho:pentaho ${PENTAHO_HOME}/log_caricamenti

#create_repo.sh -> crea repositories.xml
${PENTAHO_HOME}/setup/create_repo.sh
#ls -la ${PENTAHO_HOME}/.kettle
echo "repositories.xml MODIFICATO"
echo " -------------------------------------------- "
#cat ${PENTAHO_HOME}/.kettle/repositories.xml

#create_properties.sh -> crea kettle.properties
${PENTAHO_HOME}/setup/create_properties.sh
sed -i "s/N_MESI=6/N_MESI=${MESI}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
echo "kettle.properties MODIFICATO"
echo " -------------------------------------------- "
#cat ${PENTAHO_HOME}/.kettle/kettle.properties

cp ${PENTAHO_HOME}/.kettle/repositories.xml ${PENTAHO_HOME}/.kettle/kettle.properties ${PENTAHO_HOME}/log_caricamenti

#script di trasformazioni notturne
echo "inizio esecuzione script"
echo "caso valore $TRASF"

case $TRASF in
        1)
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_strutture_estese.sh
        ;;
        2)
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_solid.sh
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_back.sh
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web.sh
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_cittadino/dash_cittadino.sh
        ;;
        3)
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_back.sh
                ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web.sh
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_operatore/dash_operatore.sh
        ;;
        4)
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_solid.sh
                ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_back.sh
                ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web.sh
                ${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_cittadino/dash_cittadino.sh
		${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_operatore/dash_operatore.sh
        ;;
esac
