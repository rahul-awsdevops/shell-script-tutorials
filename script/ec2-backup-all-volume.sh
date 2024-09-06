#!/bin/bash

# Fetch all instance IDs
Instances=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[].InstanceId')
echo "Instance IDs: $Instances"

# Loop through instances
for ec2_instance in $Instances; do
    # Get list of volumes attached to the instance
    volumes=$(aws ec2 describe-instances --instance-ids "$ec2_instance" | jq -r '.Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId')

    # Convert volumes into a comma-separated list
    volumes_list=$(echo "$volumes" | paste -sd ',' -)
    echo "Volumes attached to instance $ec2_instance: $volumes_list"

    # Loop through each volume
    for volume in $volumes; do
        # Get the device name associated with the volume
        Device_name=$(aws ec2 describe-volumes --volume-id "$volume" | jq -r '.Volumes[].Attachments[].Device')
        echo "Device name $Device_name is attached to volume $volume of instance $ec2_instance"

        # Create a snapshot for the volume (both root and non-root)
        echo "Creating snapshot for volume: $volume (Device: $Device_name)"
        snapshot_id=$(aws ec2 create-snapshot --volume-id "$volume" --description "Backup snapshot for $volume attached to $ec2_instance" | jq -r '.SnapshotId')

        # Check if the snapshot was created successfully
        if [ -n "$snapshot_id" ]; then
            echo "Snapshot $snapshot_id created successfully for volume $volume of instance $ec2_instance"
        else
            echo "Failed to create snapshot for volume $volume of instance $ec2_instance"
        fi
    done
done
