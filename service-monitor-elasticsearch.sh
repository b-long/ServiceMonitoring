#!/usr/bin/env bash

# More information is available : https://gist.github.com/b-long/632c310453b44fc8e785

# If you ever need to confirm that AWS is configured properly, invoke 'aws help' at the
# command line.  This will also verify authentication.

# At installation time, make sure to set the initial alarm state:
# aws cloudwatch set-alarm-state --alarm-name service_alarm --state-value OK --state-reason "Installing ServiceMonitor"

#set -x
RETVAL=1

echo "Checking if ElasticSearch is running"

if service elasticsearch status > /dev/null
then
    REASON="ElasticSearch is running"
    echo "${REASON}"
    RETVAL=0 # "OK"
else
    REASON="ElasticSearch is not running, it will be automatically restarted."
    echo "${REASON}"
    RETVAL=1 # "ALARM"
fi

/usr/local/bin/aws cloudwatch put-metric-data --metric-name ElasticSearchStatus --namespace "support.bioconductor.org" --value "${RETVAL}"

echo "Status: ${RETVAL} sent to CloudWatch at $(date -u)."

if [ $RETVAL -eq 1 ]; then
    service elasticsearch start
fi

exit 0
