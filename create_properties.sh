${PENTAHO_HOME}/data-integration/pan.sh -file="${PENTAHO_HOME}/setup/kettle_properties.ktr" -level=Minimal ${POSTGRES_IP} ${POSTGRES_PORT} ${POSTGRES_USR} ${POSTGRES_PSW} ${MONGO_IP} ${MONGO_PORT} ${MONGO_DB} ${ELASTIC_IP}:${ELASTIC_PORT} ${PENTAHO_HOME}/.kettle/
