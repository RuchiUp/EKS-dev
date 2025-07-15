
resource "helm_release" "coredns" {
  name       = "coredns"
  repository = "https://coredns.github.io/helm"
  chart      = "coredns"
  namespace  = "kube-system"
  version    = "1.29.0"

  # Replace existing CoreDNS
  replace = true
  force_update = true

  values = [
    yamlencode({
      fullnameOverride = "coredns"
      nameOverride = "coredns"
      
      replicaCount = 2
      
      image = {
        repository = "registry.k8s.io/coredns/coredns"
        tag = "v1.11.1"
        pullPolicy = "IfNotPresent"
      }
      
      serviceAccount = {
        create = true
        name = "coredns"
      }
      
      rbac = {
        create = true
        pspEnable = false
      }
      
      service = {
        name = "kube-dns"
        type = "ClusterIP"
        clusterIP = "172.20.0.10" #important
        port = 53
        targetPort = 53
      }
      
      resources = {
        limits = {
          cpu = "100m"
          memory = "128Mi"
        }
        requests = {
          cpu = "100m"
          memory = "128Mi"
        }
      }
      
      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }
      
      tolerations = [
        {
          key = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          effect = "NoSchedule"
          key = "node-role.kubernetes.io/control-plane"
        }
      ]
      
      servers = [
        {
          zones = [
            { zone = "." }
          ]
          port = 53
          plugins = [
            { name = "errors" },
            {
              name = "health"
              configBlock = "lameduck 5s"
            },
            { name = "ready" },
            {
              name = "kubernetes"
              parameters = "cluster.local in-addr.arpa ip6.arpa"
              configBlock = "pods insecure\nfallthrough in-addr.arpa ip6.arpa\nttl 30"
            },
            {
              name = "prometheus"
              parameters = "0.0.0.0:9153"
            },
            {
              name = "forward"
              parameters = ". /etc/resolv.conf"
              configBlock = "max_concurrent 1000"
            },
            {
              name = "cache"
              parameters = "30"
            },
            { name = "loop" },
            { name = "reload" },
            { name = "loadbalance" }
          ]
        }
      ]
    })
  ]

  depends_on = [helm_release.argocd]
}