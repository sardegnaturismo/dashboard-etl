# Update the DNS record based on the new machine's IP.
# For this to work the Name label in EC2 must be equals to the first
# part of the domain name.

DOMAIN="sardegnaturismocloud.it"
HOSTED_ZONE_ID="Z1USAYS3WEYCI8"

INSTANCE_ID=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`;
INSTANCE_NAME=`sudo -u ec2-user aws ec2 describe-instances --region eu-west-1 --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].Tags[?Key==\`Name\`].Value[]' --output text`
MY_DNS_CNAME="$INSTANCE_NAME.$DOMAIN"
PUBLIC_HOSTNAME=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname`
INPUT_JSON="{ \"Comment\": \"Update the CNAME record set\", \"Changes\": [ { \"Action\": \"UPSERT\", \"ResourceRecordSet\": { \"Name\": \"$MY_DNS_CNAME\", \"Type\": \"CNAME\", \"TTL\": 300, \"ResourceRecords\": [ { \"Value\": \"$PUBLIC_HOSTNAME\" } ] } } ] }"

echo "$INPUT_JSON" > /tmp/test.json
sudo -u ec2-user aws route53 change-resource-record-sets --hosted-zone-id "/hostedzone/$HOSTED_ZONE_ID" --change-batch file:///tmp/test.json
