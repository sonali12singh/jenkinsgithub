###
### Variables section
###

variable "ssh_pub" {
  type        = string
  description = "SSH public key in OpenSSH format. Mandatory variable, must be unique. No default value."
}

variable "vpc_name" {
  type        = string
  default     = "silicon-designer"
  description = "VPC name. Also applies as the value for `env` tag (can be used with Cost Explorer) and gets embedded into resource names."
}

variable "vpc_cidr" {
  type        = string
  default     = null
  description = "CIDR block to use within VPC. The recommended way to assign CIDR block for new installations. Please note that this CIDR block will be divided into two subnets of equal size to alow for RDS creation. Even though RDS is optional, dynamic subnet management is not supported to avoid accidential resource replacement that might lead to data loss. Size your CIDR block accordingly."
}

variable "vpc_subnet" {
  type        = string
  default     = "172.35."
  description = "The `legacy` way to assign CIDR block for VPC, kept for backward compatibility, Does not allow to override the hardcoded netmask of `/16`."
}

variable "vpc_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region to place VPC into."
}

variable "vpc_zone" {
  type        = string
  default     = "us-east-1a"
  description = "AWS Zone to use for primary subnet."
}

variable "bkp_zone" {
  type        = string
  default     = "us-east-1b"
  description = "AWS Zone to use for backup RDS subnet."
}

variable "local_zone" {
  type        = string
  default     = "silicon-designer.home.arpa"
  description = "Route53 Zone for local subnet. Agent auto-discovery DNS records get created within this Zone. Please make sure that Zone name does not conflict with any existin Public or Prvate DNS Zones to avoid problems with DNS record resolution. Avoid using link-local zones or zone names that might become new Public zones in the future. The `home.arpa` zone is probably a reasonable choice."
}

variable "admin_ami" {
  type        = string
  default     = "ami-0dd239e274077553a"
  description = "Admin instance AMI to build on. Since Admin version 0.8.1 the only supported distribution is Oracle Linux 9. Other RHEL 9 flavors may become supported with newer releases. In this example it is OL9.2-x86_64-HVM-2023-06-21 AMI registered in us-east-1 Region. Oracle Linux AMIs can be found among Public images by Owner account ID 131827586825."
}

variable "admin_instance_type" {
  type        = string
  default     = "c5.xlarge"
  description = "c5.xlarge is the recommended starting point for Admin instances. It is a non-burstable CPU-optimized instance type and has enough RAM to run IMS and Scheduler on the same node with Admin itself.It also offers hogh-performane network and storage hardware. Adopt as you go and scale to larger instance sizes if your production load increases. For testing purposes c5.large might be suitable but it is recommended to set up a swap file."
}

variable "admin_cpu_credits" {
  type        = string
  default     = "unlimited"
  description = "If you prefer burstable instance types it is still recommended to set up an instance with unlimited CPU credits."
}

variable "admin_ebs_optimized" {
  type        = bool
  default     = true
  description = "It is recommended to use EBS-optimized instances for better storage performance, when appliccable (depends on instance type)."
}

variable "admin_disksize" {
  default     = 128
  description = "Please pay careful attention to Admin instance disk size. It serves Operating System, database files (when RDS is not in use), disk space for IMS temporary files and all the shared files - templates, content, font bundles, scripts etc. Make sure to have enough disk space for your files. Default value is merely a placeholder. Consult User Guide and your Silicon Publishing representative and do your best to plan ahead."
}

variable "admin_disktype" {
  type        = string
  default     = "gp3"
  description = "No 'magnetic' or 'disk' EBS volume type can provide performance suitable for Silicon Designer. Only suitable options are 'gp2', 'gp3' and 'Provisioned IOPS'. 'gp3' is the recommended volume type as it provides the best cost-to-performance value and also alows to adjust volume throughput and IOPS. Use AWS Console to monitor volume load and adjust settings."
}

variable "admin_data_volume_size" {
  default     = 256
  description = "It is recommended to place shared files on a dedicated EBS volume. Consult User Guide for details. EBS volume type is the same as `admin_disktype`."
}

variable "admin_data_volume_iops" {
  default     = 3000
}

variable "admin_data_volume_throughput" {
  default     = 125
}

variable "admin_data_volume_blkdev" {
  type        = string
  default     = "/dev/sdf"
  description = "Default value should be suitable in most cases."
}

variable "agent_ami" {
  type        = string
  default     = "ami-0db3480be03d8d01c"
  description = "A Windows instance is required for IDS to operate. In this example it is a Windows Server 2022 Base AMI registered in us-east-1 Region. This Windows Server version has been tested with IDS versions 18.2 to 19.5 and is known to work well. Please note: Windows Server 2025 has known issues and not currently supported."
}

variable "agent_count" {
  default     = 0
  description = "No Windows Server instance is being built by default. Set this value to the number of IDS licenses available. You can leave this value as is for the first Terraform run and build Windows instances later."
}

variable "agent_instance_type" {
  type        = string
  default     = "c5.xlarge"
  description = "c5 instance type is also suitable for all kinds of Agent instances, for the same reasons as with Admin node. As for instance size, IDS Agents are best adjusted to be large as IDS is licensed per instance. Large instances allow to run lots of IDS processes simultaneously on a single node. For mission-critical installations it is recommended to set up two large IDS instances. It allows for some redundancy while keeping number of IDS licenses reasonably low."
}

variable "agent_cpu_credits" {
  type        = string
  default     = "unlimited"
  description = "If you prefer burstable instance types it is still recommended to set up an instance with unlimited CPU credits."
}

variable "agent_disksize" {
  default     = 128
  description = "Please pay attention to Agent instance disk size too. It should have anough disk space for OS and for Template cache. Ideally, it should be large enough to keep all the Templates that are often in use to avoid unnecessary network transfers."
}

variable "agent_disktype" { default = "gp3" }
variable "agent_diskiops" { default = 3000 }
variable "agent_diskthroughput" { default = 125 }

variable "chrome_ami" {
  type        = string
  default     = "ami-0dd239e274077553a"
  description = "Chrome Agent instance AMI should be the same as for Admin instance as large portions of playbook are being reused during software setup. Chrome render engine support is a new feature which is currently under development. If you are interested in an alternative to IDS please consult your Silicon Publishing representative to see if it can be useful in your case."
}

variable "chrome_count" {
  default     = 0
  description = "No Chrome Agent instance is being built by default. Set to the desired amount if you plan to use Chrome Agent."
}

variable "chrome_instance_type" {
  type        = string
  default     = "c5.xlarge"
  description = "c5 instance type is also suitable for all kinds of Agent instances, for the same reasons as with Admin node. As for instance size, Chrome Agents can be scaled in both instance size and number. It is best to keep both scaling aprroaches in balance as it not only allows for redundancy but also distributes EBS volume load among instances."
}

variable "chrome_cpu_credits" {
  type        = string
  default     = "unlimited"
  description = "If you prefer burstable instance types it is still recommended to set up an instance with unlimited CPU credits."
}

variable "chrome_disksize" {
  default     = 120
  description = "EBS volume size requirements may vary depending on the complexity of your renders. Please consult your Silicon Publishing represenative for advise."
}

variable "chrome_disktype" { default = "gp3" }

variable "bridge_tgw" {
  type        = string
  default     = ""
  description = "This Terraform script can automatically attach VPC to designated Transit Gateway to allow for inter-VPC traffic exchange. However, another VPC, which is not under control of this script, has to be set up accordingly. This feature is primarilly meant to be used by Silicon Publishing internally."
}

variable "bridge_pxs" {
  type        = list(any)
  default     = []
  description = "Static route table entries required to reach the adjacent VPC. For use with Transit Gateway."
}

variable "dlm_interval" {
  default     = 24
  description = "Lifecycle Manager Policy snapshot interval. It is important to take backups. Even in a testing environment."
  sensitive   = false
}

variable "dlm_retain_copies" {
  default     = 6
  description = "By default Lifecycle Manager Policy keeps 6 most recent snapshots. Sometimes accidential deletions or other data problems get noticed with a delay. It is recommended to keep daily snapshots at least for a week. You may wish to keep snapshots longer for a critical environment or keep less for a testing environment to reduce costs. Adjust to your requirements."
}

variable "dlm_snapshot_time" {
  type        = string
  default     = "06:00"
  description = "Time of day when Lifecycle Manager takes snapshots."
}

variable "dlm_extra_target_tags" {
  type        = map(any)
  default     = {}
  description = "Lifecycle Manager takes snapshots of all the EBS volumes attached to EC2 instances which are assigned tag with name `DLMBackupTarget` and value of `var.vpc_name` variable. This is enough for normal operation. If you create additional EC2 instances within this VPC and wish to instruct Lifecycle Manager to take snapshots of these additional resources, you can either assign identical tag to these instances or specify additional tags with this variable."
}

variable "dlm_tags_to_add" {
  type        = map(any)
  default     = { Application = "Silicon Designer" }
  description = "Lifecycle Manager can add extra tags to snapshots taken. This is convenient when snapshots are being serached or filtered."
}

variable "admin_fqdn" {
  type        = string
  default     = "~ # REQUIRED: Admin UI domain name, procure DNS A record before proceeding"
  description = "Not used by Terraform directly. Optional. This value will be substituted when generating Ansible inventory template."
}

variable "rds_allocated_storage" {
  default     = 0
  description = "If you wish to use RDS for database, set this variable to non-zero value. If set to zero, RDS instance creation is skipped. Silicon Designer Admin aims to use database efficiently and does not store any unecessary data so volume requirements are low and it is safe to set this variable to `20` - the minimum value allowed bu AWS."
}

variable "rds_maximum_storage" {
  default     = 100
  description = "RDS instance is being built with Storage autoscaling feature enabled. Under normal circumstances database will never exceed the default 20 GiB of storage but it is safe to set this value high as a precaution."
}

variable "rds_engine_version" {
  type        = string
  default     = "10.11"
  description = "Since Silicon Designer Admin 0.8.0 only MariaDB 10.6 or higher are supported. MariaDB 10.11 has also been tested, this is the recommended version."
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t3.medium"
  description = "For testing purposes or low-to-moderate loads `db.t2.medium` is usually enough. Even though this is a burstable instance class, it provides acceptable performance. In a critical environment you may wish to start with `db.m5.large`. If high loads are expected, it is recommended to perform a stress-test and make sure that instance class chosen sustains test conditions prior to public launch."
  sensitive   = false
}

variable "rds_username" {
  type        = string
  default     = "rdsdba"
  description = "You may wish to assign a unique username for additional secrecy."
  sensitive   = true
}

variable "rds_password" {
  type        = string
  default     = "Big$ecreT"
  description = "Please generate a secure password and replace this placeholder."
  sensitive   = true
}

variable "rds_storage_type" {
  type        = string
  default     = "gp3"
  description = "`gp3` storage type allows for 3000 IOPS and 125 MB/s throughput at low cost. This should be enough at virtually any circumstances."
}

variable "rds_storage_encrypted" {
  type        = bool
  default     = true
  description = "Specifies whether the DB instance is encrypted."
}

variable "rds_backup_retention_period" {
  default     = 5
  description = "The days to retain backups for. Must be between 0 and 35."
}

variable "rds_backup_window" {
  type        = string
  default     = "03:04-03:34"
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Must not overlap with maintenance_window."
}

variable "rds_copy_tags_to_snapshot" {
  type        = bool
  default     = true
  description = "Copy all Instance tags to snapshots."
}

variable "rds_deletion_protection" {
  type        = bool
  default     = true
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true."
}

variable "rds_maintenance_window" {
  type        = string
  default     = "mon:07:56-mon:08:26"
  description = "The window to perform maintenance in."
}

# locals {

#   vpc_cidr_block       = coalesce(data.vpc_cidr, "${data.vpc_subnet}0.0/16")
#   sl_subnet_bit_size   = 32 - split("/", data.aws_subnet.standalone.cidr_block)[1]
#   sl_subnet_host_count = pow(2, local.sl_subnet_bit_size)
# }
locals {
  vpc_cidr_block       = data.aws_vpc.existing.cidr_block
  sl_subnet_bit_size   = 32 - split("/", data.aws_subnet.standalone.cidr_block)[1]
  sl_subnet_host_count = pow(2, local.sl_subnet_bit_size)
}

provider "aws" {
  region = var.vpc_region
}

data "aws_vpc" "existing" {
  id = var.vpc_id
  }



/*
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = var.vpc_name
    env  = var.vpc_name
  }
}

resource "aws_subnet" "standalone" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 1, 0)
  availability_zone       = var.vpc_zone
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.vpc_name}-${var.vpc_zone}"
    env  = var.vpc_name
  }
}

resource "aws_subnet" "backup" {
  count                   = var.rds_allocated_storage == 0 ? 0 : 1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 1, 1)
  availability_zone       = var.bkp_zone
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.vpc_name}-${var.vpc_zone}"
    env  = var.vpc_name
  }
}
*/
data "aws_subnet" "standalone" {
  id = var.standalone_subnet_id
}

data "aws_subnet" "backup" {
  id = var.backup_subnet_id
}



# resource "aws_internet_gateway" "gw" {
#   vpc_id = data.aws_vpc.existing.id
#   tags = {
#     Name = var.vpc_name
#     env  = var.vpc_name
#   }
# }
data "aws_internet_gateway" "gw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

resource "aws_eip" "admin" {

  tags = {
    Name = "${var.vpc_name}-admin"
    env  = var.vpc_name
  }
}

# resource "aws_route_table" "standalone" {
#   vpc_id     = aws_vpc.main.id
#   depends_on = [aws_internet_gateway.gw]

#   tags = {
#     Name = "${var.vpc_name}-${var.vpc_zone}"
#     env  = var.vpc_name
#   }
# }

# for using the exixting use this 
# data "aws_route_table" "existing" {
#   vpc_id = data.aws_vpc.existing.id
#   # Optionally add filters for tags or name
#   filter {
#     name   = "tag:Name"
#     values = ["${var.vpc_name}-${var.vpc_zone}"]
#   }
# }
# this is creating the new route table
resource "aws_route_table" "standalone" {
  vpc_id     = data.aws_vpc.existing.id
  # depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.vpc_name}-${var.vpc_zone}"
    env  = var.vpc_name
  }
}

# for creating the existing route table association with the existing subnet
# resource "aws_route" "default_gw" {
#   route_table_id         = data.aws_route_table.existing.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = data.aws_internet_gateway.gw.id
# }
resource "aws_route" "default_gw" {
  route_table_id         = aws_route_table.standalone.id
  destination_cidr_block = "0.0.0.0/0"   # Route all traffic need to change to your needs
  gateway_id             = data.aws_internet_gateway.gw.id
  depends_on             = [aws_route_table.standalone]
}
# for creating the route table association with the existing subnet
# resource "aws_route_table_association" "standalone" {
#   subnet_id      = data.aws_subnet.standalone.id
#   route_table_id = data.aws_route_table.existing.id
# }


# for creating the route table association with the new route table
resource "aws_route_table_association" "standalone" {
  subnet_id      = data.aws_subnet.standalone.id
  route_table_id = aws_route_table.standalone.id
}


resource "aws_vpc_dhcp_options" "standalone" {
  domain_name         = var.local_zone
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = var.vpc_name
    env  = var.vpc_name
  }
}

resource "aws_vpc_dhcp_options_association" "standalone" {
  vpc_id          = data.aws_vpc.existing.id
  dhcp_options_id = aws_vpc_dhcp_options.standalone.id
}

resource "aws_route53_zone" "int" {
  name = var.local_zone
  vpc {
    vpc_id = data.aws_vpc.existing.id
  }
}
resource "aws_route53_record" "admin" {
  zone_id = aws_route53_zone.int.zone_id
  name    = "admin.${var.local_zone}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.admin.private_ip]
}

resource "aws_route53_record" "agent" {
  count   = var.agent_count
  zone_id = aws_route53_zone.int.zone_id
  name    = "agent${count.index}.${var.local_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.agent.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "chrome" {
  count   = var.chrome_count
  zone_id = aws_route53_zone.int.zone_id
  name    = "agent-chrome${count.index}.${var.local_zone}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.chrome.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "discovery" {
  zone_id = aws_route53_zone.int.zone_id
  name    = "admin.${var.local_zone}"
  type    = "TXT"
  ttl     = "300"
  records = ["http://admin.${var.local_zone}"]
}

#
# Security Groups
# These security groups are used to control access to the instances in the VPC.
resource "aws_security_group" "rds" {
  count       = var.rds_allocated_storage == 0 ? 0 : 1
  name        = "${var.vpc_name}-agent-rds"
  description = "Local access to RDS instance"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.trusted_admin_cidr
    description = "MySQL from trusted hosts"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-rds"
    env  = var.vpc_name
  }
}
resource "aws_security_group" "admin" {
  name        = "${var.vpc_name}-admin-node"
  description = "Silicon Designer Admin node ruleset"
  vpc_id      = data.aws_vpc.existing.id
  # Allow ICMP only from within the VPC
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "ICMP from VPC only"
  }
  # Allow SSH only from your trusted IP (replace with your real IP or CIDR)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = var.trusted_admin_cidr
    description = "Secure SHell"
  }
  # Allow HTTP/HTTPS from anywhere if this is a public web server
  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "Public http"
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "Public https"
  # }
  # Allow private subnet traffic (if needed)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_subnet.standalone.cidr_block]
    description = "Private subnet traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-admin-node"
    env  = var.vpc_name
  }
}

resource "aws_security_group" "agent" {
  name        = "${var.vpc_name}-agent-node"
  description = "Silicon Designer IDS Agent node ruleset"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "ICMP from vpc only"
  }
  # RDP only from trusted admin IPs (set in tfvars)
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.trusted_admin_cidr
    description = "Remote DesktoP from trusted IPs"
  }
  # Allow communication from admin node only
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${aws_instance.admin.private_ip}/32"]
    description = "Admin node communications"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-agent-node"
    env  = var.vpc_name
  }
}

resource "aws_security_group" "chrome" {
  name        = "${var.vpc_name}-chrome-node"
  description = "Silicon Designer Chrome Agent node ruleset"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "ICMP from vpc only "
  }
  # SSH only from trusted admin IPs (set in tfvars)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.trusted_admin_cidr
    description = "Remote SHell from trusted IPs"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_subnet.standalone.cidr_block]
    description = "Private subnet traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-chrome-node"
    env  = var.vpc_name
  }
}

resource "aws_security_group" "ec2_exceptions" {
  name        = "ec2_exceptions"
  description = "Security Group exceptions for ec2 instances, these rules will not be rewritten by Terraform"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.trusted_admin_cidr
    description = "SSH from trusted hosts"
  }
# Add more specific rules as needed
  lifecycle {
    ignore_changes = [ingress]
  }

  tags = {
    env = var.vpc_name
  }
}
resource "aws_security_group" "rds_exceptions" {
  name        = "rds_exceptions"
  description = "Security Group exceptions for RDS, these rules will not be rewritten by Terraform"
  vpc_id      = data.aws_vpc.existing.id

  # Example: Allow MySQL (3306) only from trusted admin CIDRs
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.trusted_admin_cidr
    description = "MySQL from trusted hosts"
  }

  # Add more specific rules as needed, for example:
  # ingress {
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   cidr_blocks = var.trusted_admin_cidr
  #   description = "Postgres from trusted hosts"
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = {
    env = var.vpc_name
  }
}



resource "aws_key_pair" "ansible" {
  key_name   = "${var.vpc_name}-ansible-key"
  public_key = var.ssh_pub

  tags = {
    env = var.vpc_name
  }
}

resource "aws_instance" "admin" {
  ami           = var.admin_ami
  key_name      = "${var.vpc_name}-ansible-key"
  instance_type = var.admin_instance_type
  ebs_optimized = var.admin_ebs_optimized
  subnet_id     = data.aws_subnet.standalone.id
  private_ip    = cidrhost(data.aws_subnet.standalone.cidr_block, 5)
  vpc_security_group_ids = [
    aws_security_group.admin.id,
    aws_security_group.ec2_exceptions.id
  ]

  root_block_device {
    volume_size           = var.admin_disksize
    volume_type           = var.admin_disktype
    delete_on_termination = "false"
  }

  user_data = <<EOF
#cloud-config
hostname: admin
fqdn: admin.${var.vpc_name}
prefer_fqdn_over_hostname: true
swap:
  filename: /.swapfile
  size: auto
  maxsize: 8589934592
EOF

  credit_specification {
    cpu_credits = var.admin_cpu_credits
  }

  tags = merge(
    { DLMBackupTarget = var.vpc_name },
    {
      Name = "${var.vpc_name}-admin"
      env  = var.vpc_name
      App  = "Nucleus"
      OS   = "Linux"
    }
  )

  lifecycle {
    ignore_changes = [ebs_optimized, user_data, ami]
  }

  volume_tags = {
    Name = "${var.vpc_name}-admin"
    env  = var.vpc_name
  }
}

resource "aws_ebs_volume" "admin_data" {
  count = var.admin_data_volume_size == 0 ? 0 : 1
  availability_zone = data.aws_subnet.standalone.availability_zone

  type = var.admin_disktype
  size = var.admin_data_volume_size

  tags = {
    Name = "${var.vpc_name}-admin"
    env  = var.vpc_name
  }
}

resource "aws_volume_attachment" "admin_data" {
  count       = var.admin_data_volume_size == 0 ? 0 : 1
  device_name = var.admin_data_volume_blkdev
  volume_id   = element(aws_ebs_volume.admin_data.*.id, count.index)
  instance_id = aws_instance.admin.id
}

resource "aws_instance" "agent" {
  ami           = var.agent_ami
  key_name      = "${var.vpc_name}-ansible-key"
  instance_type = var.agent_instance_type
  count         = var.agent_count

  subnet_id  = data.aws_subnet.standalone.id
  private_ip = cidrhost(data.aws_subnet.standalone.cidr_block, 6 + count.index)
  vpc_security_group_ids = [
    aws_security_group.agent.id,
    aws_security_group.ec2_exceptions.id
  ]
  get_password_data = true

  credit_specification {
    cpu_credits = var.agent_cpu_credits
  }

  root_block_device {
    volume_size           = var.agent_disksize
    volume_type           = var.agent_disktype
    delete_on_termination = "false"
  }

  tags = merge(
    { DLMBackupTarget = var.vpc_name },
    {
      Name = "${var.vpc_name}-agent-${count.index}"
      App  = "Nucleus"
      OS   = "Windows"
      env  = var.vpc_name
    }
  )

  lifecycle {
    ignore_changes = [ebs_optimized, user_data, ami]
  }

  volume_tags = {
    Name = "${var.vpc_name}-agent-${count.index}"
    env  = var.vpc_name
  }
}

resource "aws_instance" "chrome" {
  ami           = var.chrome_ami
  key_name      = "${var.vpc_name}-ansible-key"
  instance_type = var.chrome_instance_type
  count         = var.chrome_count

  subnet_id  = data.aws_subnet.standalone.id
  private_ip = cidrhost(data.aws_subnet.standalone.cidr_block, local.sl_subnet_host_count / 4 + count.index)
  vpc_security_group_ids = [
    aws_security_group.chrome.id,
    aws_security_group.ec2_exceptions.id
  ]

  credit_specification {
    cpu_credits = var.chrome_cpu_credits
  }

  root_block_device {
    volume_size           = var.chrome_disksize
    volume_type           = var.chrome_disktype
    delete_on_termination = "false"
  }

  user_data = <<EOF
#cloud-config
hostname: chrome${count.index}
fqdn: chrome${count.index}.${var.vpc_name}
prefer_fqdn_over_hostname: true
write_files:
  - path: /etc/silpub/designer/automount
    content: |
      SDMNT_SOURCE="//admin.${var.local_zone}/Shared"
      SDMNT_FSTYPE=cifs
      SDMNT_OPTIONS="uid=spidsn,gid=spidsn,user=nginx,pass=anonymous,_netdev,x-systemd.automount"
    owner: 'root:root'
    permissions: '0640'
  - path: /etc/silpub/designer/service/chrome.args
    content: |
      ARGS='--node-port=33365 --node-name=chrome${count.index}.${var.vpc_name}'
    owner: 'root:root'
    permissions: '0644'
swap:
  filename: /.swapfile
  size: auto
  maxsize: 8589934592
yum_repos:
  silpub-public:
    name: Silicon Publishing public repository
    baseurl: https://dist.silcn.co/pulp/content/spi/Library/custom/Designer/public/
    gpgkey: https://dist.silcn.co/pulp/content/spi/Library/custom/Designer/files/rpmsign.pub
    enabled: true
    gpgcheck: true
  google-chrome:
    name: google-chrome
    baseurl: https://dl.google.com/linux/chrome/rpm/stable/x86_64
    gpgkey: https://dl.google.com/linux/linux_signing_key.pub
    enabled: true
    gpgcheck: true
runcmd:
- dnf install -y spidsn-chrome
- firewall-cmd --reload
- firewall-cmd --add-service=spidsn-chrome --permanent
power_state:
  delay: now
  mode: reboot
  message: "Finalizing setup with reboot"
  timeout: 10
EOF

  tags = merge(
    { DLMBackupTarget = var.vpc_name },
    {
      Name = "${var.vpc_name}-agent-chrome-${count.index}"
      App  = "Nucleus"
      OS   = "Windows"
      env  = var.vpc_name
    }
  )

  lifecycle {
    ignore_changes = [ebs_optimized, user_data, ami]
  }

  volume_tags = {
    Name = "${var.vpc_name}-agent-chrome-${count.index}"
    env  = var.vpc_name
  }
}

resource "aws_eip_association" "admin" {
  instance_id   = aws_instance.admin.id
  allocation_id = aws_eip.admin.id
}

resource "aws_route" "peers" {
  count                  = length(var.bridge_pxs)
  route_table_id         = data.aws_route_table.existing.id
  destination_cidr_block = var.bridge_pxs[count.index]
  transit_gateway_id     = var.bridge_tgw
  depends_on             = [aws_route_table.standalone]
}

resource "aws_db_subnet_group" "default" {
  count      = var.rds_allocated_storage == 0 ? 0 : 1
  name       = replace(var.vpc_name, ".", "")
  subnet_ids = [data.aws_subnet.standalone.id, data.aws_subnet.backup.id]
}

resource "aws_db_instance" "default" {
  count                 = var.rds_allocated_storage == 0 ? 0 : 1
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_maximum_storage
  engine                = "mariadb"
  engine_version        = var.rds_engine_version
  instance_class        = var.rds_instance_class
  storage_encrypted     = var.rds_storage_encrypted
  storage_type          = var.rds_storage_type
  identifier            = replace(var.vpc_name, ".", "-")
  db_name               = "sdadmin_app"
  username              = var.rds_username
  password              = var.rds_password

  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  copy_tags_to_snapshot   = var.rds_copy_tags_to_snapshot
  deletion_protection     = var.rds_deletion_protection
  maintenance_window      = var.rds_maintenance_window

  db_subnet_group_name = aws_db_subnet_group.default[0].name
  vpc_security_group_ids = [
    aws_security_group.rds[0].id,
    aws_security_group.rds_exceptions.id
  ]
  final_snapshot_identifier = "final-snapshot-${replace(var.vpc_name, ".", "")}"

  tags = {
    env = var.vpc_name
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "DLMRole-${replace(var.vpc_name, ".", "")}"
  path = "/service-role/"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole",
          Principal = {
            Service = "dlm.amazonaws.com"
          },
          Effect = "Allow",
          Sid    = ""
        }
      ]
    }
  )

  tags = {
    env = var.vpc_name
  }
}

resource "aws_iam_role_policy" "dlm_lifecycle_policy" {
  name = "AWSDataLifecycleManagerServiceRole"
  role = aws_iam_role.dlm_lifecycle_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_dlm_lifecycle_policy" "instance_snapshots" {
  description        = replace(var.vpc_name, ".", "-")
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"]

    schedule {
      copy_tags   = true
      name        = "${var.dlm_interval}h"
      tags_to_add = var.dlm_tags_to_add
      create_rule {
        interval = var.dlm_interval
        times    = [var.dlm_snapshot_time]
      }
      retain_rule {
        count = var.dlm_retain_copies
      }
    }

    parameters {
      exclude_boot_volume = false
      no_reboot           = false
    }

    target_tags = merge(
      { DLMBackupTarget = var.vpc_name },
      var.dlm_extra_target_tags
    )
  }

  tags = {
    env = var.vpc_name
  }
}
