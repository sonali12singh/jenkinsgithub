# SSH public key (replace with your real key)
ssh_pub              = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFjaXKyO69jlQXfEG4wWg9E02Vkx53lU7vYsbiuqhTYKgIuu5o8LktacM7igbDVWyNBacVANA1emiN5z38O/a0mbj53VSYiH55Vv8G8+DXoD5CFpEhWNvwMShk7bh02CHRgBUKEkkQE1qlISnNddtDnrbBYfZ5XLPFNqSDxAo0nFpq40/dJ6pdgj6njXyOcvE1l+gXfmkUHfk8i5TNHheHcE0LrThCIXqCYi43aAPUX1kmV+JzbN47tydJYN/rrSO9+phxjswi/iCGSgbD8ijxJDQUYRzJMw1v9WRjQKURFGgnBW8ribAF0qLjPyyoDCCIte+kBZTvIylZFiw7gDK7fokXSp6um32Ye8KP27zqPHO+y1iUMqmtEgses4+O+Lek6kNDC6poxPxgNeSCSikUL5jkSkjrGZoid58zjKLqGKEMxunjfIe6WmGFsZzJlOgkMbc5Levwnvf7MhobWFSSh1TqSc47JEmad/gCPB4X2GM3iNs7OF0TrTSfnurXb4M="

# VPC and networking
vpc_name        = "pci-vpc"
vpc_cidr        = "10.153.28.0/22"                    #"172.35.0.0/16"
vpc_id     =       "vpc-00bd4d2758879b1e0"          #"172.35."
standalone_subnet_id =    "subnet-0a797df6e7dcae3db"                  #"172.35.10.0/24"
backup_subnet_id    = "subnet-0832e5bee2510044d"           #"172.35.20.0/24"
route_table_id = "rtb-08298ccf6aab2797e"        #"values(aws_route_table.pci_vpc_rt.*.id)[0]"
igw_id =         "igw-0046f676bace1feb0"
vpc_region      = "us-east-1"
vpc_zone        = "us-east-1a"
bkp_zone        = "us-east-1b"
local_zone      = "pci-vpc.home.arpa"
# Example trusted admin CIDR (replace with your real IP/CIDR)
trusted_admin_cidr = ["203.0.113.0/24"]
# Admin node
admin_ami              = "ami-0dd239e274077553a"
admin_instance_type    = "c5.xlarge"
admin_cpu_credits      = "unlimited"
admin_ebs_optimized    = true
admin_disksize         = 128
admin_disktype         = "gp3"
admin_data_volume_size = 256
admin_data_volume_iops = 3000
admin_data_volume_throughput = 125
admin_data_volume_blkdev = "/dev/sdf"

# Agent node
agent_ami           = "ami-0db3480be03d8d01c"
agent_count         = 0  # You can leave this value as is for the first Terraform run and build Windows instances later
agent_instance_type = "c5.xlarge"
agent_cpu_credits   = "unlimited"
agent_disksize      = 128
agent_disktype      = "gp3"
agent_diskiops      = 3000
agent_diskthroughput = 125

# Chrome node
chrome_ami           = "ami-0dd239e274077553a"
chrome_count         = 0 #No Chrome Agent instance is being built by default. Set to the desired amount if you plan to use Chrome Agent.
chrome_instance_type = "c5.xlarge"
chrome_cpu_credits   = "unlimited"
chrome_disksize      = 120
chrome_disktype      = "gp3"

# Transit Gateway
bridge_tgw = ""
bridge_pxs = []

# Lifecycle Manager (DLM)
dlm_interval        = 24
dlm_retain_copies   = 6
dlm_snapshot_time   = "06:00"
dlm_extra_target_tags = {}
dlm_tags_to_add     = { Application = "Silicon Designer" }

# Admin UI FQDN (not used directly by Terraform)
admin_fqdn = "admin.dev-vpc.home.arpa"

# RDS configuration
rds_allocated_storage         = 20
rds_maximum_storage           = 100
rds_engine_version            = "10.11"
rds_instance_class            = "db.t3.medium"
rds_username                  = "rdsdba"
rds_password                  = "Big$ecreT"
rds_storage_type              = "gp3"
rds_storage_encrypted         = true
rds_backup_retention_period   = 5
rds_backup_window             = "03:04-03:34"
rds_copy_tags_to_snapshot     = true
rds_deletion_protection       = true
rds_maintenance_window        = "mon:07:56-mon:08:26"



# # Subnet IDs for RDS and EC2 (must be in different AZs for RDS)
# standalone_subnet_id = "subnet-0a1b2c3d4e5f6a7b8"  # us-east-1a
# backup_subnet_id     = "subnet-1a2b3c4d5e6f7a8b9"  # us-east-1b

# # Subnet CIDRs if needed (for new subnet creation)
# standalone_subnet_cidr = "172.35.10.0/24"
# backup_subnet_cidr     = "172.35.20.0/24"
