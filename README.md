# AWS VPC Peering & Private Network Connectivity

**Internship Project Submission | AWS Networking | Terraform | Linux**

![AWS](https://img.shields.io/badge/Cloud-AWS-orange?style=flat-square&logo=amazonaws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat-square&logo=terraform)
![Networking](https://img.shields.io/badge/Domain-Cloud%20Networking-blue?style=flat-square)
![Status](https://img.shields.io/badge/Infrastructure-Destroyed-success?style=flat-square)

![AWS VPC Peering Architecture](Screenshots/AWS_VPC_Peering_Architecture.png)

## 1. Project Overview

This project demonstrates the design, deployment, configuration, and validation of private network connectivity between two isolated Amazon Virtual Private Clouds (VPCs) using **AWS VPC Peering**.

The infrastructure was provisioned using Terraform in the AWS Mumbai region. A Bastion Host was deployed in a public subnet to provide controlled SSH access to application instances hosted in private subnets.

The project focused on practical cloud networking concepts, including CIDR planning, subnet architecture, route table configuration, security group management, private communication, connectivity testing, and infrastructure cleanup.

**Project objective:** Establish secure, bidirectional communication between two VPCs without exposing application instances directly to the public internet.

## 2. Business Scenario

Consider an organization operating two separate application environments:

- **Environment A:** Hosts an application server inside a private subnet.
- **Environment B:** Hosts another application server inside a separate VPC.
- Both environments need private network communication.
- Application servers must not have public IP addresses.
- Administrative access must be controlled through a Bastion Host.

The objective is to connect both environments securely without routing application traffic over the public internet.

AWS VPC Peering was selected to establish private communication between the two networks.

## 3. Technology Stack

| Category | Technology |
|---|---|
| Cloud Platform | AWS |
| Networking | Amazon VPC, VPC Peering |
| Compute | Amazon EC2 |
| Network Security | Security Groups |
| Routing | Route Tables, Internet Gateway |
| Infrastructure as Code | Terraform |
| Administration | Linux, SSH |
| Connectivity Testing | ICMP, Ping |
| Region | ap-south-1 (Mumbai) |

## 4. Network Architecture

### VPC-A — Environment A

- VPC CIDR: `10.10.0.0/16`
- Public subnet: `10.10.1.0/24`
- Private subnet: `10.10.2.0/24`
- Bastion Host: `10.10.1.10`
- Application Server A: `10.10.2.10`

### VPC-B — Environment B

- VPC CIDR: `10.20.0.0/16`
- Private subnet: `10.20.1.0/24`
- Application Server B: `10.20.1.10`

### Connectivity Design

- VPC-A and VPC-B are connected through VPC Peering.
- An Internet Gateway provides internet connectivity to the public subnet in VPC-A.
- Private application instances do not have public IP addresses.
- The Bastion Host acts as the administrative entry point.
- Route tables provide bidirectional private network routing.

### Architecture Evidence

![VPC Configuration](Screenshots/SS01_VPCs_CIDRs.png)

## 5. Implementation Methodology

### Phase 1 — VPC and Subnet Provisioning

Created two isolated VPCs with non-overlapping CIDR ranges.

Configured:
- VPC-A and VPC-B.
- Public subnet in VPC-A.
- Private subnets in both VPCs.
- Internet Gateway attached to VPC-A.

**Evidence:**

![VPC Configuration](Screenshots/SS01_VPCs_CIDRs.png)

### Phase 2 — Route Table Configuration

Configured routing for internet access and private communication.

**VPC-A Public Route Table**
- Local route: `10.10.0.0/16`
- Internet route: `0.0.0.0/0` through Internet Gateway.

**VPC-A Private Route Table**
- Local route: `10.10.0.0/16`
- Peering route: `10.20.0.0/16`

**VPC-B Private Route Table**
- Local route: `10.20.0.0/16`
- Peering route: `10.10.0.0/16`

Both sides require appropriate routes for bidirectional connectivity.

**Evidence:**

![Route Tables](Screenshots/SS02_Routes.png)

### Phase 3 — EC2 Instance Deployment

Deployed three EC2 instances:

1. Bastion Host in the public subnet.
2. Application Server A in VPC-A's private subnet.
3. Application Server B in VPC-B's private subnet.

Verified that both application instances had private IP addresses and no public IP addresses.

**Evidence:**

![EC2 Instances](Screenshots/SS03A_EC2_Instances.png)

**Application Server A:**

![Application A](Screenshots/SS03B_AppA_No_Public_IP.png)

**Application Server B:**

![Application B](Screenshots/SS03C_AppB_No_Public_IP.png)

### Phase 4 — VPC Peering Configuration

Established the VPC Peering connection between VPC-A and VPC-B.

Verified that the peering connection reached the active state.

**Evidence:**

![VPC Peering Active](Screenshots/SS04_Peering_Active.png)

### Phase 5 — Security Group Configuration

Configured security groups to control administrative access and application-level network communication.

**Bastion Host**
- SSH access restricted to the administrator's permitted public IP address.

**Application Server A**
- SSH access through the Bastion Host.
- ICMP access according to the configured connectivity requirements.

**Application Server B**
- SSH access through the Bastion Host.
- ICMP access according to the configured connectivity requirements.

**Evidence:**

![Bastion Security Group](Screenshots/SS05A_Bastion_SG.png)

![Application A Security Group](Screenshots/SS05B_AppA_SG.png)

![Application B Security Group](Screenshots/SS05C_AppB_SG.png)

### Phase 6 — SSH Access Validation

Verified administrative access to the Bastion Host and private application instances.

**Bastion Host:**

![Bastion SSH](Screenshots/SS06_Bastion_SSH_Success.png)

**Application Server A:**

![App A SSH](Screenshots/SS07_AppA_SSH_Success.png)

**Application Server B:**

![App B SSH](Screenshots/SS08_AppB_SSH_Success.png)

### Phase 7 — Private Network Connectivity Testing

Tested private communication between application instances in both directions.

**Forward Connectivity: Application A → Application B**

![App A to App B](Screenshots/SS07_AppA_To_AppB_Ping.png)

**Reverse Connectivity: Application B → Application A**

![App B to App A](Screenshots/SS08_AppB_To_AppA_Ping.png)

Successful bidirectional communication demonstrated that the required peering routes and ICMP security group permissions were configured for the tested traffic.

## 6. Troubleshooting and Root Cause Analysis

This section separates the controlled troubleshooting demonstrated in the lab from additional scenarios for further hands-on practice.

### 6.1 Implemented and Verified — ICMP Connectivity Failure

**Problem:** ICMP communication between the application instances was intentionally interrupted by modifying the relevant security group rule.

**Troubleshooting approach:**
1. Tested connectivity using ping.
2. Checked the security group ICMP rule.
3. Identified the missing or modified permission.
4. Restored the required ICMP rule.
5. Retested communication.

**Result:** Connectivity was restored after correcting the security group configuration.

**Failure evidence:**

![Controlled ICMP Failure](Screenshots/SS09_Controlled_ICMP_Failure.png)

**Recovery evidence:**

![ICMP Recovery](Screenshots/SS10_ICMP_Recovery.png)

### 6.2 Additional Troubleshooting Scenarios — Practice Before Claiming as Completed

The following are realistic AWS networking failure scenarios relevant to this architecture. They are included as technical learning and interview preparation scenarios, not as completed project tests.

**Scenario A — VPC Peering Connection Not Active**

Possible symptoms:
- Instances cannot communicate across VPCs.
- Peering connection is pending acceptance or failed.

Investigation:
- Check the peering connection status.
- Verify the requester and accepter VPC IDs.
- Confirm that the connection has been accepted.

Useful command:

```bash
aws ec2 describe-vpc-peering-connections \
  --region ap-south-1
```

Expected resolution: Accept the peering connection when required and verify that its status is `active`.

**Scenario B — Missing Route Table Entry**

Possible symptoms:
- Peering connection is active.
- Security groups appear correct.
- Ping between private instances fails.

Investigation:
- Inspect route tables associated with the source and destination subnets.
- Verify the destination VPC CIDR.
- Verify that the route target is the correct peering connection.

Useful command:

```bash
aws ec2 describe-route-tables \
  --region ap-south-1
```

Expected resolution: Add the missing route to the appropriate route table on each side.

**Scenario C — Security Group Blocking ICMP**

Possible symptoms:
- SSH works.
- Ping fails.

Investigation:
- Inspect inbound ICMP rules on the destination instance's security group.
- Verify the source CIDR or source security group.
- Check outbound rules where applicable.

Useful command:

```bash
aws ec2 describe-security-groups \
  --region ap-south-1
```

Expected resolution: Allow the required ICMP traffic from the intended source.

**Scenario D — Overlapping VPC CIDR Blocks**

Possible symptoms:
- VPC Peering cannot be established between two VPCs.
- AWS reports an overlapping CIDR error.

Investigation:
- Compare the IPv4 CIDR blocks of both VPCs.
- Check for overlapping network ranges.

Expected resolution: Redesign the VPC addressing plan with non-overlapping CIDR ranges before establishing peering.

**Scenario E — SSH Connection Timeout to a Private EC2 Instance**

Possible symptoms:
- Bastion Host is reachable.
- SSH to a private instance times out.

Investigation:
- Check the private instance's security group.
- Verify that SSH is permitted from the Bastion Host.
- Check subnet route tables and network ACLs.
- Verify instance status and SSH service availability.

Useful command on the Bastion Host:

```bash
ssh -i key.pem ec2-user@10.10.2.10
```

Expected resolution: Correct the access rules, network path, or SSH service configuration based on the identified cause.

**Scenario F — Incorrect Return Routing**

Possible symptoms:
- Traffic appears to reach the destination.
- Responses do not return successfully.

Investigation:
- Inspect the destination subnet's route table.
- Verify the route back to the source VPC CIDR.
- Check security groups and network ACLs.

Expected resolution: Ensure that the return path is correctly configured.

## 7. Security Considerations

The following security principles were incorporated into the project design:

- Used separate VPC CIDR ranges to avoid address overlap.
- Kept application instances in private subnets.
- Avoided assigning public IP addresses to application instances.
- Restricted Bastion Host SSH access to an authorized source IP.
- Used security groups to control inbound network traffic.
- Used a Bastion Host for controlled administrative access.
- Avoided exposing private application instances directly to the internet.

**Important design limitation:** VPC Peering is non-transitive. A peered VPC cannot automatically use another VPC's peering connection to reach a third VPC.

## 8. Infrastructure as Code — Terraform

Terraform was used to provision and manage the AWS networking infrastructure.

Main Terraform configuration:

`main.tf`

Deployment workflow:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Cleanup:

```bash
terraform destroy
```

Terraform helped make the infrastructure reproducible and reduced manual configuration work.

## 9. Infrastructure Cleanup and Cost Control

After completing the lab and connectivity verification, the Terraform-managed infrastructure was destroyed.

**Cleanup evidence:**

![Terraform Destroy Completed](<Screenshots/Cleanup verification — Terraform destroy completed.png>)

The screenshot documents the cleanup operation. The AWS resources are not currently deployed as part of this lab.

## 10. Key Learnings

Through this project, I developed practical understanding of:

- AWS VPC architecture and CIDR planning.
- Public and private subnet configuration.
- VPC Peering and private communication.
- Route table configuration and return-path routing.
- Security group configuration and traffic filtering.
- Bastion Host access patterns.
- SSH and ICMP connectivity testing.
- Troubleshooting network connectivity issues.
- Terraform-based infrastructure provisioning.
- AWS resource cleanup and cost awareness.

## 11. Future Improvements

Potential improvements for a production-oriented extension:

- Add VPC Flow Logs for network traffic visibility.
- Integrate CloudWatch monitoring and alarms.
- Use AWS Systems Manager Session Manager for administrative access.
- Store Terraform state remotely with encryption and state locking.
- Introduce automated infrastructure validation through CI/CD.
- Evaluate AWS Transit Gateway for larger multi-VPC network architectures.

These are proposed enhancements, not features currently implemented in this lab.

## 12. Project Status

**Implementation:** Completed

**Connectivity validation:** Completed for the documented tests

**Controlled ICMP troubleshooting:** Demonstrated

**Additional troubleshooting scenarios:** Proposed for further practice

**Infrastructure cleanup:** Completed

## 13. Author

**SK ASIF RAHEMAN**

MCA Graduate | AWS Cloud & DevOps

GitHub: [asifraheman2002](https://github.com/asifraheman2002)

Project Repository: [AWS VPC Peering Lab](https://github.com/asifraheman2002/aws-vpc-peering-lab)

---

*This project was completed as a hands-on cloud networking learning exercise, with Terraform-based provisioning, AWS configuration, connectivity validation, troubleshooting practice, and infrastructure cleanup.*