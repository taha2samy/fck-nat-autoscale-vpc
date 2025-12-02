#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting FCK-NAT Auto-configuration..."

REGION="${region}"
RTB_ID="${route_table_id}"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# CORRECTED IP ADDRESS BELOW
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

echo "Instance ID: $INSTANCE_ID"
echo "Target Route Table: $RTB_ID"

aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --no-source-dest-check --region $REGION

ROUTE_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --region $REGION --output json | jq -r '.RouteTables[0].Routes[] | select(.DestinationCidrBlock == "0.0.0.0/0") | if . then "true" else "false" end' | grep "true")

if [ "$ROUTE_EXISTS" == "true" ]; then
    echo "Route for 0.0.0.0/0 already exists. Replacing it..."
    aws ec2 replace-route \
        --route-table-id $RTB_ID \
        --destination-cidr-block 0.0.0.0/0 \
        --instance-id $INSTANCE_ID \
        --region $REGION
else
    echo "Route for 0.0.0.0/0 not found. Creating it..."
    aws ec2 create-route \
        --route-table-id $RTB_ID \
        --destination-cidr-block 0.0.0.0/0 \
        --instance-id $INSTANCE_ID \
        --region $REGION
fi

if [ $? -eq 0 ]; then
    echo "Route successfully configured for instance $INSTANCE_ID in route table $RTB_ID."
else
    echo "ERROR: Failed to configure route." >&2
fi

ENI_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/mac)/interface-id)
echo "eni_id=$ENI_ID" >> /etc/fck-nat.conf

service fck-nat restart

echo "Setup Complete."