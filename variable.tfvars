# SSH public key (replace with your real key)
ssh_pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFjaXKyO69jlQXfEG4wWg9E02Vkx53lU7vYsbiuqhTYKgIuu5o8LktacM7igbDVWyNBacVANA1emiN5z38O/a0mbj53VSYiH55Vv8G8+DXoD5CFpEhWNvwMShk7bh02CHRgBUKEkkQE1qlISnNddtDnrbBYfZ5XLPFNqSDxAo0nFpq40/dJ6pdgj6njXyOcvE1l+gXfmkUHfk8i5TNHheHcE0LrThCIXqCYi43aAPUX1kmV+JzbN47tydJYN/rrSO9+phxjswi/iCGSgbD8ijxJDQUYRzJMw1v9WRjQKURFGgnBW8ribAF0qLjPyyoDCCIte+kBZTvIylZFiw7gDK7fokXSp6um32Ye8KP27zqPHO+y1iUMqmtEgses4+O+Lek6kNDC6poxPxgNeSCSikUL5jkSkjrGZoid58zjKLqGKEMxunjfIe6WmGFsZzJlOgkMbc5Levwnvf7MhobWFSSh1TqSc47JEmad/gCPB4X2GM3iNs7OF0TrTSfnurXb4M="

# VPC and networking
# VPC and networking
vpc_name                   = "abc"
vpc_cidr_block             = "10.153.16.0/22"
vpc_id                     = "vpc-0a0c625a1d6fa41db"
standalone_subnet_id       = "subnet-0736c53db02348249"
standalone_subnet_cidr_block         = "10.153.16.0/24"     # FILL_IN with actual subnet CIDR
standalone_subnet_availability_zone  = "us-east-1a"         # FILL_IN with actual AZ if different
backup_subnet_id           = "subnet-0ff9c4d7dead28a07"
backup_subnet_cidr_block               = "10.153.17.0/24"   # FILL_IN with actual subnet CIDR
backup_subnet_availability_zone        = "us-east-1b"       # FILL_IN with actual AZ if different
route_table           = "rtb-0e1c5df450f4b591c"
igw_id                     = "igw-0b1d9671fd8c12491"
vpc_region                 = "us-east-1"
local_zone                 = "staging.home.arpa"

# Admin 
admin_ami                    = "ami-0dd239e274077553a"
admin_instance_type          = "c5.xlarge"
admin_cpu_credits            = "unlimited"
admin_ebs_optimized          = true
admin_disksize               = 128
admin_disktype               = "gp3"
admin_data_volume_size       = 256
admin_data_volume_iops       = 3000
admin_data_volume_throughput = 125
admin_data_volume_blkdev     = "/dev/sdf"

# Agent node
agent_ami            = "ami-0db3480be03d8d01c"
agent_count          = 0 # You can leave this value as is for the first Terraform run and build Windows instances later
agent_instance_type  = "c5.xlarge"
agent_cpu_credits    = "unlimited"
agent_disksize       = 128
agent_disktype       = "gp3"
agent_diskiops       = 3000
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
dlm_interval          = 24
dlm_retain_copies     = 6
dlm_snapshot_time     = "06:00"
dlm_extra_target_tags = {}
dlm_tags_to_add       = { Application = "Silicon Designer" }

# Admin UI FQDN (not used directly by Terraform)
admin_fqdn = "admin.dev-vpc.home.arpa"

# RDS configuration
rds_allocated_storage       = 20
rds_maximum_storage         = 100
rds_engine_version          = "10.11"
rds_instance_class          = "db.t3.medium"
rds_username                = "rdsdba"
rds_password                = "Big$ecreT"
rds_storage_type            = "gp3"
rds_storage_encrypted       = true
rds_backup_retention_period = 5
rds_backup_window           = "03:04-03:34"
rds_copy_tags_to_snapshot   = true
rds_deletion_protection     = true
rds_maintenance_window      = "mon:07:56-mon:08:26"

