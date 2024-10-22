provider "aws" {
  region = "eu-central-1"
  access_key = "************"
  secret_key = "************************"
  alias = "eu"
}

resource "aws_rds_cluster" "rds_cluster_test" {
    availability_zones = ["eu-central-1a", "eu-central-1b"]
    backup_retention_period = "7"
    cluster_identifier = "npr-test-cluster"
    copy_tags_to_snapshot = true
    database_name = "testdb"
    db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds_cluster_test_pg.name
    db_subnet_group_name = aws_db_subnet_group.default_sn.name
    deletion_protection = true
    enabled_cloudwatch_logs_exports = []
    engine = "aurora-postgresql"
    engine_mode = "provisioned"
    engine_version = "14.3"
    final_snapshot_identifier = "npr-test-cluster-snapshot"
    iam_database_authentication_enabled = false
    iam_roles = []
    kms_key_id = "arn:aws:kms:eu-central-1:**********:key/**********************"
    master_password = "***************"
    master_username = "testadmin"
    preferred_backup_window = "23:00-00:00"
    preferred_maintenance_window = "sun:01:00-sun:02:00"
    provider = aws.eu
    skip_final_snapshot = true
    storage_encrypted = true
    vpc_security_group_ids = [aws_security_group.rds_security_group_psql.id]
    tags = {
        Owner = "test"
        Environment = "dev"
        support = "testdb"
    }
}

resource "aws_rds_cluster_instance" "rds_cluster_instance_test" {
    cluster_identifier = aws_rds_cluster.rds_cluster_test.id
    instance_class = "db.t3.medium"
    count = 1
    identifier = "npr-test-cluster-inst-0"
    engine = aws_rds_cluster.rds_cluster_test.engine
    engine_version = aws_rds_cluster.rds_cluster_test.engine_version
    auto_minor_version_upgrade = true
    copy_tags_to_snapshot = true
    db_parameter_group_name = "default.aurora-postgresql14"
    db_subnet_group_name = aws_db_subnet_group.default_sn.name
    monitoring_interval = "0"
    monitoring_role_arn = ""
    performance_insights_enabled = false
    preferred_maintenance_window = "sat:08:00-sat:09:00"
    provider = aws.eu
    publicly_accessible = false
    #babelfish = true #Future support only
    tags = {
        Owner = "test"
        Environment = "dev"
        support = "testdb"
    }
}

resource "aws_security_group" "rds_security_group_psql" {
    name = "npr-test-cluster-sg"
    description = "Allow database connection for Postgres SQL"
    vpc_id = "vpc-*******"
    provider = aws.eu

    ingress {
        from_port = 5432
        description = "ingress-postgres"
        protocol = "tcp"
        to_port = 5432
        cidr_blocks = ["10.0.0.0/8"]
    }

    ingress {
        from_port = 1433
        description = "ingress-mssql"
        protocol = "tcp"
        to_port = 1433
        cidr_blocks = ["10.0.0.0/8"]
    }

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["10.0.0.0/8"]
    }

    tags = {
        Owner = "test"
        Environment = "dev"
        support = "testdb"
    }
}

resource "aws_rds_cluster_parameter_group" "rds_cluster_test_pg" {
    name = "npr-test-cluster-pg"
    family = "aurora-postgresql14"
    provider = aws.eu

    #Enable babelfish to be active
    parameter {
        name = "rds.babelfish_status"
        value = "on"
        apply_method = "pending-reboot"
    }

}

resource "aws_db_subnet_group" "default_sn" {
    name = "npr-test-db-subnet"
    subnet_ids = ["subnet-******", "subnet-******"]
    provider = aws.eu
    tags = {
        Name = "RDS Default Subnet group"
    }
}

resource "aws_cloudwatch_log_group" "rds_cluster_test_lg" {
    provider = aws.eu
    name = "/aws/rds/cluster/${aws_rds_cluster.rds_cluster_test.cluster_identifier}/postgresql"
    retention_in_days = 14
}
