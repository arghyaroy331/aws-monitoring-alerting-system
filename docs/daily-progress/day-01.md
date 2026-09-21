# Day 1 — AWS Infrastructure Foundation — Interview Prep

**Objective:** Stand up an EC2-based Linux server with a running Nginx service to act as the monitoring target for the rest of the project.

Companion notes to [`interview-notes.md`](https://github.com/arghyaroy331/aws-monitoring-alerting-system/blob/main/docs/interview-notes.md) — this file is the "what did you actually do on Day 1" version, phrased the way you'd say it out loud.

## Contents

- [30-second summary](#30-second-summary)
- [Cost budget](#cost-budget)
- [EC2 instance](#ec2-instance)
- [Security group](#security-group)
- [SSH troubleshooting](#ssh-troubleshooting)
- [Connecting to the instance](#connecting-to-the-instance)

---

## 30-second summary

> Day 1 was about getting the foundation in place before any monitoring existed: a cost budget so the account couldn't run up an unexpected bill, an EC2 instance running Amazon Linux 2023 as the box I'd monitor, and a Security Group to control who could reach it. The one real problem I hit was an SSH timeout, which I diagnosed layer by layer instead of rebuilding the instance — that turned into the most useful troubleshooting lesson of the whole build.

---

## Cost budget

- [ ] **Q: Why did the very first step involve a budget, before any infrastructure existed?**
  Because AWS resources start costing money the moment they exist, and this is a personal/student account. I set a $2 monthly budget up front, before deploying anything, specifically so I'd get a cost notification if something drifted — rather than finding an unexpected charge after the fact.

- [ ] **Q: What does the budget actually protect against?**
  Not against being billed at all — a budget doesn't stop spend, it alerts on it. It protects against silently forgetting a resource is running (a left-on EC2 instance, an idle load balancer) and only noticing when the invoice arrives.

---

## EC2 instance

Configuration:

| Setting | Value |
|---|---|
| AMI | Amazon Linux 2023 |
| Instance type | `t3.micro` |
| Networking | Public IPv4 address |
| Storage | 8 GiB |

- [ ] **Q: Why `t3.micro`?**
  It's the right size for a monitoring *target* rather than a production workload — enough compute to run Nginx and generate real CPU/memory/disk signal, without paying for capacity the project doesn't need. `t3` is also burstable, which is useful for the CPU-load test later in the project (spiking CPU to trigger an alarm).

- [ ] **Q: Why does it need a public IPv4 address?**
  So the instance is reachable from outside the VPC for two things this project needs directly: SSH administration from my machine, and HTTP access to Nginx from the internet. In a production design this would move behind a load balancer in a private subnet instead — noted as a Day-1-vs-production tradeoff.

- [ ] **Q: Why EC2 specifically, and why is this "the server infrastructure that will be monitored"?**
  Everything downstream — CloudWatch metrics, alarms, SNS, Lambda — only means something if there's a real server producing real signal. EC2 is that server: it's what generates the CPU, memory, disk, and log data the rest of the project observes and reacts to.

---

## Security group

Created: **`aws-monitoring-sg`**

```
SSH   TCP 22  →  restricted source
HTTP  TCP 80  →  0.0.0.0/0 (internet access)
```

- [ ] **Q: Walk me through the naming and purpose of the security group.**
  `aws-monitoring-sg` is the virtual firewall attached to the EC2 instance's network interface — it's the single point that decides what traffic is allowed to reach the box at all, before anything on the OS even sees it. Two rules: SSH locked to a specific trusted source since it's administrative access, HTTP open to the internet since Nginx is meant to be publicly reachable.

- [ ] **Q: Why split those two rules that way instead of treating them the same?**
  Different risk profiles. HTTP exposes a web page — that's the point of running it. SSH exposes a shell — that's an attack surface with no upside to leaving it open, so it gets the tightest rule the workflow allows.

---

## SSH troubleshooting

SSH connections initially returned `Connection timed out`. Diagnosed layer by layer instead of recreating the instance:

1. Checked EC2 health checks
2. Checked the public IPv4 address
3. Checked the route table
4. Checked the Internet Gateway
5. Checked the Network ACL
6. Checked the Security Group
7. Tested TCP port 22 directly
8. Temporarily widened the SSH source rule as a diagnostic test
9. Confirmed connectivity worked with the wider rule
10. Restored the restricted SSH rule

- [ ] **Q: What was actually wrong, and how do you know?**
  The Security Group's SSH source restriction was blocking the connection. I confirmed this by isolating every other layer first — instance health, IP, routing, IGW, NACL — and only then testing a deliberately looser SSH rule as a controlled experiment. When that fixed it, the Security Group was confirmed as the cause, so I reverted to the correct, restricted rule rather than leaving the wider one in place.

- [ ] **Q: What's the takeaway from this, in one sentence?**
  Network connectivity problems get isolated layer by layer, from the instance outward to the network path, rather than assumed to mean the server itself is broken — a timeout is a symptom, not a diagnosis.

---

## Connecting to the instance

```bash
ssh -i aws-monitoring-key.pem ec2-user@<PUBLIC-IP>
```

- [ ] **Q: Break down that SSH command.**
  - `-i aws-monitoring-key.pem` — the private key file that pairs with the public key AWS injected into the instance at launch; this is what authenticates me instead of a password.
  - `ec2-user` — the default login user baked into the Amazon Linux 2023 AMI.
  - `<PUBLIC-IP>` — the instance's public IPv4 address, reachable because of the Internet Gateway route and the Security Group's SSH rule allowing my source IP.
