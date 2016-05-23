#!/bin/bash

AWS_PATH="/opt/aws"
PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/aws/bin:/home/ec2-user/.local/bin:/home/ec2-user/bin"

export AWS_PATH
export PATH
cd /data && ./settings.sh

cd /data/repo/kettle && docker-compose up -d
