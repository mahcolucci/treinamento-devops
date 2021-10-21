provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com" # outra opção "https://ifconfig.me"
}

resource "aws_instance" "k8s_proxy_colucci" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  key_name      = "kp-colucci"
  subnet_id                   = "subnet-0dbc6439c94e66d76"
  associate_public_ip_address = true
  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:534566538491:key/90847cc8-47e8-4a75-8a69-2dae39f0cc0d"
    volume_size = 20
  }
  tags = {
    Name = "k8s-haproxy-colucci"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos.id}"]
}

resource "aws_instance" "k8s_masters_colucci" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.large"
  key_name      = "kp-colucci"
  count         = 3
  subnet_id                   = "subnet-0dbc6439c94e66d76"
  associate_public_ip_address = true
  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:534566538491:key/90847cc8-47e8-4a75-8a69-2dae39f0cc0d"
    volume_size = 20
  }
  tags = {
    Name = "k8s-master-colucci-${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_master.id}"]
  depends_on = [
    aws_instance.k8s_workers_colucci,
  ]
}

resource "aws_instance" "k8s_workers_colucci" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.medium"
  key_name      = "kp-colucci"
  count         = 3
  subnet_id                   = "subnet-0dbc6439c94e66d76"
  associate_public_ip_address = true
  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:534566538491:key/90847cc8-47e8-4a75-8a69-2dae39f0cc0d"
    volume_size = 20
  }
  tags = {
    Name = "k8s_workers-colucci-${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos.id}"]
}


resource "aws_security_group" "acessos_master" {
  name        = "k8s-acessos_master"
  description = "acessos inbound traffic"
  vpc_id = "vpc-000ac43d9700f2e6c"

  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids = null,
      security_groups: null,
      self: null
    },
    {
      cidr_blocks      = [
        "${var.ip_haproxy}/32",
      ]
      description      = "Libera haproxy"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
    {
      cidr_blocks      = []
      description      = "Libera acesso k8s_masters"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = true
      to_port          = 0
    },
    {
      cidr_blocks      = []
      description      = "Libera acesso k8s_workers"
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
   #  security_groups  = [
   #    "sg-056665ffa54f46217",
   #  ]
      security_groups  = null,
      self             = false
      to_port          = 0
    },
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = [],
      prefix_list_ids = null,
      security_groups: null,
      self: null,
      description: "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "k8s-allow_ssh_colucci"
  }
}


resource "aws_security_group" "acessos" {
  name        = "k8s-acessos"
  description = "acessos inbound traffic"
  vpc_id = "vpc-000ac43d9700f2e6c"

  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = []
      prefix_list_ids = null,
      security_groups: null,
      self: null
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = [
        "${aws_security_group.acessos_master.id}",
      ]
      self             = false
      to_port          = 0
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
   #  security_groups  = [
   #    "sg-05152ffdef1105622", # acesso para o proprio grupo pois os workers precisam acessar o haproxy
   #  ]
      security_groups  = null,
      self             = true
      to_port          = 0
    },
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = [],
      prefix_list_ids = null,
      security_groups: null,
      self: null,
      description: "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "k8s-allow_ssh_colucci"
  }
}


output "k8s_masters_colucci" {
  value = [
    for key, item in aws_instance.k8s_masters_colucci :
      "k8s-master ${key+1} - ${item.private_ip} - ssh -i ~/.ssh/id_rsa ubuntu@${item.public_dns}"
  ]
}


output "k8s_workers_colucci" {
  value = [
    for key, item in aws_instance.k8s_workers_colucci :
      "k8s-workers ${key+1} - ${item.private_ip} - ssh -i ~/.ssh/id_rsa ubuntu@${item.public_dns}"
  ]
}

output "k8s_proxy_colucci" {
  value = [
    "k8s_proxy - ${aws_instance.k8s_proxy_colucci.private_ip} - ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.k8s_proxy_colucci.public_dns}"
  ]
}


output "security-group-workers-e-haproxy" {
  value = aws_security_group.acessos.id
}
	

output "security-group-master" {
  value = aws_security_group.acessos_master.id
}



# terraform refresh para mostrar o ssh
