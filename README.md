# ServiceMonitoring
Service monitoring resources

[![Build Status](https://travis-ci.org/b-long/ServiceMonitoring.svg?branch=master)](https://travis-ci.org/b-long/ServiceMonitoring)

Amazon's CloudWatch is great for monitoring network, disk and CPU utilization, but what about at the application level?  If you want to alert on an application, service, or any other wiz-bang metric, you'll need to make a custom CloudWatch alarm & metric.

Let's say I want to know if ElasticSearch is running.  To do that, navigate to the AWS CloudWatch UI & create a metric named "ElasticSearchStatus" and the alarm "search_status".  Next, define the alarm bounds (throughout this gist, we'll use 0 to indicate healthiness and 1 to indicate an error condition ): 
```
Whenever: ElasticSearchStatus
is: >= 1
for: 1 consecutive period(s)
```
Don't forget to define the length of the period (I recommend using 5 minutes) and which statistic you want to act on.  Since I'm simply monitoring that a service is up, I select the statistic "Average".  In this example, we aren't interested in a Minimum, Maximum or Sum.  We want to know when the _Average_ data sent is >= 1, if it is, that's a problem.  Our monitor (the ElasticSearch server) will send data every 2 minutes and CloudWatch will evaluate the data sent every 5.  

Ensure the AWS cli tool is installed on your server.  Then, mimic a healthy state of the cron job you'll build by backgrounding a command (note the trailing `&`) :
```shell
while true; do sleep 2; aws cloudwatch put-metric-data --metric-name ElasticSearchStatus --namespace "feed-a-hipster.com" --value 0; done &
```

Set the alarm's initial state before you install your cron job : 
```shell
aws cloudwatch set-alarm-state --alarm-name search_status --state-value OK --state-reason "Initial alarm state"
```

Create a shell script (to be executed by cron) and save it as /usr/bin/my-monitor.sh : 
```shell
#!/usr/bin/env bash

REASON="Failure in monitoring ElasticSearch on feed-a-hipster.com"
RETVAL=1
# Check if ES is running
if sudo service elasticsearch status > /dev/null
then
    REASON="ElasticSearch is running"
    echo "${REASON}"
    RETVAL=0 # "OK"
else
    REASON="ElasticSearch is not running"
    echo "${REASON}"
    RETVAL=1 #"ALARM"
fi

echo "ES status: ${RETVAL} .  Reason: ${REASON}"

aws cloudwatch put-metric-data --metric-name ElasticSearchStatus --namespace "feed-a-hipster.com" --value "${RETVAL}"
```
And finally, add an entry to the crontab to run that script every 2 minutes: 
```
*/2 * * * * /usr/bin/my-monitor.sh >> /var/log/aws-elastic-monitor.log 2>&1
```
Next, make sure to cleanup that fake job we created (use the Linux command `jobs` to find and kill it).  And that's it, you're done, hipsters won't go hungry!  Just sit back and wait for alerts (which are inevitable, but hopefully won't happen for a long time).
