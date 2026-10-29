# eks-inventory-platform

An inventory API running on Amazon EKS, built with Terraform and shipped through keyless GitHub Actions pipelines.

## Status

| Phase | What | Status |
|---|---|---|
| 0 | Repository, state backend, keyless plan and apply pipelines, protected main | Done |
| 1 | EKS cluster and node group through the pipeline | Next |
| 2 | Deploy the app to the cluster from a workflow | Planned |
| 3 | Public access through a load balancer | Planned |
| 4 | Docs, incident log, teardown | Planned |

## How a change ships

- Pull requests run `terraform plan` with a read-only role and post the plan as a comment.
- A branch ruleset requires that check, and direct pushes to `main` are rejected.
- Merging to `main` runs `terraform apply` with a separate write role.
- GitHub Actions authenticates to AWS with OIDC, so no access keys are stored.

## Related

- [aws-platform-as-code](https://github.com/fiehna-hue/aws-platform-as-code): the platform whose pipeline pattern and network module this project reuses.
- [k8s-inventory-kind](https://github.com/fiehna-hue/k8s-inventory-kind): the same app on a local Kubernetes cluster.

## Phase 2: inventory app deployed on EKS

The Flask and Postgres inventory API from [inventory-app](https://github.com/fiehna-hue/inventory-app) was deployed onto this cluster using the manifests in `k8s/`: a 2-replica API Deployment (rolling update with `maxUnavailable: 0`, readiness and liveness probes, non-root user) pulling its image from ECR, and a Postgres Deployment. The database password was created with `kubectl create secret` and is never committed. Verified with `kubectl port-forward`: `/health` returned ok, an item was created and read back. Output is saved in `docs/deploy-evidence.txt`.

Design choices:
- Postgres uses `emptyDir`, so data is lost if the pod restarts. EKS has no storage driver by default and this avoided RDS cost; a real deployment would use the EBS CSI driver or RDS.
- No load balancer was created: a Kubernetes-created load balancer is not in Terraform state and can block the VPC destroy if left behind.

The cluster was destroyed through the same pipeline in the same session. See `docs/incident-log.md` for what went wrong.
