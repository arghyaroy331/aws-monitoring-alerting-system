\# AWS Monitoring \& Alerting System — Interview Notes



\## 1. What is your project?



I built an AWS Monitoring and Alerting System focused on cloud infrastructure monitoring and basic incident response.



The project uses an EC2 instance running Amazon Linux 2023 and Nginx as the monitored workload. The planned monitoring layer uses CloudWatch to collect metrics and logs, CloudWatch Alarms to detect abnormal conditions, SNS to send notifications, and Lambda for selected automated responses.



The project is designed to demonstrate practical Cloud, DevOps and SRE concepts such as monitoring, alerting, troubleshooting, IAM, automation and infrastructure as code.



\---



\## 2. Why did you choose this project?



I wanted to build a project that goes beyond simply deploying an application on AWS.



In a real production environment, engineers need to know whether infrastructure is healthy, whether services are running, and whether resource usage is becoming abnormal.



This project focuses on detecting those problems automatically and notifying the engineer.



\---



\## 3. What is the current architecture?



```text

Internet

&#x20;  |

&#x20;  v

Internet Gateway

&#x20;  |

&#x20;  v

Public Subnet

&#x20;  |

&#x20;  v

EC2 - Amazon Linux 2023

&#x20;  |

&#x20;  v

Nginx

&#x20;  |

&#x20;  v

CloudWatch Agent

&#x20;  |

&#x20;  +---- CPU

&#x20;  +---- Memory

&#x20;  +---- Disk

&#x20;  +---- Logs

&#x20;         |

&#x20;         v

&#x20;     CloudWatch

&#x20;         |

&#x20;         v

&#x20;  CloudWatch Alarm

&#x20;         |

&#x20;         v

&#x20;        SNS

&#x20;         |

&#x20;         v

&#x20;   Email Notification

&#x20;         |

&#x20;         v

&#x20;      Lambda

&#x20;    Automation



4\. Why did you use EC2?



EC2 provides the compute infrastructure that we need to monitor.



Instead of creating only a theoretical monitoring system, I wanted to monitor an actual Linux server running a real service.



The EC2 instance gives us metrics such as CPU usage, memory usage and disk usage and also provides logs that can be monitored.



5\. Why Amazon Linux 2023?



I used Amazon Linux 2023 because it is an AWS-oriented Linux distribution and works well with AWS infrastructure.



It also uses standard Linux tools such as:

systemctl

dnf

ss

curl



These tools are useful for server administration and troubleshooting.



6\. Why did you install Nginx?



I installed Nginx to create a real service running on the EC2 instance.



This gives the monitoring system something meaningful to observe.



For example, later we can detect:



Nginx service failure

HTTP availability problems

Nginx errors

Resource usage caused by the service

7\. What does Nginx do?



Nginx is a web server and reverse proxy.



In this project, I use it as a simple HTTP service running on port 80.



I verified it locally using:

curl http://localhost



8\. How did you verify that Nginx was running?



First, I checked the service:



sudo systemctl status nginx



I expected:



Active: active (running)



Then I tested it locally:



curl http://localhost



Then I checked that port 80 was listening:



sudo ss -tulpn | grep :80



Finally, I tested port 80 from my Windows machine:



Test-NetConnection <PUBLIC-IP> -Port 80



Then I opened the public IP in the browser.



9\. What is a Security Group?



A Security Group is a virtual firewall associated with an EC2 network interface.



It controls which network traffic is allowed to reach the instance.



For this project I configured:



SSH   TCP 22 → My IP

HTTP  TCP 80 → 0.0.0.0/0



SSH is restricted because it provides administrative access, while HTTP is public because the Nginx service needs to be accessible from the internet.



10\. Why did you restrict SSH?



SSH provides administrative access to the EC2 server.



Opening SSH to:



0.0.0.0/0



allows connections from any IPv4 address and increases the attack surface.



Therefore, I restricted SSH to my trusted source IP whenever possible.



11\. Why is HTTP open to 0.0.0.0/0?



The Nginx web service needs to be reachable from the internet for testing.



Therefore:



HTTP → TCP 80 → 0.0.0.0/0



allows clients on the internet to access the Nginx page.



12\. What is a VPC?



A VPC is an isolated virtual network in AWS.



It provides networking components such as:



Subnets

Route tables

Internet Gateways

Network ACLs

Security Groups



The EC2 instance runs inside the VPC.



13\. What is an Internet Gateway?



An Internet Gateway allows communication between resources in a VPC and the public internet.



For the EC2 instance, the route table contains a route similar to:



0.0.0.0/0 → Internet Gateway



This allows traffic destined for the internet to leave the VPC.



14\. What is a Route Table?



A route table determines where network traffic should go.



The important route for this project is:



Destination: 0.0.0.0/0

Target: Internet Gateway



This allows the public subnet to communicate with the internet.



15\. What is a Network ACL?



A Network ACL is a subnet-level network traffic filter.



It controls inbound and outbound traffic at the subnet boundary.



I checked the Network ACL during troubleshooting to verify that it wasn't blocking the required traffic.



16\. Security Group vs Network ACL?

Security Group

Works at the instance/network-interface level

Stateful

Allows rules

Return traffic is automatically allowed

Network ACL

Works at the subnet level

Stateless

Supports allow and deny rules

Return traffic must be explicitly allowed

17\. How did you troubleshoot the SSH timeout?



Initially, SSH returned:



Connection timed out



Instead of recreating the EC2 instance, I investigated the network path layer by layer.



I checked:



EC2 health

&#x20;   ↓

Public IP

&#x20;   ↓

Route Table

&#x20;   ↓

Internet Gateway

&#x20;   ↓

Network ACL

&#x20;   ↓

Security Group

&#x20;   ↓

Port 22



I used:



Test-NetConnection <PUBLIC-IP> -Port 22



to test TCP connectivity.



I temporarily used a broader SSH source rule as a diagnostic test. When connectivity worked, it confirmed that the problem was related to the Security Group source restriction.



I then restored the SSH rule to a restricted source.



18\. What did you learn from the SSH troubleshooting?



The important lesson was to troubleshoot systematically.



A timeout doesn't automatically mean that the EC2 server is down.



I need to check:



Is the instance healthy?

Does it have a public IP?

Does the subnet have the correct route?

Is the Internet Gateway attached?

Is the Network ACL allowing traffic?

Is the Security Group allowing traffic?

Is the destination service listening on the required port?



This approach is useful for real cloud troubleshooting.



19\. What is CloudWatch?



Amazon CloudWatch is AWS's monitoring and observability service.



I will use it to collect and visualize:



Metrics

Logs

Alarms

Events



For this project, CloudWatch is the central monitoring layer.



20\. Why do you need the CloudWatch Agent?



Some system-level metrics such as memory and disk usage are not automatically available in the same way as basic EC2 metrics.



The CloudWatch Agent can collect additional operating-system-level metrics and logs from the EC2 instance.



The agent will send this information to CloudWatch.



21\. What metrics will you monitor?



The planned metrics include:



CPU utilization

Memory utilization

Disk utilization

Disk space

Network activity

EC2 status

Application/service-related information

22\. What is a CloudWatch Alarm?



A CloudWatch Alarm evaluates a metric against a configured threshold.



For example:



CPU > 80%

&#x20;    |

&#x20;    v

CloudWatch Alarm

&#x20;    |

&#x20;    v

SNS Notification



The alarm can move between states such as:



OK

ALARM

INSUFFICIENT\_DATA

23\. Give an example of an alarm.



For example, I could configure:



Metric: CPUUtilization

Threshold: > 80%

Evaluation period: 5 minutes



If CPU utilization remains above the threshold according to the configured evaluation period, the alarm can enter the ALARM state.



24\. What is SNS?



Amazon SNS stands for Simple Notification Service.



I will use SNS to send notifications when a CloudWatch Alarm enters the ALARM state.



For example:



High CPU

&#x20;  ↓

CloudWatch Alarm

&#x20;  ↓

SNS Topic

&#x20;  ↓

Email

25\. Why use SNS instead of checking CloudWatch manually?



Manual checking does not scale well.



With SNS, the monitoring system can notify the engineer when a problem occurs.



The engineer doesn't need to continuously watch the CloudWatch dashboard.



26\. What is Lambda's role?



AWS Lambda will be used for selected automated responses.



For example:



CloudWatch Event

&#x20;     ↓

Lambda

&#x20;     ↓

Automated action



The exact automation will depend on the incident and the safety requirements.



The purpose is to demonstrate how monitoring can lead to automated remediation rather than only sending notifications.



27\. What problem does this project solve?



Without monitoring, an infrastructure problem may only be discovered when a user reports it.



For example:



Server CPU becomes very high

&#x20;       ↓

Application becomes slow

&#x20;       ↓

Users experience problems

&#x20;       ↓

Engineer receives complaint

&#x20;       ↓

Engineer starts investigation



With monitoring:



CPU becomes very high

&#x20;       ↓

CloudWatch detects it

&#x20;       ↓

Alarm enters ALARM state

&#x20;       ↓

SNS sends notification

&#x20;       ↓

Engineer investigates



This reduces the time between a problem occurring and the engineer becoming aware of it.



28\. Why is this an SRE/DevOps project?



The project covers several SRE/DevOps concepts:



Infrastructure

Monitoring

Observability

Alerting

Incident detection

Troubleshooting

Automation

IAM

Infrastructure as Code

CI/CD



The goal is not just deploying infrastructure, but also observing and responding to problems.



29\. What is observability?



Observability is the ability to understand the internal state of a system from the information it produces.



Common observability signals include:



Metrics

Logs

Traces



This project primarily focuses on metrics and logs.



30\. What is the difference between monitoring and alerting?



Monitoring is the process of collecting and observing system information.



Alerting is notifying an engineer when a defined condition requires attention.



For example:



Monitoring:

CPU = 87%



Alerting:

CPU exceeded the configured threshold → send notification

31\. How will you test the monitoring system?



I will create controlled test scenarios.



For example:



CPU test



Generate temporary CPU load and observe whether the CloudWatch metric increases and the alarm changes state.



Nginx test



Stop Nginx:



sudo systemctl stop nginx



Then observe the service availability/log monitoring.



Restart it:



sudo systemctl start nginx



The purpose is to demonstrate an actual incident and recovery.



32\. What is IAM?



IAM stands for Identity and Access Management.



It controls authentication and authorization in AWS.



For this project, IAM will provide the EC2 instance with the permissions required to publish metrics and logs to CloudWatch.



33\. Why should you avoid using AWS access keys on EC2?



Putting long-term AWS access keys directly on a server creates a security risk.



Instead, I should use an IAM role attached to the EC2 instance.



The application or agent can obtain temporary credentials through the role.



34\. What is the principle of least privilege?



Least privilege means giving a user, service or application only the permissions it actually needs.



For this project, the EC2 monitoring role should have only the permissions necessary for CloudWatch monitoring rather than administrator access.



35\. Why did you create an AWS budget?



The project uses AWS resources that can generate costs.



I created a low monthly budget to receive notifications if spending reaches defined thresholds.



This is especially important for personal/student AWS projects because accidentally running resources can create unexpected charges.



36\. What would happen if the EC2 instance becomes unreachable?



The response depends on what failed.



I would investigate:



EC2 status checks

Network connectivity

Security Group

Route table

NACL

System/service health

CloudWatch metrics

CloudWatch logs



The monitoring system should help reduce the time required to identify the failure.



37\. Why didn't you immediately use Terraform?



I first built the infrastructure manually to understand the AWS components and how they interact.



After understanding the architecture, I plan to reproduce the infrastructure using Terraform.



That allows me to demonstrate both practical AWS knowledge and Infrastructure as Code.



38\. Why Terraform?



Terraform allows infrastructure to be defined as code.



Instead of manually creating every resource through the AWS Console, resources can be described in configuration files and recreated consistently.



It also makes infrastructure changes easier to review and version-control.



39\. Why GitHub?



GitHub provides version control and project documentation.



I use Git commits to document the development process.



For example:



Day 1 → Infrastructure setup

Day 2 → CloudWatch Agent

Day 3 → Alarms + SNS

Day 4 → Dashboard

Day 5 → Lambda

Day 6 → Terraform

Day 7 → CI/CD

40\. What is CI/CD's role in the project?



GitHub Actions can automate parts of the development workflow.



For example:



Developer

&#x20;  ↓

git push

&#x20;  ↓

GitHub

&#x20;  ↓

GitHub Actions

&#x20;  ↓

Validation / Tests

&#x20;  ↓

Deployment or Terraform checks



The exact pipeline will depend on which components are automated.



41\. What was your biggest troubleshooting experience?



The biggest troubleshooting issue during the initial deployment was the SSH timeout.



The important part wasn't simply fixing it; it was identifying which layer was responsible.



I tested connectivity with:



Test-NetConnection <PUBLIC-IP> -Port 22



and systematically checked the AWS networking configuration.



This helped me understand how Security Groups, NACLs, routing and public IP connectivity work together.



42\. What would you improve in a production version?



A production implementation could include:



Private subnets

Systems Manager Session Manager instead of public SSH

Application Load Balancer

Auto Scaling

Multiple Availability Zones

Centralized log retention

More detailed dashboards

Infrastructure as Code

Automated deployment

Better alert routing

Incident management integration

Stronger IAM policies

Secrets management

Cost optimization

High-availability architecture



The current project intentionally starts with a smaller architecture so each component can be understood and demonstrated.



43\. Explain the project in 30 seconds



"I built an AWS Monitoring and Alerting System focused on SRE and DevOps concepts. I deployed an Amazon Linux EC2 instance with Nginx as the monitored service and configured the required VPC, routing, security group and network controls. The monitoring layer uses CloudWatch to collect infrastructure metrics and logs, CloudWatch Alarms to detect abnormal conditions, and SNS to notify the engineer. I'm also adding Lambda automation, Terraform and GitHub Actions to demonstrate incident response and Infrastructure as Code."



44\. Explain the project in 1 minute



"The goal of my project is to build a practical infrastructure monitoring and alerting system on AWS. I started by deploying an Amazon Linux 2023 EC2 instance and running Nginx as the monitored workload. I configured the VPC networking, Internet Gateway, route table, Network ACL and Security Group, and restricted SSH access to a trusted source. I then verified the service locally with curl and externally through the public IP.



The next layer is CloudWatch Agent for collecting system-level metrics such as memory and disk usage and sending logs to CloudWatch. CloudWatch Alarms will detect conditions such as high CPU or disk utilization, and SNS will send notifications to the engineer. I also plan to use Lambda for selected automated responses and Terraform for Infrastructure as Code. The project is version-controlled through GitHub, with the work documented through incremental commits."



45\. Key commands I should remember

Linux

cat /etc/os-release

sudo dnf update -y

sudo dnf install nginx -y

sudo systemctl start nginx

sudo systemctl enable nginx

sudo systemctl status nginx

curl http://localhost

sudo ss -tulpn | grep :80

Windows PowerShell

Test-NetConnection <PUBLIC-IP> -Port 22

Test-NetConnection <PUBLIC-IP> -Port 80

Git

git status

git add .

git commit -m "message"

git push

git log --oneline

46\. The most important interview explanation



Do not say:



"I followed a tutorial and created an EC2 instance."



Instead explain the engineering process:



Requirement

&#x20;   ↓

Design

&#x20;   ↓

AWS Infrastructure

&#x20;   ↓

Security Configuration

&#x20;   ↓

Service Deployment

&#x20;   ↓

Monitoring

&#x20;   ↓

Alerting

&#x20;   ↓

Incident Testing

&#x20;   ↓

Automation

&#x20;   ↓

Infrastructure as Code

&#x20;   ↓

CI/CD



The strongest part of the project is being able to explain why each component exists, how the components communicate, how you tested them, and how you diagnosed failures.

INTERVIEW QUESTIONS
46. Tell Me About Your Project

"I built an AWS Monitoring and Alerting System using EC2, Nginx, CloudWatch, SNS, and Lambda.

The goal is to monitor infrastructure metrics and logs, detect abnormal conditions, notify administrators, and eventually automate responses.

I also implemented AWS networking, IAM, security controls, cost monitoring, and documented the project using GitHub."

47. Why Did You Choose This Project?

"I wanted to build something related to cloud, DevOps, and SRE rather than only developing a traditional web application.

The project gave me practical experience with AWS infrastructure, Linux, networking, monitoring, alerting, and automation."

48. What Was the Most Difficult Part?

"The most challenging part initially was troubleshooting SSH connectivity to EC2.

Instead of assuming that EC2 was down, I checked the Security Group, route table, Internet Gateway, Network ACL, and port connectivity.

That helped me understand AWS networking more practically."

49. What Would You Add In Production?

I would consider adding:

Application Load Balancer
Auto Scaling
Multiple EC2 instances
HTTPS/TLS
Route 53
CloudFront
Centralized logging
More CloudWatch alarms
Incident automation
Terraform
CI/CD
Better dashboards
High availability across Availability Zones
50. 30-Second Project Explanation

"I built an AWS-based monitoring and alerting system for an EC2-hosted Nginx server. CloudWatch collects infrastructure metrics and logs, alarms detect abnormal conditions, SNS sends notifications, and Lambda provides automation. I also configured the underlying VPC networking, security groups, IAM permissions, and AWS budget controls. The project demonstrates practical cloud, DevOps, and SRE concepts."