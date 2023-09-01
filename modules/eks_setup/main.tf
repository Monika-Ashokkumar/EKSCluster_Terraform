# Create IAM policy document for assuming role
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.oidc_issuer]
    }
  }
}

# Create IAM role for EKS autoscaler
resource "aws_iam_role" "eks_cluster_autoscaler_role" {
  name = "eks_cluster_autoscaler_role"
  
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

# Use the cluster_name variable
data "aws_eks_cluster" "my_eks_cluster" {
  name = var.cluster_name
}

# Use the data source to get the cluster ARN and OIDC issuer
output "eks_cluster_arn" {
  value = data.aws_eks_cluster.my_eks_cluster.arn
}

output "eks_cluster_oidc_issuer" {
  value = data.aws_eks_cluster.my_eks_cluster.identity[0].oidc[0].issuer
}


# Create the EKS cluster
resource "aws_eks_cluster" "my_eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_autoscaler_role.arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
  }

  tags = {
    Terraform = "true"
  }
}

# Create EKS node group
resource "aws_eks_node_group" "eks_nodegroup" {
  cluster_name    = aws_eks_cluster.my_eks_cluster.name
  node_group_name = "eksng"
  
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  remote_access {
    ec2_ssh_key = "eks"  
  }

  subnet_ids = var.private_subnet_ids

  instance_types  = ["t2.medium"]
  capacity_type  = "ON_DEMAND"
  node_role_arn  = aws_iam_role.eks_cluster_autoscaler_role.arn
  ami_type       = "AL2_x86_64"
  disk_size      = 20
  tags = {
    Terraform = "true"    
    "Name" = "eksng"
  }

  depends_on = [aws_eks_cluster.my_eks_cluster]
}