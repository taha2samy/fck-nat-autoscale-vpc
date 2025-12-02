
# FCK-NAT High Availability Terraform Setup

This repository contains Terraform configuration to deploy an AWS VPC with a cost-effective, self-healing NAT solution using `fck-nat` within an Auto Scaling Group (ASG).

## Overview

Instead of using the expensive managed AWS NAT Gateway, this setup utilizes a specialized ARM/x86 instance (`fck-nat`) optimized for network address translation. The instance is managed by an Auto Scaling Group to ensure high availability. If the NAT instance terminates, the ASG launches a new one, and a startup script automatically updates the private route table to point to the new instance.

## Architecture

This setup creates the following resources:

*   **VPC:** A custom VPC with IPv4 and IPv6 support.
*   **Subnets:**
    *   **Public Subnet:** Hosted in AZ-1, contains the NAT instance.
    *   **Private Subnet:** Hosted in AZ-2, contains the application workload.
*   **Gateways:**
    *   **Internet Gateway:** For public internet access.
    *   **Egress-Only Internet Gateway:** For IPv6 outbound traffic.
*   **NAT Auto Scaling Group:**
    *   Maintains 1 running `fck-nat` instance.
    *   Uses an IAM Role to allow the instance to modify VPC route tables.
    *   Runs a `user_data` script that automatically replaces the default route (`0.0.0.0/0`) in the private route table with its own Instance ID upon boot.
*   **Private Workload:** A generic Ubuntu EC2 instance located in the private subnet to demonstrate outbound connectivity.

## Prerequisites

*   Terraform installed.
*   AWS CLI configured with appropriate credentials.

## Deployment Instructions

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

2.  **Review the Plan:**
    ```bash
    terraform plan
    ```

3.  **Apply the Configuration:**
    ```bash
    terraform apply
    ```

## Outputs

After applying, Terraform will output the following:

*   `nat_public_ips`: The Public IP of the current NAT instance.
*   `private_app_ip`: The Private IP of the Ubuntu application server.
*   `private_key_path`: The local path to the generated SSH private key (`private_key.pem`).

## How to Connect

The private instance does not have a public IP. To access it, you must use the NAT instance as a bastion/jump host.

1.  **Change key permissions:**
    ```bash
    chmod 400 private_key.pem
    ```

2.  **Connect to the NAT Instance (Bastion):**
    ```bash
    ssh -i private_key.pem ec2-user@<NAT_PUBLIC_IP>
    ```

3.  **From the NAT Instance, connect to the Private Instance:**
    (Note: You will need to forward your agent or copy the key to jump to the next hop).

## Automatic Failover Testing

To test the self-healing capability:
1.  Manually terminate the `fck-nat` instance in the AWS Console.
2.  The Auto Scaling Group will detect the failure and launch a new instance.
3.  The new instance will execute the startup script and take over the `0.0.0.0/0` route in the private route table automatically.