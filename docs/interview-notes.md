# AWS Monitoring & Alerting System — Interview Prep

Study notes for talking through this project in interviews, organized by topic with the reasoning behind each design decision. Check items off as you review them — GitHub renders these as clickable checkboxes.

## Contents

- [Elevator pitches](#elevator-pitches)
- [Architecture & compute](#architecture--compute)
- [Networking fundamentals](#networking-fundamentals)
- [The SSH timeout incident](#the-ssh-timeout-incident)
- [Monitoring, alerting & automation](#monitoring-alerting--automation)
- [IAM & cost governance](#iam--cost-governance)
- [Roadmap: IaC & CI/CD](#roadmap-iac--cicd)
- [Failure scenarios & production hardening](#failure-scenarios--production-hardening)
- [Command cheat sheet](#command-cheat-sheet)

---

## Elevator pitches

Lead with these. Say them out loud until they sound like you talking, not a script.

### 30 seconds

> I built an AWS Monitoring and Alerting System focused on SRE and DevOps concepts. I deployed an Amazon Linux EC2 instance with Nginx as the monitored service, and configured the VPC, routing, security group, and network controls around it. CloudWatch collects infrastructure metrics and logs, CloudWatch Alarms detect abnormal conditions, and SNS notifies the engineer. I'm layering in Lambda automation, Terraform, and GitHub Actions to demonstrate incident response and Infrastructure as Code.

### 60 seconds

> The goal was a practical infrastructure monitoring and alerting system, not just a deployed app. I started with an Amazon Linux 2023 EC2 instance running Nginx as the monitored workload, then built the VPC networking — Internet Gateway, route table, NACL, and Security Group — restricting SSH to a trusted source. I verified the service locally with curl and externally through the public IP. Next is the CloudWatch Agent for OS-level metrics like memory and disk, CloudWatch Alarms for conditions like high CPU, and SNS for notifications. I'm adding Lambda for selected automated responses and Terraform for Infrastructure as Code, with the whole build version-controlled and documented through incremental GitHub commits.

> **Delivery note:** Don't say "I followed a tutorial and created an EC2 instance." Narrate the engineering process instead: `requirement → design → infrastructure → security → deployment → monitoring → alerting → incident testing → automation → IaC → CI/CD`. The strongest signal is being able to explain *why* each piece exists, how the pieces talk to each other, how you tested them, and how you diagnosed what broke.

- [ ] **Q: Why did you choose this project?**
  I wanted something that went beyond deploying an application — in production, engineers need to know whether infrastructure is healthy, whether services are running, and whether resource usage is drifting abnormal before a user notices. This project is built specifically to detect those conditions automatically and notify the engineer, which is what gave me hands-on exposure to monitoring, alerting, networking, IAM, and automation rather than just "spinning up a server."

---

## Architecture & compute

What's actually running, and why each piece was chosen.

```
Internet → Internet Gateway → Public Subnet → EC2 (Amazon Linux 2023) → Nginx
                                                        │
                                              CloudWatch Agent
                                      ┌───────┬─────────┼─────────┐
                                    CPU     Memory     Disk      Logs
                                      └───────┴─────────┴─────────┘
                                                        ▼
                                                  CloudWatch
                                                        ▼
                                               CloudWatch Alarm
                                                        ▼
                                                       SNS ──▶ Email
                                                        ▼
                                                      Lambda (automation)
```

- [ ] **Q: Why EC2?**
  EC2 provides the actual compute infrastructure to monitor. Rather than building a theoretical monitoring system, I wanted to observe a real Linux server running a real service — EC2 gives real CPU, memory, and disk metrics, plus logs to monitor, instead of synthetic data.

- [ ] **Q: Why Amazon Linux 2023?**
  It's an AWS-oriented distribution that integrates cleanly with AWS infrastructure, while still using standard Linux tooling I need for administration and troubleshooting:
  - `systemctl` — service management
  - `dnf` — package management
  - `ss` — socket/port inspection
  - `curl` — HTTP testing

- [ ] **Q: Why did you install Nginx, and what does it do?**
  Nginx gives the monitoring system something meaningful to observe — a real HTTP service on port 80. It's a web server and reverse proxy; here it's used as a simple HTTP service so I can later detect service failure, HTTP availability problems, Nginx errors, and resource usage caused by the service itself.

- [ ] **Q: How did you verify Nginx was actually running?**
  Layer by layer, from the inside out:

  ```bash
  # 1. Is the service active?
  sudo systemctl status nginx
  # expect: Active: active (running)

  # 2. Does it respond locally?
  curl http://localhost

  # 3. Is it actually listening on the port?
  sudo ss -tulpn | grep :80
  ```

  Then, from Windows, I tested the network path from outside the box:

  ```powershell
  Test-NetConnection <PUBLIC-IP> -Port 80
  ```

  and finally opened the public IP in a browser to confirm end-to-end reachability.

---

## Networking fundamentals

The VPC building blocks and why the traffic rules are shaped the way they are.

- [ ] **Q: What is a VPC?**
  An isolated virtual network in AWS that provides the networking primitives the EC2 instance runs inside of: subnets, route tables, Internet Gateways, Network ACLs, and Security Groups.

- [ ] **Q: What is an Internet Gateway, and what's the route table doing?**
  An Internet Gateway lets resources in a VPC reach the public internet. The route table is what actually points traffic at it — for this project, the public subnet's route table contains:

  ```
  Destination: 0.0.0.0/0
  Target:      Internet Gateway
  ```

  That single route is what lets the public subnet — and the EC2 instance in it — send and receive internet traffic.

- [ ] **Q: What is a Security Group, and how did you configure it?**
  A Security Group is a virtual firewall attached to the EC2 network interface — it decides what traffic is allowed to reach the instance. This project's rules:

  ```
  SSH   TCP 22  →  My IP
  HTTP  TCP 80  →  0.0.0.0/0
  ```

  SSH is restricted because it's administrative access; HTTP is open because Nginx needs to be reachable from the internet. `0.0.0.0/0` means "any IPv4 address" — fine for a public web service, dangerous for an admin port.

- [ ] **Q: What is a Network ACL, and how is it different from a Security Group?**
  A Network ACL filters traffic at the subnet boundary, rather than at the instance's network interface. I checked it during SSH troubleshooting to confirm it wasn't the layer blocking traffic.

  | | Security Group | Network ACL |
  |---|---|---|
  | Scope | Instance / ENI level | Subnet level |
  | State | Stateful — return traffic auto-allowed | Stateless — return traffic must be explicitly allowed |
  | Rules | Allow rules only | Allow *and* deny rules |

---

## The SSH timeout incident

This is the story to have polished — it's the one piece of real, lived troubleshooting in the project.

- [ ] **Q: Walk me through how you troubleshot the SSH timeout.**
  SSH came back with `Connection timed out`. Rather than assuming the instance was broken and recreating it, I worked the network path layer by layer, outside-in:

  ```
  EC2 health → Public IP → Route Table → Internet Gateway → Network ACL → Security Group → Port 22
  ```

  I used `Test-NetConnection <PUBLIC-IP> -Port 22` to check raw TCP connectivity at each stage, and temporarily widened the SSH source rule as a diagnostic test. When connectivity started working, that confirmed the Security Group's source restriction was the actual cause — so I restored it to the narrower, trusted-source rule once confirmed.

- [ ] **Q: What did that teach you, and how would you frame it as your "biggest troubleshooting" answer?**
  A timeout doesn't mean the server is down — it means *something on the path* is blocking traffic, and the job is to find out which layer. The checklist I now default to:
  - Is the instance healthy?
  - Does it have a public IP?
  - Does the subnet have the correct route?
  - Is the Internet Gateway attached?
  - Is the Network ACL allowing the traffic?
  - Is the Security Group allowing the traffic?
  - Is the destination service actually listening on that port?

  That systematic, layer-by-layer instinct — rather than guessing or rebuilding — is the transferable lesson, and it's the answer to "tell me about a time you debugged something" as much as it is a networking question.

---

## Monitoring, alerting & automation

The core of the project — CloudWatch, Alarms, SNS, and Lambda.

- [ ] **Q: What is CloudWatch, and why does the project need the Agent specifically?**
  CloudWatch is AWS's monitoring and observability service — it collects and visualizes metrics, logs, alarms, and events, and acts as the central monitoring layer here. Basic EC2 metrics come for free, but OS-level metrics like memory and disk usage don't — those need the **CloudWatch Agent** installed on the instance, which collects that additional system-level data and log content and ships it to CloudWatch.

- [ ] **Q: What metrics are you monitoring?**
  - CPU utilization
  - Memory utilization
  - Disk utilization / disk space
  - Network activity
  - EC2 status checks
  - Application/service-level signals (e.g. Nginx)

- [ ] **Q: What is a CloudWatch Alarm? Give an example.**
  An alarm evaluates a metric against a threshold and moves between states: `OK`, `ALARM`, `INSUFFICIENT_DATA`.

  ```
  Metric:            CPUUtilization
  Threshold:         > 80%
  Evaluation period: 5 minutes
  ```

  If CPU stays above 80% for the configured evaluation period, the alarm transitions into `ALARM`.

- [ ] **Q: What is SNS, and why use it instead of just checking CloudWatch manually?**
  SNS (Simple Notification Service) sends a notification — here, email — when an alarm enters `ALARM`. Manual dashboard-checking doesn't scale: with SNS, the system pushes the alert to the engineer instead of requiring someone to babysit a dashboard.

- [ ] **Q: What is Lambda's role in this project?**
  Lambda handles selected automated responses triggered off a CloudWatch event — the goal is to show monitoring leading to actual remediation, not just a notification. The exact action depends on the incident type and how safe it is to automate.

- [ ] **Q: What problem does this whole system actually solve?**

  **Without monitoring:**
  ```
  High CPU → app slows → users affected → engineer gets a complaint → investigation starts
  ```

  **With monitoring:**
  ```
  High CPU → CloudWatch detects it → Alarm fires → SNS notifies → engineer investigates
  ```

  The system shrinks the gap between a problem occurring and an engineer knowing about it — before a user has to report it.

- [ ] **Q: Monitoring vs. alerting — what's the difference?**
  **Monitoring** is collecting and observing system information (e.g. "CPU = 87%"). **Alerting** is the decision layer on top: notifying someone because a defined condition needs attention ("CPU exceeded threshold → send notification"). Monitoring is data; alerting is the action taken on that data.

- [ ] **Q: What is observability?**
  The ability to understand a system's internal state from the information it produces — typically metrics, logs, and traces. This project focuses primarily on metrics and logs.

- [ ] **Q: How will you test that the monitoring actually works?**
  **CPU test** — generate temporary CPU load and confirm the CloudWatch metric rises and the alarm changes state.

  **Nginx test** — stop the service and watch service-availability/log monitoring react:
  ```bash
  sudo systemctl stop nginx
  # observe monitoring
  sudo systemctl start nginx
  ```

  The point of both is to demonstrate a real incident and a real recovery, not just a configured alarm that's never fired.

---

## IAM & cost governance

Access control and keeping a personal AWS project from generating surprise charges.

- [ ] **Q: What is IAM, and what does it do here?**
  Identity and Access Management controls authentication and authorization in AWS. Here, IAM gives the EC2 instance exactly the permissions it needs to publish metrics and logs to CloudWatch — nothing more.

- [ ] **Q: Why avoid putting AWS access keys on the EC2 instance?**
  Long-term access keys sitting on a server are a standing security risk — if the box is compromised, the keys are compromised. An IAM role attached to the instance lets the agent obtain short-lived, temporary credentials instead, with nothing long-lived to leak.

- [ ] **Q: What's the principle of least privilege, applied here?**
  Giving an identity only the permissions it actually needs. The EC2 monitoring role should be scoped to CloudWatch monitoring actions — not administrator access — so a compromised instance can't do more than emit metrics and logs.

- [ ] **Q: Why did you set up an AWS budget?**
  The resources in this project can generate real cost, and this is a personal/student account. A low monthly budget with notification thresholds catches accidental spend early — before it becomes an unexpected bill.

---

## Roadmap: IaC & CI/CD

Where the project goes after the manual build.

- [ ] **Q: Why didn't you start with Terraform?**
  I built the infrastructure manually first specifically to understand each AWS component and how it interacts with the others. Once that mental model was solid, reproducing it in Terraform demonstrates both hands-on AWS knowledge *and* Infrastructure as Code — rather than only IaC syntax without the underlying understanding.

- [ ] **Q: Why Terraform, specifically?**
  It defines infrastructure as versioned, reviewable configuration instead of manual console clicks — the same environment can be recreated consistently, and changes go through the same review process as code.

- [ ] **Q: Why GitHub, and what does CI/CD add?**
  GitHub gives version control and a running record of the build — commits document the project day by day (infra → agent → alarms/SNS → dashboard → Lambda → Terraform → CI/CD). GitHub Actions then automates parts of that workflow:

  ```
  git push → GitHub → GitHub Actions → validation / tests → deployment or Terraform checks
  ```

  The exact pipeline depends on which components end up automated.

---

## Failure scenarios & production hardening

What happens when it breaks, and what a "real" version looks like.

- [ ] **Q: What would you do if the EC2 instance became unreachable?**
  It depends on which layer failed, so I'd work through the same checklist as the SSH incident: EC2 status checks, network connectivity, Security Group, route table, NACL, system/service health, then CloudWatch metrics and logs for corroborating evidence. The monitoring system's job is to shrink how long that diagnosis takes.

- [ ] **Q: What would you change for a production version?**
  - Private subnets, with Systems Manager Session Manager instead of public SSH
  - Application Load Balancer + Auto Scaling across multiple Availability Zones
  - Centralized log retention and richer dashboards
  - Full Infrastructure as Code + automated deployment
  - Better alert routing and incident-management integration
  - Stronger IAM policies and proper secrets management
  - Cost optimization and a real high-availability architecture

  The current build intentionally stays small so each component can be understood and demoed individually — production hardening is the deliberate next layer, not a gap I missed.

---

## Command cheat sheet

Have these ready to type from memory if asked to demo.

**Linux**
```bash
cat /etc/os-release
sudo dnf update -y
sudo dnf install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
curl http://localhost
sudo ss -tulpn | grep :80
```

**PowerShell**
```powershell
Test-NetConnection <PUBLIC-IP> -Port 22
Test-NetConnection <PUBLIC-IP> -Port 80
```

**Git**
```bash
git status
git add .
git commit -m "message"
git push
git log --oneline
```
