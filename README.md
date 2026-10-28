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
