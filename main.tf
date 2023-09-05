resource "aws_vpc" "custom_vpc_mnka" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1_mnka" {
  vpc_id           = aws_vpc.custom_vpc_mnka.id
  cidr_block       = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "public_subnet_2_mnka" {
  vpc_id           = aws_vpc.custom_vpc_mnka.id
  cidr_block       = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_subnet" "private_subnet_1_mnka" {
  vpc_id           = aws_vpc.custom_vpc_mnka.id
  cidr_block       = "10.0.3.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "private_subnet_2_mnka" {
  vpc_id           = aws_vpc.custom_vpc_mnka.id
  cidr_block       = "10.0.4.0/24"
  availability_zone = "us-west-2b"
}

module "eks_setup" {
  source = "./modules/eks_setup"
  
  cluster_name      = "ekscluster_mnka"
  oidc_provider_arn = "arn:aws:iam::account-id:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EKS_OIDC_PROVIDER_ID"
  oidc_issuer       = "https://oidc.eks.us-east-1.amazonaws.com/id/EKS_OIDC_PROVIDER_ID"

  public_subnet_ids = [
    aws_subnet.public_subnet_1_mnka.id,
    aws_subnet.public_subnet_2_mnka.id,
  ]

  private_subnet_ids = [
    aws_subnet.private_subnet_1_mnka.id,
    aws_subnet.private_subnet_2_mnka.id,
  ]
}

output "eks_cluster_arn" {
  value = module.eks_setup.eks_cluster_arn
}

output "eks_cluster_oidc_issuer" {
  value = module.eks_setup.eks_cluster_oidc_issuer
}
