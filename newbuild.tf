
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
