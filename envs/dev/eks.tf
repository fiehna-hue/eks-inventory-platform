locals {
  cluster_name = "inventory-eks"
}

# ---------- Cluster ----------

resource "aws_iam_role" "cluster" {
  name = "platform-eksrole-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = "1.36"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = module.network.public_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  # Access entries instead of the legacy aws-auth ConfigMap.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = []

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# ---------- Worker nodes ----------

resource "aws_iam_role" "node" {
  name = "platform-eksrole-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.network.public_subnet_ids

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2023_x86_64_STANDARD"
  disk_size      = 20

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

# ---------- Outputs ----------

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_version" {
  value = aws_eks_cluster.this.version
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

# ---------- Cluster access for my CLI user ----------

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = "arn:aws:iam::247906201098:user/tf-user01"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
