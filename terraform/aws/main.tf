# NETWORK

resource "aws_vpc" "${CLUSTER_NAME}_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${CLUSTER_NAME}-vpc",
    Owner = "${RESOURCE_OWNER}"
  }
}

resource "aws_internet_gateway" "${CLUSTER_NAME}_igw" {
  vpc_id = aws_vpc.${CLUSTER_NAME}_vpc.id

  tags = {
    Name = "${CLUSTER_NAME}-internet-gateway",
    Owner = "${RESOURCE_OWNER}"
  }
}

resource "aws_subnet" "${CLUSTER_NAME}_subnet" {
  vpc_id                  = aws_vpc.${CLUSTER_NAME}_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${REGION}a" 
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${CLUSTER_NAME}-subnet",
    Owner = "${RESOURCE_OWNER}"
  }
}

resource "aws_route_table" "${CLUSTER_NAME}_route_table" {
  vpc_id = aws_vpc.${CLUSTER_NAME}_vpc.id

  tags = {
    Name = "${CLUSTER_NAME}-route-table",
    Owner = "${RESOURCE_OWNER}"
  }
}

resource "aws_route" "${CLUSTER_NAME}_route" {
  route_table_id         = aws_route_table.${CLUSTER_NAME}_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.${CLUSTER_NAME}_igw.id

}

resource "aws_route_table_association" "${CLUSTER_NAME}_rta_subnet_public" {
  subnet_id      = aws_subnet.${CLUSTER_NAME}_subnet.id
  route_table_id = aws_route_table.${CLUSTER_NAME}_route_table.id

}


resource "aws_security_group" "${CLUSTER_NAME}_internal_security_group" {
  name_prefix = "${CLUSTER_NAME}-"
  
  vpc_id = aws_vpc.${CLUSTER_NAME}_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0 
    protocol    = "-1"   
    cidr_blocks = ["10.0.1.0/24"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${CLUSTER_NAME}-sg",
    Owner = "${RESOURCE_OWNER}"
  }
  
}

resource "aws_security_group" "${CLUSTER_NAME}_external_security_group" {
  name_prefix = "${CLUSTER_NAME}-"
  
  vpc_id = aws_vpc.${CLUSTER_NAME}_vpc.id

   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # For CM
  ingress {
    from_port   = 7180
    to_port     = 7180
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # For Control Plane & ECS services
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # For CM
  ingress {
    from_port   = 7183
    to_port     = 7183
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # For Ranger
  ingress {
    from_port   = 6182
    to_port     = 6182
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # For Knox
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # For Datagen
  ingress {
    from_port   = 4242
    to_port     = 4242
    protocol    = "tcp"   
    cidr_blocks = [${WHITELIST_IP}] 
  }

  # Add a list of ports instead of all of them

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${CLUSTER_NAME}-sg",
    Owner = "${RESOURCE_OWNER}"
  }
  
}


# INSTANCES

resource "aws_instance" "${CLUSTER_NAME}-master" {
  count         = ${MASTER_COUNT}
  ami           = "${AMI_ID}"
  instance_type = "${MASTER_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${MASTER_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "master-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}

resource "aws_instance" "${CLUSTER_NAME}-worker" {
  count         = ${WORKER_COUNT}
  ami           = "${AMI_ID}"
  instance_type = "${WORKER_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${WORKER_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "worker-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}

resource "aws_instance" "${CLUSTER_NAME}-worker-stream" {
  count         = ${WORKER_STREAM_COUNT}
  ami           = "${AMI_ID}"
  instance_type = "${WORKER_STREAM_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${WORKER_STREAM_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "worker-stream-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}

resource "aws_instance" "${CLUSTER_NAME}-ipa" {
  count         = var.create_ipa ? 1 : 0
  ami           = "${AMI_ID}"
  instance_type = "${IPA_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${IPA_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "ipa-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}

resource "aws_instance" "${CLUSTER_NAME}-kts" {
  count         = var.create_kts ? 1 : 0
  ami           = "${AMI_ID}"
  instance_type = "${KTS_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${KTS_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "kts-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}

resource "aws_instance" "${CLUSTER_NAME}-ecs-master" {
  count         = ${ECS_MASTER_COUNT}
  ami           = "${AMI_ID}"
  instance_type = "${ECS_MASTER_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${ECS_MASTER_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "ecs-master-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}

resource "aws_instance" "${CLUSTER_NAME}-ecs-worker" {
  count         = ${ECS_WORKER_COUNT}
  ami           = "${AMI_ID}"
  instance_type = "${ECS_WORKER_TYPE}"
  key_name      = "${KEY_PAIR_NAME}"
  subnet_id     = aws_subnet.${CLUSTER_NAME}_subnet.id
  vpc_security_group_ids = [aws_security_group.${CLUSTER_NAME}_internal_security_group.id, aws_security_group.${CLUSTER_NAME}_external_security_group.id]
  associate_public_ip_address = "true"

  root_block_device {
    volume_size = ${ECS_WORKER_DISK_SIZE} 
    volume_type = "gp3"
    encrypted   = false
  }
  
  tags = {
    Name = "ecs-worker-${format("%02d", count.index + 1)}.${DOMAIN_NAME}",
    Owner = "${RESOURCE_OWNER}"
  }

}
