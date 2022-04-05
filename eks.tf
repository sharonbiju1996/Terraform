# --------------------------------------------------
# Cluster policy for eks cluster
# ---------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "role-${var.clustername}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
  }


# ---------------------------------------------------
#Cluster  setup for eks
# ---------------------------------------------------
resource "aws_eks_cluster" "aws_eks" {
  name     = var.clustername
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [var.private1_cidr, var.private2_cidr]
    endpoint_private_access = true
    endpoint_public_access = false

  }

  tags = {
    Name = var.clustername
  }


  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy
  ]
}



# ---------------------------------------------------
#node policy setup for eks
# ---------------------------------------------------
resource "aws_iam_role" "eks_nodes" {
  name = "node-role-${var.clustername}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
 
policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}


# ---------------------------------------------------
#node setup for eks
# ---------------------------------------------------

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "default-${var.clustername}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [var.private1_cidr, var.private2_cidr]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  remote_access {
    ec2_ssh_key = aws_key_pair.deployer.id
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ---------------------------------------------------
#security key 
# ---------------------------------------------------
resource "aws_key_pair" "deployer" {
  key_name   = "key-${var.clustername}"
  public_key = var.public_key
}


