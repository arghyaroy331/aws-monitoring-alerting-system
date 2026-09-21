# Architecture — Interview Prep

Companion notes to [`interview-notes.md`](https://github.com/arghyaroy331/aws-monitoring-alerting-system/blob/main/docs/interview-notes.md) and `docs/architecture.md` — this file is the "explain the architecture out loud" version, built to be talked through rather than read.

**The framing to hold onto throughout:** the architecture is being built in stages. Day 1 shipped networking, compute, and the web server — that part is *done*. CloudWatch, SNS, and Lambda are *designed but not built yet*. Be precise about that split in an interview; claiming a planned component as completed is the fastest way to get caught in a follow-up question.

## Contents

- [Project overview](#project-overview)
- [Current architecture — what's actually running](#current-architecture--whats-actually-running)
- [Network architecture](#network-architecture)
- [EC2 architecture](#ec2-architecture)
- [Security group](#security-group)
- [Nginx request flow](#nginx-request-flow)
- [Planned: monitoring architecture](#planned-monitoring-architecture)
- [Planned: automation architecture](#planned-automation-architecture)
- [Final planned architecture](#final-planned-architecture)
- [Component status](#component-status)
- [Design principles](#design-principles)

---

## Project overview

- [ ] **Q: What is this system, in one sentence?**
  An AWS-based monitoring and alerting system that watches an EC2-hosted web server, detects infrastructure problems, sends alerts, and — eventually — automates responses to them.

- [ ] **Q: Why does the architecture doc separate "current" from "planned"?**
  Because the project is built incrementally, and an architecture diagram that shows the end-state as if it already exists would misrepresent what's actually deployed. Day 1 is networking + compute + web server only — everything downstream (CloudWatch, alarms, SNS, Lambda) is designed on paper but not built. Keeping that distinction explicit is also just good engineering documentation practice: it tells the next reader (or the next version of you) exactly what state the system is in.

---

## Current architecture — what's actually running

```text
                         INTERNET
                            |
                     Internet Gateway
                            |
                            v
                    +----------------+
                    |      VPC       |
                    | 172.31.0.0/16  |
                    +----------------+
                            |
                            v
                    +----------------+
                    | Public Subnet  |
                    | 172.31.0.0/20  |
                    +----------------+
                            |
                            v
                    +----------------+
                    |      EC2       |
                    | Amazon Linux   |
                    |   2023 /       |
                    |   t3.micro     |
                    +----------------+
                            |
                            v
                    +----------------+
                    |     Nginx      |
                    |    Port 80     |
                    +----------------+
                            |
                            v
                    HTTP Response → USER
```

- [ ] **Q: Talk me through this diagram top to bottom.**
  Traffic enters through the Internet Gateway into the VPC, lands in a public subnet, reaches the EC2 instance, and terminates at Nginx listening on port 80, which returns the HTTP response back out the same path. Every arrow in that chain corresponds to something I configured and verified individually — nothing here is assumed.

---

## Network architecture

| Resource | Value |
|---|---|
| VPC CIDR | `172.31.0.0/16` |
| Public subnet CIDR | `172.31.0.0/20` |
| Route table | `0.0.0.0/0 → Internet Gateway` |

- [ ] **Q: Why does the route table matter separately from the Internet Gateway existing?**
  Attaching an Internet Gateway to a VPC doesn't automatically route traffic to it — the subnet's route table has to explicitly send internet-bound traffic (`0.0.0.0/0`) there. Without that route, the gateway is attached but unused, and the subnet would have no path out. It's the combination of both that makes the subnet "public."

- [ ] **Q: What does the `/20` subnet CIDR tell you?**
  It's a subdivision of the wider `/16` VPC range, sized to hold the public-facing resources — in this case, just the one EC2 instance, but the block leaves room to add more public resources (like a load balancer, later) without re-architecting the addressing.

---

## EC2 architecture

| Setting | Value |
|---|---|
| OS | Amazon Linux 2023 |
| Instance type | `t3.micro` |
| Web server | Nginx |
| HTTP port | 80 |
| SSH port | 22 |
| IP | Public IPv4 |

- [ ] **Q: Why does the instance need a public IPv4 address specifically, architecturally speaking?**
  Because in this stage of the architecture, the EC2 instance *is* the public-facing endpoint — there's no load balancer or reverse proxy in front of it yet. The public IP is what lets Nginx be reachable from the internet at all. That's flagged in the "planned improvements" as something to move behind a load balancer in a later, more production-like architecture.

---

## Security group

`aws-monitoring-sg`

| Protocol | Port | Source | Purpose |
|---|---|---|---|
| TCP | 22 | My public IP `/32` | SSH administration |
| TCP | 80 | `0.0.0.0/0` | Public HTTP access |

- [ ] **Q: Where does the security group sit in the architecture, conceptually?**
  It's the enforcement point between the network layer (VPC, subnet, route table, IGW) and the instance itself — routing can get traffic to the EC2 instance's door, but the security group decides whether that traffic is actually let in. SSH is scoped to a single `/32` address because it's administrative access; HTTP is open because the web server's entire purpose is to serve public requests.

---

## Nginx request flow

```text
User Browser
     |  HTTP Request
     v
Public IP
     v
Security Group
     v
EC2
     v
Nginx :80
     v
HTTP Response
```

- [ ] **Q: How did you confirm each hop in this flow actually works, not just that it should in theory?**
  ```bash
  sudo systemctl status nginx   # service is active
  curl http://localhost         # Nginx responds locally
  sudo ss -tulpn | grep :80     # something is actually bound to port 80
  ```
  Then externally, from outside the instance, I confirmed the public IP + security group + port were all correctly wired by reaching it from my own machine — closing the loop from "should work" to "verified working."

---

## Planned: monitoring architecture

**Not built yet — this is the design for the next stage.**

```text
                    EC2
                     |
                     v
              CloudWatch Agent
                     |
                     v
              Amazon CloudWatch
                     |
                     v
             CloudWatch Alarm
                     |
                     v
                    SNS
                     |
                     v
              Email Notification
```

- [ ] **Q: What's the very next piece you'd build, and why that one first?**
  An IAM role for the EC2 instance, followed by installing the CloudWatch Agent. The agent needs permission to publish metrics and logs before it's useful, so the IAM role is the prerequisite — everything else in the monitoring chain (alarms, SNS) depends on CloudWatch actually having data to evaluate.

---

## Planned: automation architecture

**Not built yet.**

```text
EC2 → CloudWatch → CloudWatch Alarm → SNS / Event → Lambda → Automated Action
```

- [ ] **Q: Why is the "automated action" left undefined for now?**
  Because it should be defined once the monitoring and alerting layers are actually proven to work — automating a response to a signal you haven't validated yet risks automating the wrong reaction. The architecture reserves Lambda's place in the chain without committing to a specific remediation before there's real alarm data to design against.

---

## Final planned architecture

```text
INTERNET → Internet Gateway → VPC → Public Subnet → EC2 (Amazon Linux + Nginx)
                                                          |
                                                          v
                                                  CloudWatch Agent
                                                          |
                                                          v
                                                  Amazon CloudWatch
                                                    /            \
                                          CloudWatch Metrics   CloudWatch Logs
                                                    \            /
                                                          v
                                                  CloudWatch Alarm
                                                          |
                                                          v
                                                         SNS
                                                          |
                                                          v
                                                 Email Notification
                                                          |
                                                          v
                                                       Lambda
                                                          |
                                                          v
                                               Automated Response
```

- [ ] **Q: What are you optimizing for across this whole design?**
  Reducing the time between a real infrastructure problem occurring and an engineer (or an automated system) responding to it — starting from "someone has to notice manually" down to "the system detects, alerts, and eventually self-remediates."

---

## Component status

| Component | Purpose | Status |
|---|---|---|
| VPC | Network isolation | Completed |
| Public Subnet | Hosts EC2 | Completed |
| Internet Gateway | Internet connectivity | Completed |
| Route Table | Network routing | Completed |
| Network ACL | Subnet-level traffic control | Completed |
| Security Group | EC2 firewall | Completed |
| EC2 | Hosts the web server | Completed |
| Amazon Linux 2023 | Operating system | Completed |
| Nginx | Web server | Completed |
| IAM Role | AWS permissions | Next stage |
| CloudWatch Agent | Collect system metrics/logs | Next stage |
| CloudWatch | Monitoring | Planned |
| CloudWatch Alarm | Detect thresholds | Planned |
| SNS | Notifications | Planned |
| Lambda | Automation | Planned |
| Terraform | Infrastructure as Code | Planned |
| GitHub Actions | CI/CD | Planned |

- [ ] **Q: If asked "what's done vs. what's left" cold, how do you answer fast?**
  Done: everything below the EC2 instance in the network stack, plus the instance and Nginx themselves. Left: everything from the IAM role onward — monitoring, alerting, automation, and the IaC/CI/CD layer around the whole thing.

---

## Design principles

- Least privilege
- Secure SSH access
- Infrastructure monitoring
- Automation
- Cost awareness
- Reproducibility
- Version control
- Step-by-step implementation

- [ ] **Q: Pick one of these principles and show me where it shows up in the current build, not just as a word.**
  *Least privilege* — the Security Group scopes SSH to a single `/32` source instead of the internet, and the plan for the IAM role explicitly calls out CloudWatch-only permissions rather than broad access, before that role even exists yet.
