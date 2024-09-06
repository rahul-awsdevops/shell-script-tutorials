#!/bin/bash

# Fetch instance details, filter stopped instances, and store them in a variable
stopped_instances=$(aws ec2 describe-instances \
    | jq -r '.Reservations[].Instances[] | [.InstanceId, .State.Name] | @tsv' \
    | awk -F "\t" '$2 == "stopped" {print $1}')

# Loop through each stopped instance ID and start it
for instance_id in $stopped_instances; do
    echo "Starting instance: $instance_id"
    aws ec2 start-instances --instance-ids "$instance_id"
done
