# Cluster Creation and Deployment (Araneae)

This repo contains instructions and scripts to create the infrastructure and deploy the application.

### Prerequisite Supporting CLI Tools and Utilities
--------------------------------------------
* yq - *(CLI processor for yaml files)*
    * [Github page](https://github.com/mikefarah/yq)
        * `curl --silent --location "https://github.com/mikefarah/yq/releases/download/v4.2.0/yq_linux_amd64.tar.gz" | tar xz && sudo mv yq_linux_amd64 /usr/local/bin/yq`
* kubectl - *(official CLI for generic Kubernetes)*
    * [Install kubectl - OSX/Linux/Windows](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
    * Install kubectl version `1.23.7`
        * `curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl`
        * `chmod +x ./kubectl`
        * `sudo mv kubectl /usr/local/bin/kubectl`
        * `kubectl version --short --client`
* kustomize - *(Customize kubernetes YML configurations)*
    * `curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash`
    * `sudo mv kustomize /usr/local/bin`
    * `kustomize version`
* eksctl - *(official CLI for Amazon EKS)*
    * [Install/Upgrade eksctl - OSX/Linux/Windows](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
    * `curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp`
    * `sudo mv /tmp/eksctl /usr/local/bin`
    * `eksctl version`
* AWS CLI - *(official CLI for AWS)*
    * [Install AWS CLI - Linux](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install)
    * [Upgrade AWS CLI - Linux](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-upgrade)


### Install Instructions
--------------------------------------------
Before you deploy, you must have a k8s cluster up and running. We have AWS EKS  
cluster specification as part of the repo, `aws-eks-cluster-spec.yaml`. This  
makes it very easy to deploy an AWS EKS cluster for you to use in a public cloud.  
Use the `eksctl` tool to create a specific cluster up on AWS for your needs.  
## Step 1 - Configure `awscli`
Define your key and secret in `~/.aws/credentials`
```
[default]
aws_access_key_id = SOMETHING
aws_secret_access_key = SOMETHINGLONGER

[paloul]
aws_access_key_id = SOMETHING
aws_secret_access_key = SOMETHINGLONGER
```
If using AWS Organization sub-accounts, then define your profile information (AWS Organization) in `~/.aws/config`.
```
[default]
region = us-west-2
output = json

[profile araneae]
region = us-west-2
output = json
role_arn = arn:aws:iam::113113113456:role/subaccount-araneae
source_profile = paloul
```

You must execute `awscli` or `eksctl` commands while assuming the correct role in order  
to deploy the cluster under the right account. This is done with either the `--profile` option  
or the use of an environment variable `AWS_PROFILE`, i.e. `export AWS_PROFILE=profile1`,  
before executing any commands. Visit [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html#using-profiles) for information.

Execute the following command to verify you configured `awscli` and `eksctl` correctly:
```
╰─❯ eksctl get cluster --verbose 4 --profile araneae
2022-05-19 15:13:08 [▶]  role ARN for the current session is "arn:aws:sts::113113113456:assumed-role/subaccount-access/aws-go-sdk-1652998387669703569"
2022-05-19 15:13:08 [ℹ]  eksctl version 0.97.0
2022-05-19 15:13:08 [ℹ]  using region us-west-2
No clusters found
```
You will see any existing EKS clusters listed in that account that you have access to.

----

## Step 2 - Create EKS Cluster - [Additional Info](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)
Execute the following `eksctl` command to create a cluster under the AWS account. You should  
be in the same directory as the file `aws-eks-cluster.yaml`. 
```
eksctl create cluster -f aws-eks-cluster-spec.yaml --profile araneae
```
This command will take several minutes as `eksctl` creates the entire stack with  
supporting services inside AWS, i.e. VPC, Subnets, Security Groups, Route Tables,  
in addition to the cluster itself. Once completed you should see the following:
```
[✓]  EKS cluster "araneae" in "us-west-2" region is ready
```
With nothing else running on the cluster you can check `kubectl` and see similar output:  
```
╰─❯ kubectl get nodes
NAME                                           STATUS   ROLES    AGE   VERSION
ip-192-168-2-226.us-west-2.compute.internal    Ready    <none>   17m   v1.19.6-eks-49a6c0
ip-192-168-26-228.us-west-2.compute.internal   Ready    <none>   17m   v1.19.6-eks-49a6c0

╰─❯ kubectl get pods -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
aws-node-2ssm5             1/1     Running   0          19m
aws-node-xj5sb             1/1     Running   0          19m
coredns-6548845887-fg74h   1/1     Running   0          25m
coredns-6548845887-vlzff   1/1     Running   0          25m
kube-proxy-hjgd5           1/1     Running   0          19m
kube-proxy-jm2m9           1/1     Running   0          19m
```
### <u>Delete the EKS Cluster When Not Needed</u>
In order to avoid being charged while not in use please use the following command to delete your cluster:
```
eksctl delete cluster -f aws-eks-cluster-spec.yaml --profile araneae
```