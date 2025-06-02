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

variable "vpc_id" {
  type        = string
  description = "ID of existing VPC"
}
variable "vpc_cidr_block" {
  type        = string
  default     = null
  description = "CIDR block to use within VPC. The recommended way to assign CIDR block for new installations. Please note that this CIDR block will be divided into two subnets of equal size to alow for RDS creation. Even though RDS is optional, dynamic subnet management is not supported to avoid accidential resource replacement that might lead to data loss. Size your CIDR block accordingly."
}
variable "standalone_subnet_id" {
  type        = string
  description = "ID of existing primary subnet (for admin/agent/chrome)"
}
variable "standalone_subnet_cidr_block" {}
variable "standalone_subnet_availability_zone" {}

variable "backup_subnet_id" {
  type        = string
  description = "ID of existing backup subnet (for RDS)"
}
variable "backup_subnet_cidr_block" {}
variable "backup_subnet_availability_zone" {}

variable "route_table" {
  type        = string
  description = "ID of existing route table to use"
}
variable "igw_id" {
  type        = string
  description = "ID of existing Internet Gateway"
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
  default = 3000
}

variable "admin_data_volume_throughput" {
  default = 125
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
  default     = "~"# REQUIRED: Admin UI domain name, procure DNS A record before proceeding"
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
