\# AWS Monitoring \& Alerting System



A practical SRE/DevOps project for monitoring AWS infrastructure using Amazon EC2, CloudWatch, SNS, Lambda and Terraform.



\## Project Objective



The goal is to build an automated monitoring and alerting system that can:



\- Monitor EC2 infrastructure

\- Collect CPU, memory and disk metrics

\- Collect system and application logs

\- Detect abnormal conditions

\- Trigger CloudWatch alarms

\- Send notifications using Amazon SNS

\- Automate selected incident responses using AWS Lambda

\- Manage infrastructure using Terraform

\- Use GitHub Actions for CI/CD



\## Architecture



```text

&#x20;                   Internet

&#x20;                      |

&#x20;                      v

&#x20;               AWS Internet Gateway

&#x20;                      |

&#x20;                      v

&#x20;                 EC2 Instance

&#x20;              Amazon Linux 2023

&#x20;                      |

&#x20;                      v

&#x20;                    Nginx

&#x20;                      |

&#x20;            +---------+---------+

&#x20;            |                   |

&#x20;            v                   v

&#x20;     CloudWatch Agent       Nginx Logs

&#x20;            |                   |

&#x20;            +---------+---------+

&#x20;                      |

&#x20;                      v

&#x20;                 CloudWatch

&#x20;               Metrics + Logs

&#x20;                      |

&#x20;                      v

&#x20;               CloudWatch Alarm

&#x20;                      |

&#x20;                      v

&#x20;                    SNS

&#x20;                      |

&#x20;                      v

&#x20;                Email Alert

&#x20;                      |

&#x20;                      v

&#x20;             Lambda Automation

