#!/bin/bash

AWS_PATH="/opt/aws"
PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/aws/bin:/home/ec2-user/.local/bin:/home/ec2-user/bin"

export AWS_PATH
export PATH

export POSTGRES_IP=pp1b9t82a8i830n.cl10kn47agjy.eu-west-1.rds.amazonaws.com
export POSTGRES_PORT=5432
export POSTGRES_USR=postgres
export POSTGRES_PSW=o8e4t7va34
export ELASTIC_IP=es-dashboard.prod.sardegnaturismocloud.it
export ELASTIC_PORT=9200
export MONGO_IP=127.0.0.1
export MONGO_PORT=27018
export MONGO_DB=sardpen
export TRASF=1

cd /data/repo/kettle && docker-compose up -d
