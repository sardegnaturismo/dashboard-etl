#!/bin/bash

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
echo "avvio caricamenti ETL"
#da web service a elastic
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_strutture_estese.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_web.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_solid.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_elasticsearch/regime_movimenti_back.sh

#da elastic a dashboard pentaho
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_operatore/dash_operatore.sh
${PENTAHO_HOME}/setup/scripts_trasformazioni/regime_cittadino/dash_cittadino.sh

echo "script terminati"
