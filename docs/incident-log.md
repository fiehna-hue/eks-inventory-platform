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
