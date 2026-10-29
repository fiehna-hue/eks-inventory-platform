# Incident log

## 1. EKS cluster left running after merge (cost risk)

**What happened:** Merging the EKS pull request ran the apply pipeline, which created the cluster and two t3.medium nodes. I did not tear it down the same session, so it kept running for about 22 hours (control plane about $0.10/hour plus two nodes).

**How it was found:** An account sweep (running EC2 instances, volumes, VPCs) showed `inventory-eks` nodes still running.

**Fix:** Opened a teardown PR that removed `eks.tf` and `network.tf`. The plan read `0 to add, 0 to change, 29 to destroy`. After merge, the apply pipeline destroyed everything in about 11 minutes. A final sweep confirmed no instances, NAT gateways, Elastic IPs, load balancers, RDS or ECS clusters remained, and the dedicated VPC was gone.

**Lessons:**
- Merging a PR that creates billable infrastructure starts the billing immediately, so plan the teardown before the merge.
- Always run a sweep after any billable stack: instances, volumes, VPCs, NAT, EIPs, load balancers, RDS, ECS, and the EKS console (the CLI user cannot list clusters).
- Do not terminate managed node group instances by hand; the node group relaunches them. Destroy through Terraform.
- Keep the budget alert as the safety net.

## 2. Planned stop time missed because a permission was not checked first

**What happened:** I planned a short session to deploy the app on EKS and agreed a destroy time. The cluster was ready on time, but I could not connect: `aws eks update-kubeconfig` failed with `AccessDeniedException` because the CLI user had no `eks:DescribeCluster` permission. The fix needed an admin console login, since the CLI user is deliberately denied from editing its own IAM policies. The stop time slipped by about 45 minutes while the cluster kept running.

**Fix:** Added an inline policy allowing only `eks:DescribeCluster` on the one cluster, then deployed and tore down in the same session. By the hourly rates the run cost roughly 0.45 USD (an estimate, not yet confirmed in Cost Explorer).

**Lessons:**
- Verify permissions before starting the billing clock: `aws eks describe-cluster` on a non-existent cluster returns ResourceNotFound when allowed and AccessDenied when not, so it can be tested for free.
- The explicit deny on self-editing IAM did its job: the CLI user could not grant itself access.
- Destroy before any Kubernetes-created load balancer or volume exists, or delete those first; here the app used ClusterIP services and an emptyDir volume so nothing outside Terraform state was created.
