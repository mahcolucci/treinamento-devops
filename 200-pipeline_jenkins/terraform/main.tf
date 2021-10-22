  region = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com" # outra opção "https://ifconfig.me"
}

resource "aws_instance" "pipeline-jenkins-colucci" {
  ami                         = "ami-09e67e426f25ce0d7"
  instance_type               = "t2.medium"
  key_name                    = "kp-colucci"
  subnet_id                   = "subnet-0dbc6439c94e66d76"
  associate_public_ip_address = true
  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:534566538491:key/90847cc8-47e8-4a75-8a69-2dae39f0cc0d"
    volume_size = 20
  }
  tags = {
    Name = "pipeline-jenkins-colucci"
  }
  vpc_security_group_ids = ["${aws_security_group.pipeline-jenkins.id}"]
}

resource "aws_security_group" "pipeline-jenkins" {
  name        = "acessos_pipeline_jenkins"
  description = "acessos_pipeline_jenkins inbound traffic"
  vpc_id      = "vpc-000ac43d9700f2e6c"

  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups : null,
      self : null
    },
    {
      description      = "SSH from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups : null,
      self : null
    },
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups : null,
      self : null,
      description : "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "pipeline-jenkins-colucci"
  }
}

# terraform refresh para mostrar o ssh
output "jenkins" {
  value = [
    "jenkins",
    "id: ${aws_instance.pipeline-jenkins-colucci.id}",
    "private: ${aws_instance.pipeline-jenkins-colucci.private_ip}",
    "public: ${aws_instance.pipeline-jenkins-colucci.public_ip}",
    "public_dns: ${aws_instance.pipeline-jenkins-colucci.public_dns}",
    "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.pipeline-jenkins-colucci.public_dns}"
  ]
}
