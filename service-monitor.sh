#!/usr/bin/env bash

# Input variables
NAMESPACE="example.com"
SERVICE="MyService"

# Derived variables
REASON="Failure in monitoring ${SERVICE} on ${NAMESPACE}"
RETVAL=1

# Check if ES is running
# if sudo service elasticsearch status > /dev/null

# Check if httpd is running
if nc -z localhost 80 > /dev/null
then
    REASON="${SERVICE} is running"
    echo "${REASON}"
    RETVAL=0 # "OK"
else
    REASON="${SERVICE} is not running"
    echo "${REASON}"
    RETVAL=1 #"ALARM"
fi

echo "$(date -u) | Alarm status: ${RETVAL} .  Reason: ${REASON}"

aws cloudwatch put-metric-data --metric-name "${SERVICE}" --namespace "${NAMESPACE}" --value ${RETVAL}
