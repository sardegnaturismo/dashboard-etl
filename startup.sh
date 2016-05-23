#!/bin/bash

AWS_PATH="/opt/aws"
PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/aws/bin:/home/ec2-user/.local/bin:/home/ec2-user/bin"

# Settings varables.
export AWS_PATH
export PATH
cd /data && ./settings.sh

# Run containers
cd /data/repo/kettle && docker-compose --file docker-compose-mongo.yml up -d
cd /data/repo/kettle && docker-compose up

# Shutdown the server.
sudo shutdown +10 "ETL finished; halt in 10 minutes"
