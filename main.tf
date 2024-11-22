# Configuração do Terraform: Especifica os requisitos do provedor AWS
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"  # Fonte do provedor AWS (oficial da HashiCorp)
      version = "5.75.1"        # Versão específica do provedor AWS
    }
  }
}

# Configuração do provedor AWS
provider "aws" {  
  region = "us-east-1"  # Define a região da AWS onde os recursos serão criados
}

# Bloco de dados para buscar a AMI do Ubuntu mais recente
data "aws_ami" "ubuntu" {  
  most_recent = true  # Garante que será utilizada a AMI mais recente disponível

  # Filtro para escolher a imagem do Ubuntu com base no nome da imagem
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Filtro para garantir que a imagem use o tipo de virtualização "hvm"
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # ID do proprietário da imagem (Canonical - responsável pelas imagens oficiais do Ubuntu)
  owners = ["099720109477"]
}

# Recurso para criar uma instância EC2 na AWS
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id  # ID da AMI recuperada pelo bloco 'data'
  instance_type = "t3.micro"              # Tipo da instância (t3.micro é uma instância de baixo custo)

  # Tags para identificar a instância na AWS
  tags = {
    Name = "HelloWorld"  # A instância será nomeada como "HelloWorld"
  }
}

# Bloco de saída para exibir o IP privado da instância criada
output "ip_privado" {
  value = aws_instance.web.private_ip  # Exibe o IP privado da instância criada
}

# Definindo um módulo VPC que utiliza o módulo "terraform-aws-modules/vpc/aws" para criar a infraestrutura da VPC na AWS
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"  # Especifica o módulo VPC da AWS no repositório Terraform

  # Configurações básicas da VPC
  name = "my-vpc"           # Nome da VPC que será criada
  cidr = "10.0.0.0/16"      # Bloco CIDR para o range de IPs da VPC

  # Zonas de disponibilidade (Availability Zones) onde os sub-redes serão distribuídos
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]  # Define três zonas de disponibilidade na região us-east-1
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  # Blocos CIDR para as sub-redes privadas em cada zona de disponibilidade
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]  # Blocos CIDR para as sub-redes públicas em cada zona de disponibilidade

  # Configurações adicionais
  enable_nat_gateway = true  # Habilita o NAT Gateway para permitir que as instâncias nas sub-redes privadas acessem a internet
  enable_vpn_gateway = true  # Habilita o VPN Gateway para conexão com redes remotas

  # Tags para identificação de recursos na AWS
  tags = {
    Terraform   = "true"  # Indica que os recursos foram criados com Terraform
    Environment = "dev"   # Tag de ambiente para indicar que é um ambiente de desenvolvimento
  }
}
