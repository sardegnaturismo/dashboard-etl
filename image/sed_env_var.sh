#!/bin/bash

# UPDATE repositories.xml
sed -i "s/sired_pdi_repo/${POSTGRES_REPO}/g" ${PENTAHO_HOME}/.kettle/repositories.xml

# UPDATE kettle.properties
sed -i "s#SIRED_MONTLY_ACTIVITY_URL=SIRED_MONTLY_ACTIVITY_URL#SIRED_MONTLY_ACTIVITY_URL=${SIRED_MONTLY_ACTIVITY_URL}#g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s/ELASTIC_IP:ELASTIC_PORT/${ELASTIC_IP}:${ELASTIC_PORT}/g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s/SIRED_DASH_IP=SIRED_DASH_IP/SIRED_DASH_IP=${SIRED_DASH_IP}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_DASH_DB=SIRED_DASH_DB/SIRED_DASH_DB=${SIRED_DASH_DB}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_DASH_PORTA=SIRED_DASH_PORTA/SIRED_DASH_PORTA=${SIRED_DASH_PORTA}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_DASH_USR=SIRED_DASH_USR/SIRED_DASH_USR=${SIRED_DASH_USR}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_DASH_PSW=SIRED_DASH_PSW/SIRED_DASH_PSW=${SIRED_DASH_PSW}/g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s/SIRED_STG_IP=SIRED_STG_IP/SIRED_STG_IP=${SIRED_STG_IP}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_STG_DB=SIRED_STG_DB/SIRED_STG_DB=${SIRED_STG_DB}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_STG_PORTA=SIRED_STG_PORTA/SIRED_STG_PORTA=${SIRED_STG_PORTA}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_STG_USR=SIRED_STG_USR/SIRED_STG_USR=${SIRED_STG_USR}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_STG_PSW=SIRED_STG_PSW/SIRED_STG_PSW=${SIRED_STG_PSW}/g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s/N_MESI=6/N_MESI=${MESI}/g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s/SIRED_MONGO_DB=SIRED_MONGO_DB/SIRED_MONGO_DB=${SIRED_MONGO_DB}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_MONGO_IP=SIRED_MONGO_IP/SIRED_MONGO_IP=${SIRED_MONGO_IP}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/SIRED_MONGO_PORTA=SIRED_MONGO_PORTA/SIRED_MONGO_PORTA=${SIRED_MONGO_PORTA}/g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s/MONGO_ANAGRAFE_DB=MONGO_ANAGRAFE_DB/MONGO_ANAGRAFE_DB=${MONGO_ANAGRAFE_DB}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/MONGO_ANAGRAFE_IP=MONGO_ANAGRAFE_IP/MONGO_ANAGRAFE_IP=${MONGO_ANAGRAFE_IP}/g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s/MONGO_ANAGRAFE_PORTA=MONGO_ANAGRAFE_PORTA/MONGO_ANAGRAFE_PORTA=${MONGO_ANAGRAFE_PORTA}/g" ${PENTAHO_HOME}/.kettle/kettle.properties

sed -i "s#SIRED_ELA_TEST_CON=SIRED_ELA_TEST_CON#SIRED_ELA_TEST_CON=${SIRED_ELA_TEST_CON}#g" ${PENTAHO_HOME}/.kettle/kettle.properties
sed -i "s#SIRED_WS_TEST_CON=SIRED_WS_TEST_CON#SIRED_WS_TEST_CON=${SIRED_WS_TEST_CON}#g" ${PENTAHO_HOME}/.kettle/kettle.properties
