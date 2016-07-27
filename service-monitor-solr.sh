#!/usr/bin/env bash

# More information is available : https://gist.github.com/b-long/632c310453b44fc8e785

# If you ever need to confirm that AWS is configured properly, invoke 'aws help' at the
# command line.  This will also verify authentication.

# At installation time, make sure to set the initial alarm state:
# aws cloudwatch set-alarm-state --alarm-name service_alarm --state-value OK --state-reason "Installing ServiceMonitor"

#set -x
RETVAL=1

echo "Checking if Solr is running"

solr_status=$(curl -s -o /dev/null -I -w "%{http_code}" http://localhost:8983/solr/)
if [ "${solr_status}" -eq 200 ]; then
    REASON="Solr (the engine powering search on bioconductor.org) is running"
    echo "${REASON}"
    RETVAL=0 # "OK"
else
    REASON="Solr (the engine powering search on bioconductor.org) is not running"
    echo "${REASON}"
    RETVAL=1 # "ALARM"
fi

/usr/local/bin/aws cloudwatch put-metric-data --metric-name SolrStatus --namespace "master.bioconductor.org" --value "${RETVAL}"

echo "Status: ${RETVAL} sent to CloudWatch at $(date -u)."
exit 0
