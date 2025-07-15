

#This guide will help you provision an EKS cluster with Terraform and deploy CoreDNS, Karpenter, and AWS Load Balancer Controller via Helm and ArgoCD!

---

## Prerequisites

Before you begin, make sure the following tools and configurations are in place:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate permissions
* [Terraform v1.3+](https://developer.hashicorp.com/terraform/downloads)
* [Helm](https://helm.sh/docs/intro/install/) and `kubectl` installed locally
* AWS credentials stored as GitHub secrets (for GitHub Actions)
* **IAM Policy JSON Files** in your Terraform module directory:
  * `karpenter-controller-policy.json`
  * `aws-lb-controller-policy.json`
* **GitHub Personal Access Token** (classic) with `repo` scope if your repository is private

---

## ⚙️ Current Terraform Configuration Summary

Update these variables in your Terraform config as per your use case:

cluster_name           = "eks-demo"
cluster_role_name      = "eksClusterRole"
endpoint_public_access = true
node_group_name = "eks-node-group"
node_role_name  = "eksNodeRole"
instance_types  = ["t3.medium"]
desired_size    = 2
max_size        = 3
min_size        = 1


karpenter_instance_profile_name     = "eks-demo-karpenter-node-instance-profile"
karpenter_queue_name                = "eks-demo-karpenter"


argocd_release_name   = "argocd"
argocd_chart_version  = "7.7.3"
argocd_namespace      = "argocd"
argocd_repository     = "https://argoproj.github.io/argo-helm"
argocd_chart_name     = "argo-cd"
argocd_service_type   = "LoadBalancer" options (NodePort, clusterIP, LoadBalancer)


coredns_release_name   = "coredns"
coredns_chart_version  = "1.29.0"
coredns_namespace      = "kube-system"
coredns_repository     = "https://coredns.github.io/helm"
coredns_chart_name     = "coredns"
coredns_service_name   = "kube-dns"
coredns_cluster_ip     = "" # Must be within your VPC CIDR
coredns_port           = 53
coredns_image_tag      = "v1.11.1"
coredns_replica_count  = 2
coredns_cpu_limit      = "100m"
coredns_memory_limit   = "128Mi"
coredns_cpu_request    = "100m"
coredns_memory_request = "128Mi"


security_group_name        = "eks-cluster-sg"
security_group_description = "Allow all EKS traffic"
ingress_cidr_blocks        = ["0.0.0.0/0"]
egress_cidr_blocks         = ["0.0.0.0/0"]

##**SECURITY WARNING:** Current configuration allows all traffic, restrict CIDRs for production use
oidc_client_id_list     = ["sts.amazonaws.com"]
oidc_thumbprint_list    = ["9e99a48a9960b14926bb7f3b02e22da0a82a5f5c"]




##Project Setup Instructions

###Step 1: Initialize Terraform

cd <your-terraform-project-directory>
terraform init
terraform plan
terraform apply

###Step 2: Configure kubectl once cluster is up

```bash
aws eks update-kubeconfig --region <your-region> --name <your-cluster-name>
```
---
###Step 3: Verify Kubernetes & ArgoCD pods

```bash
kubectl get pods -n kube-system
```

Get Argo CD initial password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

###Step 4: Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

* Open: [http://localhost:8080](http://localhost:8080)
* Username: `admin`
* Password: (From step 3)

---

###Step 5: Connect GitHub Repo to ArgoCD

In the ArgoCD UI:

* Go to **Settings → Repositories → Connect Repo via HTTPS**
* Fill in:

  * **Repo URL:** `https://github.com/<your-username>/<your-repo>.git`
  * **Username:** Your GitHub username
  * **Password:** Your GitHub PAT with `repo` access

**Make sure your repo URL ends with `.git`**

---

###Step 6: Prepare Your GitOps Repo Locally

```bash
git clone https://github.com/RuchiUp/eks-gitOps
cd eks-gitOps
```

Update:

* `values.yaml`: Fill in actual ARNs, EKS endpoint, instance profiles
* `apps/karpenter.yaml` & `apps/aws-lb-controller.yaml`:

  * Update `repoURL` to point to your repo
  * Update `path` to your local chart path (`../../values/` typically works on Windows)

---

###Step 7: Deploy Karpenter & AWS Load Balancer Controller

```bash
kubectl apply -f apps/karpenter.yaml
kubectl apply -f apps/aws-lb-controller.yaml
```

---

###Step 8: Verify Everything

```bash
kubectl get application -n argocd
kubectl get pods -n argocd
```

In the ArgoCD UI, verify:

* `karpenter` and `aws-lb-controller` apps
* Status: **Healthy** and **Synced**

---

##Clean Up

To destroy all infrastructure:

```bash
terraform destroy
```
