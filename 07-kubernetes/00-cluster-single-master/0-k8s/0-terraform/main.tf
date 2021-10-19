provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com" # outra opção "https://ifconfig.me"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ou ["099720109477"] ID master com permissão para busca

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"] # exemplo de como listar um nome de AMI - 'aws ec2 describe-images --region us-east-1 --image-ids ami-09e67e426f25ce0d7' https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  }
}

resource "aws_instance" "maquina_master" {
  ami           = "ami-09e67e426f25ce0d7" #"${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name      = "kp-colucci"
  tags = {
    Name = "maquina-cluster-kubernetes-master-colucci"
  }
  subnet_id                   = "subnet-0dbc6439c94e66d76"
  associate_public_ip_address = true


  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:534566538491:key/90847cc8-47e8-4a75-8a69-2dae39f0cc0d"
    volume_size = 20
  }

  vpc_security_group_ids = ["${aws_security_group.acessos_master.id}"]
  depends_on = [
    aws_instance.workers,
  ]
}

resource "aws_instance" "workers" {
  ami           = "ami-09e67e426f25ce0d7" #"${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name      = "kp-colucci"
  tags = {
    Name = "maquina-cluster-kubernetes-colucci-${count.index}"
  }
  subnet_id                   = "subnet-0dbc6439c94e66d76"
  associate_public_ip_address = true

  root_block_device {
    encrypted = true
    #kms_key_id  = "arn:aws:kms:us-east-1:534566538491:key/90847cc8-47e8-4a75-8a69-2dae39f0cc0d"
    volume_size = 20
  }

  vpc_security_group_ids = ["${aws_security_group.acessos_workers.id}"]
  count                  = 2
}


resource "aws_security_group" "acessos_master" {
  name        = "acessos_master"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-000ac43d9700f2e6c"

  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"] #["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups : null,
      self : null
    },
    {
      description = "Libera porta kubernetes"
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = [
        "${chomp(data.http.myip.body)}/32",
        "${aws_instance.workers[0].private_ip}/32",
        "${aws_instance.workers[1].private_ip}/32",
      ]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null,
      security_groups : null,
      self : null
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups = [
        "sg-05baab447d1b51879",
      ]
      self    = false
      to_port = 65535
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
    Name = "acessos_master"
  }
}


resource "aws_security_group" "acessos_workers" {
  name        = "acessos_workers"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-000ac43d9700f2e6c"

  ingress = [
    # {
    #  description      = "SSH from VPC"
    #  from_port        = 22
    #  to_port          = 22
    #  protocol         = "tcp"
    #  cidr_blocks      = ["0.0.0.0/0"] #["${chomp(data.http.myip.body)}/32"]
    #  ipv6_cidr_blocks = ["::/0"]
    #  prefix_list_ids  = null,
    #  security_groups : null,
    #  self : null
    # },
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = "SSH from VPC"
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks      = []
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups = [
        "sg-079f27458cdec1b2b",
      ]
      self    = false
      to_port = 65535
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
    Name = "acessos_workers"
  }
}


# terraform refresh para mostrar o ssh
output "maquina_master" {
  value = [
    "master - ${aws_instance.maquina_master.public_ip} - ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.maquina_master.public_dns}"
  ]
}

# terraform refresh para mostrar o ssh
output "aws_instance_e_ssh" {
  value = [
    for key, item in aws_instance.workers :
    "worker ${key + 1} - ${item.public_ip} - ssh -i ~/.ssh/id_rsa ubuntu@${item.public_dns}"
  ]
}
