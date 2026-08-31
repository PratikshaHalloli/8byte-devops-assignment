resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound PostgreSQL traffic from EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL access from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "8byte-rds-sg"
  }
}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "eightbyte-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "eightbyte-rds-subnet-group"
  }
}





resource "aws_db_instance" "postgres" {
  identifier             = "eight-byte-postgres-db"
  allocated_storage      = 20
  max_allocated_storage  = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  db_name                = "devopsdb"
  username               = "dbadmin"
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1           
  backup_window           = "03:00-04:00" 
  maintenance_window      = "Mon:04:30-Mon:05:30"
  skip_final_snapshot     = true

  tags = {
    Name        = "8byte-postgres-db"
    Environment = "staging"
  }
}
