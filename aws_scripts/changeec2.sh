#!/bin/bash

aws ec2 stop-instances --force --instance-ids $1
aws ec2 wait instance-stopped --instance-ids $1
aws ec2 modify-instance-attribute --instance-id $1 --instance-type "{\"Value\": \""$2"\"}"
aws ec2 start-instances --instance-ids $1
