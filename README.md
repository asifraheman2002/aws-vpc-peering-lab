# AWS VPC Peering Lab --- EWB AWS Networking

**Author:** SK Asif Raheman\
**AWS Region:** `ap-south-1` (Mumbai)\
**Project status:** Lab completed; AWS resources were destroyed after
testing.

## 1. Overview

I built this lab to practise private connectivity between two Amazon
VPCs using VPC Peering. VPC-A contains a public bastion host and a
private App-A instance. VPC-B contains a private App-B instance. I
configured routing and security-group rules, then tested SSH and ICMP
connectivity using private IP addresses.

> **Important:** Screenshots show the environment during the lab, not currently running resources. Never commit private keys, credentials, Terraform state files, or secrets.

## 2. Network design

  Component              CIDR / private IP   Purpose
  ---------------------- ------------------- -------------------------------
  VPC-A                  `10.10.0.0/16`      Bastion and App-A network
  VPC-A public subnet    `10.10.1.0/24`      Bastion subnet
  VPC-A private subnet   `10.10.2.0/24`      App-A subnet
  VPC-B                  `10.20.0.0/16`      Peered VPC
  VPC-B private subnet   `10.20.1.0/24`      App-B subnet
  Bastion                `10.10.1.10`        Public SSH entry point
  App-A                  `10.10.2.10`        Private EC2 instance in VPC-A
  App-B                  `10.20.1.10`        Private EC2 instance in VPC-B

App-A and App-B were configured without public IP addresses. The
Internet Gateway was attached to VPC-A.

## 3. Route tables

  Route table     Subnet association   Destination      Target
  --------------- -------------------- ---------------- ------------------
  VPC-A public    `10.10.1.0/24`       `10.10.0.0/16`   `local`
  VPC-A public    `10.10.1.0/24`       `0.0.0.0/0`      Internet Gateway
  VPC-A private   `10.10.2.0/24`       `10.10.0.0/16`   `local`
  VPC-A private   `10.10.2.0/24`       `10.20.0.0/16`   VPC Peering
  VPC-B private   `10.20.1.0/24`       `10.20.0.0/16`   `local`
  VPC-B private   `10.20.1.0/24`       `10.10.0.0/16`   VPC Peering

VPC Peering does not automatically add routes. Both VPCs need a route to
the other VPC's CIDR through the peering connection.

## 4. Forward and return paths

**Forward path --- App-A → App-B:** App-A (`10.10.2.10`) sends traffic
to App-B (`10.20.1.10`). VPC-A's private route table matches
`10.20.0.0/16` and sends the traffic through the peering connection.
VPC-B's local route delivers it to App-B if security rules allow it.

**Return path --- App-B → App-A:** App-B (`10.20.1.10`) sends the reply
to App-A (`10.10.2.10`). VPC-B's private route table matches
`10.10.0.0/16` and sends traffic through the peering connection. VPC-A's
local route delivers it to App-A. Both routes and relevant security
rules are required.

## 5. Security approach

-   Bastion SSH access was restricted to the client public IPv4 address
    using `/32`.
-   Private-instance SSH access was tested through the intended
    bastion/SSH path.
-   Connectivity tests used private destination IPs.
-   ICMP rules were changed for the controlled failure/recovery test.
-   Refer to the screenshots below for the exact security-group rules
    used during the lab.

## 6. Screenshot evidence

All paths below use the exact filenames shown in the `Screenshots/`
folder. **Do not rename these files without updating the corresponding
Markdown links.** Click each link to open its image.

### Network and resources

  -------------------------------------------------------------------------------------
  Screenshot                                        Evidence
  ------------------------------------------------- -----------------------------------
  [SS01 --- VPC                                     VPC CIDR ranges
  CIDRs](Screenshots/SS01_VPCs_CIDRs.png)           

  [SS02 --- Route                                   Route configuration
  tables](Screenshots/SS02_Routes.png)              

  [SS03A --- EC2                                    EC2 inventory during the lab
  instances](Screenshots/SS03A_EC2_Instances.png)   

  [SS03B --- App-A has no public                    App-A public-IP check
  IP](Screenshots/SS03B_AppA_No_Public_IP.png)      

  [SS03C --- App-B has no public                    App-B public-IP check
  IP](Screenshots/SS03C_AppB_No_Public_IP.png)      

  [SS04 --- Active VPC                              Peering status during the lab
  Peering](Screenshots/SS04_Peering_Active.png)     
  -------------------------------------------------------------------------------------

### Security and connectivity

  --------------------------------------------------------------------------------------------
  Screenshot                                               Evidence
  -------------------------------------------------------- -----------------------------------
  [SS05A --- Bastion security                              Bastion inbound rules
  group](Screenshots/SS05A_Bastion_SG.png)                 

  [SS05B --- App-A security                                App-A inbound rules
  group](Screenshots/SS05B_AppA_SG.png)                    

  [SS05C --- App-B security                                App-B inbound rules
  group](Screenshots/SS05C_AppB_SG.png)                    

  [SS06 --- Bastion SSH                                    SSH to bastion
  success](Screenshots/SS06_Bastion_SSH_Success.png)       

  [SS07 --- App-A SSH                                      SSH to App-A
  success](Screenshots/SS07_AppA_SSH_Success.png)          

  [SS07 --- Forward ping, App-A →                          Ping from App-A to App-B
  App-B](Screenshots/SS07_AppA_To_AppB_Ping.png)           

  [SS08 --- App-B SSH                                      SSH to App-B
  success](Screenshots/SS08_AppB_SSH_Success.png)          

  [SS08 --- Reverse ping, App-B →                          Ping from App-B to App-A
  App-A](Screenshots/SS08_AppB_To_AppA_Ping.png)           

  [SS09 --- Controlled ICMP                                Negative connectivity test
  failure](Screenshots/SS09_Controlled_ICMP_Failure.png)   

  [SS10 --- ICMP                                           Recovery test after restoring ICMP
  recovery](Screenshots/SS10_ICMP_Recovery.png)            access
  --------------------------------------------------------------------------------------------

### Cleanup and extra evidence

  --------------------------------------------------------------------------------------------------------------------------------------
  Screenshot                                                                                         Evidence
  -------------------------------------------------------------------------------------------------- -----------------------------------
  [Cleanup --- Terraform destroy                                                                     Terraform cleanup output
  completed](Screenshots/Cleanup%20verification%20%E2%80%94%20Terraform%20destroy%20completed.png)   

  [Additional screenshot --- 2026-10-28](Screenshots/Screenshot%202026-10-28%20194703.png)           Additional captured evidence;
                                                                                                     inspect the image for its specific
                                                                                                     context
  --------------------------------------------------------------------------------------------------------------------------------------

**Evidence labelling:** Each screenshot should identify the host,
command/test or console view, and observed result. Do not claim a test
succeeded unless the screenshot demonstrates it.

## 7. Terraform files and GitHub safety

  -----------------------------------------------------------------------
  File                                Guidance
  ----------------------------------- -----------------------------------
  `main.tf`                           Commit after checking for hardcoded
                                      secrets

  `.terraform.lock.hcl`               Commit

  `.gitignore`                        Commit

  `.terraform/`                       Do not commit

  `terraform.tfstate` and backups     **Do not commit**; may contain
                                      sensitive values

  `ewb-lab.pem`                       **Never commit**; private SSH key
  -----------------------------------------------------------------------

Suggested `.gitignore`:

``` gitignore
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
*.tfvars
*.tfvars.json
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.pem
*.key
.terraformrc
terraform.rc
.DS_Store
Thumbs.db
.vscode/
```

If a private key or state file has already been committed, `.gitignore`
alone does not remove it from Git history or tracking. Remove it from
tracking and rotate any exposed credentials as appropriate.

## 8. Cleanup

After testing, I ran `terraform destroy` to remove the lab resources.
The cleanup screenshot is linked above. Resource IDs and console states
shown in screenshots describe the deployment at test time; they are not
active resources now.

## 9. What I learned

-   How VPC and subnet CIDRs define network boundaries.
-   Why peering requires routes in both VPCs.
-   How to separate a public bastion from private EC2 instances.
-   How security groups affect SSH and ICMP traffic.
-   How to test forward and return paths using private IP addresses.
-   How a changed client public IP can affect bastion SSH access.
-   Why private keys and Terraform state must not be published.
-   Why lab resources should be destroyed after testing to control
    costs.

## 10. Reproducing the lab

1.  Install Terraform and configure AWS CLI credentials for a dedicated
    lab account.

2.  Review `main.tf`, the Region, CIDRs, instance types, key-pair setup,
    security-group rules, and expected costs.

3.  Initialise and validate:

    ``` bash
    terraform init
    terraform validate
    terraform plan
    ```

4.  Review the plan before creating resources:

    ``` bash
    terraform apply
    ```

5.  Run the connectivity/security tests and capture your own evidence.

6.  Remove resources when finished:

    ``` bash
    terraform destroy
    ```

**Before reproducing:** Confirm the current `main.tf` matches this
design. Review the plan carefully and avoid applying the configuration
unless you are prepared for possible AWS charges.
