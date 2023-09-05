# Create IAM policy document for assuming role
data "aws_iam_policy_document" "eks_assume_role_policy_mnka" {
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

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
    }
  }
}
# Create IAM role for EKS autoscaler
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  role       = aws_iam_role.eks_cluster_autoscaler_role_mnka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly_policy_attachment" {
  role       = aws_iam_role.eks_cluster_autoscaler_role_mnka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "eks_cluster_autoscaler_role_mnka" {
  name = "eks_cluster_autoscaler_role_mnka"
  
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy_mnka.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_autoscaler_role_mnka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read_only_policy_attachment" {
  role       = aws_iam_role.eks_cluster_autoscaler_role_mnka.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Use the data source to get the cluster ARN and OIDC issuer
output "eks_cluster_arn" {
  value = aws_eks_cluster.my_eks_cluster_mnka.arn
}

output "eks_cluster_oidc_issuer" {
  value = aws_eks_cluster.my_eks_cluster_mnka.identity[0].oidc[0].issuer
}


# Create the EKS cluster
resource "aws_eks_cluster" "my_eks_cluster_mnka" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_autoscaler_role_mnka.arn

  vpc_config {
    subnet_ids = var.public_subnet_ids
  }

  tags = {
    Terraform = "true"
  }
}

# Create EKS node group
resource "aws_eks_node_group" "eks_nodegroup_mnka" {
  cluster_name    = aws_eks_cluster.my_eks_cluster_mnka.name
  node_group_name = "eksng"
  
  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  subnet_ids = var.private_subnet_ids

  instance_types  = ["t2.medium"]
  capacity_type  = "ON_DEMAND"
  node_role_arn  = aws_iam_role.eks_cluster_autoscaler_role_mnka.arn
  ami_type       = "AL2_x86_64"
  disk_size      = 20
  tags = {
    Terraform = "true"    
    "Name" = "eksng"
  }

  depends_on = [aws_eks_cluster.my_eks_cluster_mnka]
}
