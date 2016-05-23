#!/bin/bash
DIM=$( ls -l /opt/pentaho/log_caricamenti/dash_cittadino.log | awk -F' ' '{print $5}' )
DATA=$(date +%Y%m%d)
#Se il file supera i 10M crea un archivio
if [ $DIM -gt 10485760 ]
        then
                tar -czvf /opt/pentaho/log_caricamenti/dash_cittadino.log.${DATA}.tgz /opt/pentaho/log_caricamenti/dash_cittadino.log
                rm -f /opt/pentaho/log_caricamenti/dash_cittadino.log
fi
nohup /opt/pentaho/data-integration/kitchen.sh /rep:"sired_pdi_repo" /job:"J_DASH_CITTADINO" /dir:/SIRED/DASHBOARD/CITTADINO /user:admin /pass:admin /level:Basic >> /opt/pentaho/log_caricamenti/dash_cittadino.log
