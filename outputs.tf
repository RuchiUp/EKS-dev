output "karpenter_irsa_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}

output "aws_lb_controller_irsa_role_arn" {
  value = aws_iam_role.aws_lb_controller.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}