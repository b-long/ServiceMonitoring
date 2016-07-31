# ServiceMonitoring
Service monitoring resources

[![Build Status](https://travis-ci.org/b-long/ServiceMonitoring.svg?branch=master)](https://travis-ci.org/b-long/ServiceMonitoring)

# Intro

Amazon's CloudWatch is great for monitoring network, disk and CPU utilization, but what about at the application level?  If you want to alert on an application, service, or any other wiz-bang metric, you'll need to make a custom CloudWatch alarm & metric.

## Variables

The installation procedures below assume the  following variables.  Please modify as you see fit:
```
Namespace: example.com
MetricName: MyService
```

## Installation

* First, install the AWS Command Line Interface.  Instructions are available : **[here](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)**.
  * Note, if you're running within an EC2 instance, this may be unnecessary


* Verify the installation.  **ServiceMonitoring** requires AWS CLI version 1.10.33 or newer.

  ```shell
  $ [ec2-user@host ~]$ aws --version
  # Output: aws-cli/1.10.33 Python/2.7.10 Linux/4.4.11-23.53.amzn1.x86_64 botocore/1.4.23
  ```

* Create an IAM user to execute the **ServiceMonitoring** application.

  * <u>Note</u>: This feature is offered for free from Amazon, per **[this page](https://aws.amazon.com/iam/faqs/)**.

  * Grant the appropriate permissions to this new user by creating a "Policy", using this JSON:  

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "MetricsAccess",
                "Action": [
                    "cloudwatch:*"
                ],
                "Effect": "Allow",
                "Resource": [
                    "*"
                ]
            }
        ]
    }
    ```


* Create user account on the host
  * Next, follow the appropriate steps to create a user account on the target machine (this is the host you're planning to monitor).
  * After the user is created, follow the appropriate steps to configure the AWS CLI
  * Linux users can follow the outline below:  
  ```shell
  [ec2-user@ip-172-31-6-208 ~]$ sudo adduser servicemonitor
  [ec2-user@ip-172-31-6-208 ~]$ sudo su - servicemonitor
  [servicemonitor@ip-172-31-6-208 ~]$ which aws
  /usr/bin/aws
  [servicemonitor@ip-172-31-6-208 ~]$ aws configure
  AWS Access Key ID [None]: # Omitted
  AWS Secret Access Key [None]: # Omitted
  Default region name [None]: # Omitted
  Default output format [None]: # Unnecessary
  ```


* *Create* the initialization data for our custom metric first.  Note, custom metrics are documented **<u>[*here*](https://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/publishingMetrics.html)</u>**.

  ```
  aws cloudwatch put-metric-data --metric-name MyService --namespace "example.com" --value 0
  ```


* Navigate to the main CloudWatch and click "Create Alarm"

  - From the "*Custom Metrics*" dropdown, choose your namespace
  - Select your metric "***MyService***"
  - Click "***Next***"
  - Enter the ***name*** for your alarm "wordpress_status", enter some ***description***.

* Install the software

  * As the newly minted `servicemonitor` user, execute the following

    ```shell
    cd $HOME
    git clone https://github.com/b-long/ServiceMonitoring.git
    cd ServiceMonitoring
    # At this point, you may need to configure service-monitor.sh
    #		Note that variables may require modification

    # Once the script is configured, ensure the monitor script is
    # marked as executable
    chmod +x service-monitor.sh

    # Create the log file
    touch ~/service-monitor.log
    ```

* Configure Cron

  * Copy and paste the contents of `service-monitor.crontab` into the actual users's crontab entry


#### Configuring the Alarm

Let's say I want to know if ElasticSearch is running.  To do that, navigate to the AWS CloudWatch UI & create a metric named "MyService" and the alarm "service_alarm".  Next, define the alarm bounds (throughout this gist, we'll use 0 to indicate healthiness and 1 to indicate an error condition ):
```
Whenever: MyService
is: >= 1
for: 1 consecutive period(s)
```
Don't forget to define the length of the period (I recommend using 5 minutes) and which statistic you want to act on.  Since I'm simply monitoring that a service is up, I select the statistic "Average".  In this example, we aren't interested in a Minimum, Maximum or Sum.  We want to know when the _Average_ data sent is >= 1, if it is, that's a problem.  Our monitor (the ElasticSearch server) will send data every 2 minutes and CloudWatch will evaluate the data sent every 5.  

#### Alarm Initialization

Ensure service-monitor.sh is configured properly.  Then, mimic a healthy state of the cron job you'll build by backgrounding a command (note the trailing `&`) :

```shell
while true; do sleep 2; aws cloudwatch put-metric-data --metric-name MyService --namespace "example.com" --value 0; done &
```

Set the alarm's initial state before you install your cron job :
```shell
aws cloudwatch set-alarm-state --alarm-name service_alarm --state-value OK --state-reason "Installing ServiceMonitor"
```

Next, make sure to cleanup that fake job we created (use the Linux command `jobs` to find and kill it).  And that's it, you're done, hipsters won't go hungry!  Just sit back and wait for alerts (which are inevitable, but hopefully won't happen for a long time).



### Roadmap

* Configurable alarm templates ([see issue #4](https://github.com/b-long/ServiceMonitoring/issues/4#issuecomment-235489329)).
* Additional configuration options
* Additional service integrations

  ​
