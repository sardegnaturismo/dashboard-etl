#!/bin/bash
DIM=$( ls -l /opt/pentaho/log_caricamenti/regime_strutt_estese.log | awk -F' ' '{print $5}' )
DATA=$(date +%Y%m%d)
#Se il file supera i 10M crea un archivio
if [ $DIM -gt 10485760 ]
        then
                tar -czvf /opt/pentaho/log_caricamenti/regime_strutt_estese.log.${DATA}.tgz /opt/pentaho/log_caricamenti/regime_strutt_estese.log
		rm -f /opt/pentaho/log_caricamenti/regime_strutt_estese.log
fi
nohup /opt/pentaho/data-integration/kitchen.sh /rep:"sired_pdi_repo" /job:"JOB_REGIME_STRUTTURE" /dir:/SIRED/REGIME/STRUTTURA_ESTESA /user:admin /pass:admin /level:Basic >> /opt/pentaho/log_caricamenti/regime_strutt_estese.log
