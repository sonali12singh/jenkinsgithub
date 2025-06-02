
locals {
  vpc_cidr_block       = var.vpc_cidr_block
  sl_subnet_bit_size   = 32 - tonumber(split("/", var.standalone_subnet_cidr_block)[1])
  sl_subnet_host_count = pow(2, local.sl_subnet_bit_size)
}
provider "aws" {
  region = var.vpc_region
}
#---Networking Resources 
resource "aws_eip" "admin" {
  # domain = "vpc"
  tags = {
    Name = "${var.vpc_name}-admin"
    env  = var.vpc_name
  }
}

#--- if the exixting vpc has  a DHCP option set that sets domain name and dns server we can skip
resource "aws_vpc_dhcp_options" "standalone" {
  domain_name         = var.local_zone
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = var.vpc_name
    env  = var.vpc_name
  }
}

resource "aws_vpc_dhcp_options_association" "standalone" {
  vpc_id          = var.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.standalone.id
}
#----DNS and Route53 Resources
resource "aws_route53_zone" "int" {
  name = var.local_zone
  vpc {
    vpc_id = var.vpc_id
  }
}
# resource "aws_route" "default_gw" {
#   route_table_id         = var.route_table_id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = var.igw_id
# }

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
  records = [aws_instance.agent[count.index].private_ip]
}

resource "aws_route53_record" "chrome" {
  count   = var.chrome_count
  zone_id = aws_route53_zone.int.zone_id
  name    = "agent-chrome${count.index}.${var.local_zone}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.chrome[count.index].private_ip]

}

resource "aws_route53_record" "discovery" {
  zone_id = aws_route53_zone.int.zone_id
  name    = "admin.${var.local_zone}"
  type    = "TXT"
  ttl     = "300"
  records = ["http://admin.${var.local_zone}"]
}
#----Security Groups
resource "aws_security_group" "admin" {
  name        = "${var.vpc_name}-admin-node"
  description = "Silicon Designer Admin node ruleset"
  vpc_id      = var.vpc_id

  # ICMP only from within VPC 
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "ICMP from vpc"
  }
  #----ssh only from trusted admin CIDR
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Secure SHell"
  }
  # Allow HTTP/HTTPS from public or restricted as needed

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"] # change if not public-facing
  #   description = "Public http"
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "Public https"
  # }
  # internal communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Private subnet traffic"
  }
  # Allow all outbound traffic
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
  vpc_id      = var.vpc_id

  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "ICMP"
  }
  #RDP only from admin node or trusted CIDR
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.admin.private_ip}/32"]
    description = " RDP from trusted Remote Desktop"
  }

  # Agent specific ports from admin
  ingress {
    from_port   = 8000
    to_port     = 8100
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.admin.private_ip}/32"] # security_groups = [aws_security_group.admin.id]
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
  vpc_id      = var.vpc_id

  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    # cidr_blocks = [data.aws_subnet.standalone.cidr_block]
    cidr_blocks = [var.vpc_cidr_block]
    description = "ICMP within subnet "
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.admin.private_ip}/32"]
    description = " SSH from Secure SHell"
  }
  ingress {
    from_port   = 33365
    to_port     = 33365
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.admin.private_ip}/32"]
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
  vpc_id      = var.vpc_id
  # No ingress rules managed by Terraform
  # ingress = [
  #   {
  #     cidr_blocks      = ["0.0.0.0/0"]
  #     description      = "Trusted hosts can access any ports"
  #     from_port        = 0
  #     to_port          = 0
  #     protocol         = "-1"
  #     cidr_blocks      = []
  #     ipv6_cidr_blocks = []
  #     prefix_list_ids  = []
  #     security_groups  = []
  #     self             = false
  #   }
  # ]

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = {
    env = var.vpc_name
  }
}
# RDS Exception Security Group (for manual exceptions, not managed by Terraform)
resource "aws_security_group" "rds_exceptions" {
  name        = "rds_exceptions"
  description = "Security Group exceptions for RDS, these rules will not be rewritten by Terraform"
  vpc_id      = var.vpc_id
  # No ingress rules managed by Terraform
  # ingress = [
  #   {
  #     cidr_blocks      = ["0.0.0.0/0"]
  #     description      = "Trusted hosts can access any ports"
  #     from_port        = 0
  #     to_port          = 0
  #     protocol         = "-1"
  #     cidr_blocks      = []
  #     ipv6_cidr_blocks = []
  #     prefix_list_ids  = []
  #     security_groups  = []
  #     self             = false
  #   }
  # ]

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = {
    env = var.vpc_name
  }
}

resource "aws_security_group" "rds" {
  count       = var.rds_allocated_storage == 0 ? 0 : 1
  name        = "${var.vpc_name}-agent-rds"
  description = "Local access to RDS instance"
  vpc_id      = var.vpc_id

  # ingress {
  #   from_port   = -1
  #   to_port     = -1
  #   protocol    = "icmp"
  #   cidr_blocks = [var.vpc_cidr_block]
  #   description = "ICMP"
  # }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.admin.id, aws_security_group.agent.id]
    description     = "MySQL From agent and admin nodes"
  }

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "${var.vpc_name}-rds"
    env  = var.vpc_name
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

  subnet_id  = var.standalone_subnet_id
  private_ip = cidrhost(var.standalone_subnet_cidr_block, 5)
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
  count             = var.admin_data_volume_size == 0 ? 0 : 1
  availability_zone = var.standalone_subnet_availability_zone
  type              = var.admin_disktype
  size              = var.admin_data_volume_size
  iops              = var.admin_data_volume_iops
  throughput        = var.admin_data_volume_throughput

  tags = {
    Name = "${var.vpc_name}-admin"
    env  = var.vpc_name
  }
}

resource "aws_volume_attachment" "admin_data" {
  count       = var.admin_data_volume_size == 0 ? 0 : 1
  device_name = var.admin_data_volume_blkdev
  volume_id = aws_ebs_volume.admin_data[0].id
  instance_id = aws_instance.admin.id
}

resource "aws_instance" "agent" {
  ami           = var.agent_ami
  key_name      = "${var.vpc_name}-ansible-key"
  instance_type = var.agent_instance_type
  count         = var.agent_count

  subnet_id  = var.standalone_subnet_id
  private_ip = cidrhost(var.standalone_subnet_cidr_block, 6 + count.index)
  vpc_security_group_ids = [
    aws_security_group.agent.id,
    aws_security_group.ec2_exceptions.id
  ]
  get_password_data = false

  credit_specification {
    cpu_credits = var.agent_cpu_credits
  }

  root_block_device {
    volume_size           = var.agent_disksize
    volume_type           = var.agent_disktype
    iops                  = var.agent_diskiops
    throughput            = var.agent_diskthroughput
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

  subnet_id  = var.standalone_subnet_id
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
  route_table_id         = var.route_table
  destination_cidr_block = var.bridge_pxs[count.index]
  transit_gateway_id     = var.bridge_tgw
}
#RDS CONFIGURATION
# This section creates an RDS instance if the allocated storage is greater than 0
resource "aws_db_subnet_group" "default" {
  name       = replace(var.vpc_name, ".", "")
  subnet_ids = [var.standalone_subnet_id, var.backup_subnet_id]
  tags = {
    Name = "${var.vpc_name}-rds"
    env  = var.vpc_name
  }
}
# resource "aws_db_subnet_group" "default" {
#   count      = var.rds_allocated_storage == 0 ? 0 : 1
#   name       = replace(var.vpc_name, ".", "")
#   subnet_ids = [var.standalone_subnet_id, data.aws_subnet.backup[0].id]
# }

resource "aws_db_instance" "default" {
  count                 = var.rds_allocated_storage > 0 ? 1 : 0
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

  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [
    aws_security_group.rds[0].id,
    aws_security_group.rds_exceptions.id
  ]
  final_snapshot_identifier = "final-snapshot-${replace(var.vpc_name, ".", "")}"

  tags = {
    env = var.vpc_name
  }
}

# resource "aws_iam_role" "dlm_lifecycle_role" {
#   name = "DLMRole-${replace(var.vpc_name, ".", "")}"
#   path = "/service-role/"

#   # managed_policy_arns = [
#   #   "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole",
#   # ]

#   assume_role_policy = jsonencode(
#     {
#       Version = "2012-10-17",
#       Statement = [
#         {
#           Action = "sts:AssumeRole",
#           Principal = {
#             Service = "dlm.amazonaws.com"
#           },
#           Effect = "Allow",
#           Sid    = ""
#         }
#       ]
#     }
#   )

#   tags = {
#     env = var.vpc_name
#   }
# }
resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "DLMRole-${replace(var.vpc_name, ".", "")}"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "dlm.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
    }
  )

  tags = {
    env = var.vpc_name
  }
}

resource "aws_iam_role_policy_attachment" "dlm_lifecycle" {
  role       = aws_iam_role.dlm_lifecycle_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
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
