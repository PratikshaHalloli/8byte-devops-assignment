resource "aws_secretsmanager_secret" "db_secret" {
  name        = "8byte-rds-credentials-v2"
  description = "RDS PostgreSQL database credentials"

  tags = {
    Environment = "staging"
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = var.db_password
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = "devopsdb"
  })
}
