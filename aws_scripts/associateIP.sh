#/bin/bash

FROM_INSTANCE=$1
DEST_INSTANCE=$2
ELASTIC_IP=$(aws ec2 describe-instances --instance-ids $FROM_INSTANCE --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
NEW_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $DEST_INSTANCE --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
aws ec2 disassociate-address --public-ip $ELASTIC_IP
aws ec2 start-instances --instance-ids $DEST_INSTANCE
aws ec2 wait instance-running --instance-ids $DEST_INSTANCE
aws ec2 associate-address --public-ip $ELASTIC_IP --instance-id $DEST_INSTANCE --private-ip-address $NEW_PRIVATE_IP
aws ec2 stop-instances --instance-ids $FROM_INSTANCE
