#!/bin/bash

# Fetch all instance ids
Instances=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[].InstanceId')
echo "Instance IDs: $Instances"

# Loop through instances
for ec2_instance in $Instances; do
    # Get list of volumes attached to instance
    volumes=$(aws ec2 describe-instances --instance-ids "$ec2_instance" | jq -r '.Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId')

    # Convert volumes into a comma-separated list
    volumes_list=$(echo "$volumes" | paste -sd ',' -)

    echo "Volumes attached to instance $ec2_instance: $volumes_list"

    # Loop through volumes
    for volume in $volumes; do
        # Get list of device names attached to the volume
        Device_name=$(aws ec2 describe-volumes --volume-id "$volume" | jq -r '.Volumes[].Attachments[].Device')
        echo "Device name $Device_name is attached to volume $volume of instance $ec2_instance"

        # Check if volume is not root volume
        if [[ "$Device_name" != "/dev/xvda" && "$Device_name" != "/dev/sda1" ]]; then
            echo "Creating snapshot for volume: $volume (Device: $Device_name)"
            
            # Create snapshot of volume
            snapshot_id=$(aws ec2 create-snapshot --volume-id "$volume" --description "Backup snapshot for $volume attached to $ec2_instance" | jq -r '.SnapshotId')
            # test expression [-n "$string"] : Evaluates to true if the string is not empty (i.e., the length of the string is greater than zero).
            if [ -n "$snapshot_id" ]; then
                echo "Snapshot $snapshot_id created successfully for volume $volume of instance $ec2_instance"
            fi
        else
            echo "Volume $volume is a root volume ($Device_name). Skipping snapshot creation."
        fi
    done
done
