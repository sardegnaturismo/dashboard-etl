#!/bin/bash
DIM=$( ls -l /opt/pentaho/log_caricamenti/regime_mov_solid.log | awk -F' ' '{print $5}' )
DATA=$(date +%Y%m%d)
#Se il file supera i 10M crea un archivio
if [ $DIM -gt 10485760 ]
        then
                tar -czvf /opt/pentaho/log_caricamenti/regime_mov_solid.log.${DATA}.tgz /opt/pentaho/log_caricamenti/regime_mov_solid.log
                rm -f /opt/pentaho/log_caricamenti/regime_mov_solid.log
fi
nohup /opt/pentaho/data-integration/kitchen.sh /rep:"sired_pdi_repo" /job:"JOB_REGIME_MOVIMENTI_SOLID" /dir:/SIRED/REGIME/MOVIMENTI_SOLID /user:admin /pass:admin /level:Basic >> /opt/pentaho/log_caricamenti/regime_mov_solid.log
