# PoCAcme

This a PoC of configuring two EC2 Instances using Terraform + Ansible. One VM will run NGINX + PHP and with two Prometheus exporters and the orther one, Prometheus + Grafana for monitoring.

This project is just for learning how to configure this services using Terraform + Ansible, so I hope it will be evolving as I get more skilled.

Note: This is a paralel project of [GMansioni/PoCAcmeLocal](https://github.com/GMansioni/PoCAcmeLocal)

### Prerequisites

* AWS CLI conected with a profile to your AWS account
* Ansible >=2.9
* Terraform CLI

### Software used

EC2 Instances are created using the image *ami-00399ec92321828f5* Ubuntu Server 20.04 LTS (HVM), SSD Volume Type.

All the packages used are the included in this linux distribution.

Except:
* community.grafana plugin for ansible
* grafana oficial repository is added
* php-fpm-exporter from [bakins/php-fpm-exporter](https://github.com/bakins/php-fpm-exporter)

Services:
* Web:
  * Web :80 (8080 y 9000 for status)
  * Nginx exporter: 9113
  * Php exporter: 9253
  * SSH :22

* Grafana Server:
  * Grafana :3000
  * Prometheus: 9090
  * SSH: 22


### Starting

Configure your AWS CLI with a profile to access your AWS account.
Edit the file variables.tf and update your profile.
Just clone the project and execute "terraform init && terraform plan && terraform apply"

The ansible execution may fail if EC2 are not ready, just retry with "terraform apply"

Each provision generates new keys, so you can access your EC2 instances with "ssh -i private_key.pem ubuntu@ec2_ip"

### Update log

#### 2021-07-12 First Commit

Known issues / pending improvements
* php-fpm-exporter is working but grafana doesn't show metrics
* Internal IP's are hardcoded
* Passwords are in plain test on the playbook
* Grafana Dashboards included are for test. I need to work on real ones
* Grafana Dashboards doesn't show at the welcome screen
* Comments are in spanish ;-)
* Retrive dashboards .json from Githubs sometimes fail, retry with "vagrant provision"
* Adjust security group rules
* Wait time to run asinsible playbook check EC2 availabity
