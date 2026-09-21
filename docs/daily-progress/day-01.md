\# Day 1 — AWS Infrastructure Foundation



\## Objective



Deploy an EC2-based Linux server with a running Nginx service that will become the monitoring target for the project.



\## Work Completed



\### 1. AWS Cost Budget



Created an AWS monthly cost budget of $2.



Purpose:

\- Control project spending

\- Receive cost notifications

\- Avoid unexpected AWS charges



\### 2. EC2



Created an EC2 instance using:



\- Amazon Linux 2023

\- t3.micro

\- Public IPv4 address

\- 8 GiB storage



Purpose:



EC2 provides the server infrastructure that will be monitored.



\### 3. Security Group



Created:



`aws-monitoring-sg`



Configured:



\- SSH — TCP 22 — restricted source

\- HTTP — TCP 80 — internet access



Purpose:



The Security Group acts as a virtual firewall for the EC2 instance.



\### 4. SSH Troubleshooting



Initially SSH connections timed out.



Troubleshooting process:



1\. Checked EC2 health checks

2\. Checked public IPv4

3\. Checked route table

4\. Checked Internet Gateway

5\. Checked Network ACL

6\. Checked Security Group

7\. Tested TCP port 22

8\. Temporarily tested SSH connectivity using a broader source rule

9\. Confirmed connectivity

10\. Restored restricted SSH access



Lesson:



Network connectivity problems should be isolated layer by layer rather than immediately rebuilding the server.



\### 5. Amazon Linux



Connected to the EC2 instance using:



```bash

ssh -i aws-monitoring-key.pem ec2-user@<PUBLIC-IP>

