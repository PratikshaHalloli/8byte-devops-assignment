resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  final_db_password = var.db_password != "" ? var.db_password : random_password.db_password.result
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group-${var.environment}"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "postgres" {
  identifier             = "eight-byte-postgres-${var.environment}"
  allocated_storage      = 20
  max_allocated_storage  = 20         
  storage_type           = "gp2"       
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" 
  db_name                = "appdb"
  username               = "dbadmin"
  password               = local.final_db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}
