#!/bin/bash

# Fetch all instances id

Instances=$(aws ec2 describe-instances |jq -r '.Reservations[].Instances[].InstanceId')
echo "Instance Id: $Instances"

for ec2_instance in $Instances;
do
 # list state of instance
 instance_state=$(aws ec2 describe-instances --instance-ids $ec2_instance | jq -r '.Reservations[].Instances[].State.Name')
     # Check if the state is "stopped"
    if [ "$instance_state" == "stopped" ]; then
        echo "Instance $ec2_instance is in the stopped state. Starting it..."
        # Start the instance
        aws ec2 start-instances --instance-ids $ec2_instance
    else
        echo "Instance $ec2_instance is in the $instance_state state. No action taken."
    fi
done

