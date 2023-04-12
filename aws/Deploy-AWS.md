## **Introduction**

This project offers a complete platform distribution that has the following characteristics:
- It follows a fully declarative, GitOps approach using [ArgoCD](https://argoproj.github.io/argo-cd/). No other middleware is injected. All manifests are defined either as vanilla Kubernetes YAML specs, Kustomize specs, or Helm charts.
- Maximum effort to deploy all dependent services within the k8s cluster. These include block storage, service mesh, cache, databases, message queues, certificate managers, secret key managers and authentication/authorization. There are obvious certain dependencies such as auto-scaling and external load balancing that are unique to each underlying cloud platform. We integrate accordingly for the intended cloud platform. See below for each native integrations.
- A very simple [init script](./setup_repo.sh) and accompanying [config file](./examples/setup.conf). We have intentionally kept this a simple "find-and-replace" script (in favour using using a stricter approach, such as encoding the entire distribution as a Helm chart) in order to make the repo easy to extend.
- For authentication and authorization, we use [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) and [Keycloak](https://www.keycloak.org/) due to their wide adoption and active user base.

#
## **AWS Integrations**

This distribution assumes that you will be making use of the following AWS services:
- An [EKS](https://aws.amazon.com/eks/) Kubernetes cluster built with `eksctl`. The [aws-eks-cluster-spec.yaml](./aws-eks-cluster-spec.yaml) file defines the EKS cluster created with `eksctl`.
- [Autoscaling Groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) for Worker Nodes in the EKS cluster. We use the [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) application to automatically scale nodes up or down depending on usage.
- A [Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) via external ingress/egress is facilitated. We use the [aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller) application in order to automatically provision NLB's in the correct subnets.
- [Route53](https://aws.amazon.com/route53/) for DNS routing. We use the [external-dns](https://github.com/kubernetes-sigs/external-dns) application to automatically create records sets in Route53 in order to route from a public DNS to the NLB endpoint, as well as a [LetsEncrypt](https://letsencrypt.org/) DNS-01 solver to certify the domain with Route53.
- [Secrets Manager](https://aws.amazon.com/secrets-manager/) for secret management working with the Kubernetes operator [External Secrets](https://external-secrets.io/). 
  - *Looking into using kubeseal to handle all secrets as a replacement to using external secret providers like AWS Secrets Manager*
- [IAM Roles for Service Accounts (IRSA)](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) to define the IAM Roles that may be assumed by specific Pods, by attaching a specific ServiceAccount to them. For example, we attach to the `external-dns` Pod a ServiceAccount that uses an IAM Role allowing certain actions in Route53. See the section below for a detailed listing of IRSA policies that are needed.

#
## **AWS IAM Roles for Service Acocunts**

Below you will find all of the IAM Policies that need to be attached to the IRSA roles. Before looking at the policies though, please take note of the fact that IRSA works via setting up a Trust relationship to a *specific* ServiceAccount in a *specific* Namespace. If you find that an IAM role is not being correctly assumed, it probably means that you are attaching it to a ServiceAccount that hasn't explicitly been authorized to do so.

## Trust Relationships

Let's take the [external-dns](https://github.com/kubernetes-sigs/external-dns) service as an example. The ServiceAccount for this application is defined [here](distribution/external-dns/serviceaccount.yaml), is named `external-dns` and is rolled out in the `kube-system` Namespace. To allow this ServiceAccount to assume an IAM Role, we have to set a [trust relationship](https://aws.amazon.com/blogs/security/how-to-use-trust-policies-with-iam-roles/) that looks as follows:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/SOMEUNIQUEID1234567890"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/SOMEUNIQUEID1234567890:sub": "system:serviceaccount:kube-system:external-dns"
        }
      }
    }
  ]
}
```

For every IRSA Role, you will replace the actual OIDC Provider URL with the OIDC Provider URL for the target cluster. In addition, update the Condition for the `sts:AssumeRoleWithWebIdentity` field to reflect the intended namespace and service, i.e. `kube-system` and `external-dns`. 

## Policies

Further down in this guide we explain how to initialise this repository. For now, just take note that we use placeholder values such as `<<__role_arn.external_dns__>>` that will be replaced by the actual ARNs of the Roles you wish to use. Below is a listing of all of the IRSA roles in use in this repository, along with links to JSON files with example policies. If you do a search on the whole "distribution" folder you find exactly where these placeholders are used.

---
### `aws-loadbalancer-controller`
Needs policy that allows it to schedule a NLB in specific subnests.

- Placeholder:      `<<__role_arn.loadbalancer_controller__>>`
- Example ARN:      `arn:aws:iam::123456789012:role/my-cluster_kube-system_aws-loadbalancer-controller`
- Policy:           [link](./iam_policies/lb-controller-v2_2_0-iam_policy.json)

---
### `cluster-autoscaler`
Needs policy that allows it to automatically scale EC2 instances up/down.
- Placeholder:      `<<__role_arn.cluster_autoscaler__>>`
- Example ARN:      `arn:aws:iam::123456789012:role/my-cluster_kube-system_aws-cluster-autoscaler`
- Policy:           [link](./iam_policies/cluster-autoscaler-policy.json)

---
### `external-dns`
Needs policy that allows it to automatically create record sets in Route53.
- Placeholder:      `<<__role_arn.external_dns__>>`
- Example ARN:      `arn:aws:iam::123456789012:role/my-cluster_kube-system_external-dns`
- Policy:           [link](./iam_policies/external-dns-policy.json)

---
### `certificate-manager`
Needs policies that allows it to automatically create entries in Route53 in order to allow for DNS-01 solving.
- Placeholder:      `<<__role_arn.cert_manager__>>`
- Example ARN:      `arn:aws:iam::123456789012:role/my-cluster_cert-manager_cert-manager`
- Policy:           [link](./iam_policies/cert-manager-iam_policy.json)

---
### `external-secrets`
A Kubernetes operator that integrates external secret management systems like AWS Secrets Manager, HashiCorp Vault, Google Secrets Manager, Azure Key Vault, IBM Cloud Secrets Manager, and many more. The operator reads information from external management system APIs and automatically injects the values as Kubernetes Secrets.  

Allow the `external-secret` operator wide authority to read all secrets defined in AWS Secrets Manager service.
- Placeholder:        `<<__role_arn.external_secrets>>`
- Example ARN:        `arn:aws:iam::123456789012:role/my-cluster_kube-system_external_secrets`
- Policy:             [link](./iam_policies/external-secrets-iam-policy.json)


#
## **Deployment**

This repository contains Kustomize manifests that point to the upstream
manifest of each Kubeflow component and provides an easy way for people
to change their deployment according to their need. ArgoCD application
manifests for each componenet will be used to deploy Kubeflow. The intended
usage is for people to fork this repository, make their desired kustomizations,
run a script to change the ArgoCD application specs to point to their fork
of this repository, and finally apply a master ArgoCD application that will
deploy all other applications.

## Prerequisites

- kubectl (latest)
- kustomize 4.0.5


## The `setup.conf` file and `setup_repo.sh` script

This repository uses a very simple initialisation script, [setup_repo.sh](../setup_repo.sh), that takes a config file such as [setup_repo.conf](../setup_repo.conf) and iterates over all lines. A single line would for example look as follows:
```bash
<<__role_arn.cluster_autoscaler__>>=arn:aws:iam::123456789012:role/my-cluster_kube-system_aws-cluster-autoscaler
```
The init script will look for all occurences in the ./distribution folder of the placeholder `<<__role_arn.cluster_autoscaler__>>` and will replace it with the value `arn:aws:iam::123456789012:role/my-cluster_kube-system_aws-cluster-autoscaler`. Please note that that comments (`//`, `#`), quatation marks (`"`, `'`) or unnecessary line-breaks should be avoided.

You may add any additional placeholder/value pairs you want. The naming convention `<<__...__>> ` has no functional purpose other than to aid readability and minimise the risk of a "find-and-replace" being performed on a value that was not meant as a placeholder.

## The `setup_credentials[].sh` scripts

The `setup_credentials[].sh` scripts generate [SealedSecrets](https://github.com/bitnami-labs/sealed-secrets) for access to "admin" applications and portals. These "admin" applications are things like the ArgoCD dashboard, Keycloak, kubeflow admin user, etc. They can also be extended to seal other secrets such as database info and store them safely upon first deployment. These secrets are then safe to be checked into source control as they are encrypted and sealed, accessibly only internally via kubectl commands on the cluster. 

## Deployment

To initialise your repository, do the following:
- fork this repo
- modify the kustomizations for your purpose. You may in particular wish to edit `distribution/araneae.yaml` with the selection of applications you wish to roll out
- create a `setup_repo.conf` file like [this](../setup_repo.conf) one
- run `./setup_repo.sh setup_repo.conf`
- run any `setup_credentials[].sh` scripts
- commit and push your changes

Start up external-secret:

```bash
kustomize build distribution/external-secrets/ | kubectl apply -f -
```

Start up argocd:

- If you are using a public repo:

  ```bash
  kustomize build distribution/argocd/base/ | kubectl apply -f -
  ```

- If you are using a private repo (note that this will use an ExternalSecret to fetch git credentials from an external secret manager, i.e. AWS Secret Manager):

  ```bash
  kustomize build distribution/argocd/overlays/private-repo/ | kubectl apply -f -
  ```

Finally, roll out your main application with:
```bash
kubectl apply -f distribution/araneae.yaml
```

## Updating the deployment

By default, all the ArgoCD application specs included here are
setup to automatically sync with the specified repoURL.
If you would like to change something about your deployment,
simply make the change, commit it and push it to your fork
of this repo. ArgoCD will automatically detect the changes
and update the necessary resources in your cluster.  

---
## Accessing the ArgoCD UI 

By default the ArgoCD UI is rolled out behind a ClusterIP. This can be accessed for development purposes with port forwarding, for example:

```bash
kubectl port-forward svc/argocd-server -n argocd 8888:80
```

The UI will now be accessible at `localhost:8888` and can be accessed with the initial admin password. The password is stored in a secret and can be read as follows:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

If you wish to update the password, this can be done using the [argcd cli](https://github.com/argoproj/argo-cd/releases/latest), using the following commands:
```bash
argocd login localhost:8888
argocd account update-password
```

