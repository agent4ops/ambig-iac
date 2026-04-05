terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
    cidr_block = "192.168.0.0/22"
}

data "aws_availability_zones" "azs" {
    state = "available"
}

resource "aws_subnet" "subnet_az1" {
    availability_zone = data.aws_availability_zones.azs.names[0]
    cidr_block = "192.168.0.0/24"
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az2" {
    availability_zone = data.aws_availability_zones.azs.names[1]
    cidr_block = "192.168.1.0/24"
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az3" {
    availability_zone = data.aws_availability_zones.azs.names[2]
    cidr_block = "192.168.2.0/24"
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "first" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "second" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "third" {
  subnet_id      = aws_subnet.subnet_az3.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "egress1" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_cloudwatch_log_group" "test" {
    name = "msk_broker_logs"
}

resource "aws_msk_cluster" "example" {
    cluster_name = "example"
    kafka_version = "3.2.0"
    number_of_broker_nodes = 3

    broker_node_group_info {
        instance_type = "kafka.t3.small"
        client_subnets = [
            aws_subnet.subnet_az1.id,
            aws_subnet.subnet_az2.id,
            aws_subnet.subnet_az3.id,
        ]

        storage_info {
            ebs_storage_info {
                volume_size = 1000
            }
        }

        security_groups = [aws_security_group.sg.id]
    }

    open_monitoring {
        prometheus {
            jmx_exporter {
                enabled_in_broker = true
            }
            node_exporter {
                enabled_in_broker = true
            }
        }
    }

    logging_info {
        broker_logs {
            cloudwatch_logs {
                enabled = true
                log_group = aws_cloudwatch_log_group.test.name
            }
            firehose {
                enabled = false
            }
            s3 {
                enabled = false
            }
        }
    }
}

output "zookeeper_connect_string" {
    value = aws_msk_cluster.example.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
    description = "TLS connection host:port pairs"
    value = aws_msk_cluster.example.bootstrap_brokers_tls
}