resource "aws_iam_role" "karpenter_node_instance_role" {
  name = "eks-demo-karpenter-node-instance-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Attach required policies to the node role
resource "aws_iam_role_policy_attachment" "karpenter_node_instance_role_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  policy_arn = each.value
  role       = aws_iam_role.karpenter_node_instance_role.name
}

# Create instance profile
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "eks-demo-karpenter-node-instance-profile"
  role = aws_iam_role.karpenter_node_instance_role.name
}
resource "aws_sqs_queue" "karpenter_queue" {
  name                    = "eks-demo-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue_policy" "karpenter_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_queue.url

  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = ["events.amazonaws.com", "sqs.amazonaws.com"]
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.karpenter_queue.arn
    }]
    Version = "2012-10-17"
  })
}
resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  name        = "eks-demo-karpenter-spot-interruption"
  description = "Karpenter spot instance interruption warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption.name
  target_id = "KarpenterSpotInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_queue.arn
}

resource "aws_cloudwatch_event_rule" "karpenter_instance_state_change" {
  name        = "eks-demo-karpenter-instance-state-change"
  description = "Karpenter instance state change"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_instance_state_change" {
  rule      = aws_cloudwatch_event_rule.karpenter_instance_state_change.name
  target_id = "KarpenterInstanceStateChangeQueueTarget"
  arn       = aws_sqs_queue.karpenter_queue.arn
}