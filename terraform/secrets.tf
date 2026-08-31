resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "8byte-db-credentials-${var.environment}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = local.final_db_password
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = 5432
  })
}
