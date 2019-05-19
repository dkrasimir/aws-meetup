# Setup AWS EKS Cluster and deploy an App

## Clone the GitRepo with the tutorial

```console
git clone git@github.com:dkrasimir/aws-meetup.git
```

### Setup the AWS CLI

To setup the AWS CLI you need to configure the AWS Access Key ID and the AWS Secret Access Key. The values will be provided at the training session.

in `~/.aws/credentials`:

```yaml
[default]
aws_access_key_id = TODO
aws_secret_access_key = TODO
```

In `~/.aws/config`:

```yaml
[default]
output = json
region = eu-west-1
```


Check the configuration calling:

```console
$ aws sts get-caller-identity
{
    "UserId": "<USER ID>",
    "Account": "<ACCOUNT ID>",
    "Arn": "arn:aws:iam::<ACCOUNT ID>:user/hackandlearn"
}
```

## Create EKS cluster using eksctl

```console
$ eksctl create cluster --name=aws-hackandlearn-nttdata --nodes=3 --node-type=m5.large --region eu-west-1
[ℹ]  using region eu-west-1
[ℹ]  setting availability zones to [eu-west-1c eu-west-1a eu-west-1b]
[ℹ]  subnets for eu-west-1c - public:192.168.0.0/19 private:192.168.96.0/19
[ℹ]  subnets for eu-west-1a - public:192.168.32.0/19 private:192.168.128.0/19
[ℹ]  subnets for eu-west-1b - public:192.168.64.0/19 private:192.168.160.0/19
[ℹ]  nodegroup "ng-403a3672" will use "ami-08716b70cac884aaa" [AmazonLinux2/1.12]
[ℹ]  creating EKS cluster "aws-hackandlearn-nttdata" in "eu-west-1" region
[ℹ]  will create 2 separate CloudFormation stacks for cluster itself and the initial nodegroup
[ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=eu-west-1 --name=aws-hackandlearn-nttdata'
[ℹ]  2 sequential tasks: { create cluster control plane "aws-hackandlearn-nttdata", create nodegroup "ng-403a3672" }
[ℹ]  building cluster stack "eksctl-aws-hackandlearn-nttdata-cluster"
[ℹ]  deploying stack "eksctl-aws-hackandlearn-nttdata-cluster"
[ℹ]  buildings nodegroup stack "eksctl-aws-hackandlearn-nttdata-nodegroup-ng-403a3672"
[ℹ]  --nodes-min=3 was set automatically for nodegroup ng-403a3672
[ℹ]  --nodes-max=3 was set automatically for nodegroup ng-403a3672
[ℹ]  deploying stack "eksctl-aws-hackandlearn-nttdata-nodegroup-ng-403a3672"
[✔]  all EKS cluster resource for "aws-hackandlearn-nttdata" had been created
[✔]  saved kubeconfig as "C:\\Users\\dzhigk/.kube/config"
[ℹ]  adding role "arn:aws:iam::016973021151:role/eksctl-aws-hackandlearn-nttdata-n-NodeInstanceRole-1JS4K54H06EL2" to auth ConfigMap
[ℹ]  nodegroup "ng-403a3672" has 0 node(s)
[ℹ]  waiting for at least 3 node(s) to become ready in "ng-403a3672"
[ℹ]  nodegroup "ng-403a3672" has 3 node(s)
[ℹ]  node "ip-192-168-6-215.eu-west-1.compute.internal" is ready
[ℹ]  node "ip-192-168-63-26.eu-west-1.compute.internal" is ready
[ℹ]  node "ip-192-168-94-132.eu-west-1.compute.internal" is ready
[ℹ]  kubectl command should work with "C:\\Users\\dzhigk/.kube/config", try 'kubectl get nodes'
[✔]  EKS cluster "aws-hackandlearn-nttdata" in "eu-west-1" region is ready
```

Once you have created a cluster, you will find that cluster credentials were added in ~/.kube/config

Test the cluster

```console
kubectl get nodes
```

## Create EKS cluster using terraform

Source [Terraform AWS EKS Intro](https://learn.hashicorp.com/terraform/aws/eks-intro)

```console
cd eks/source/cluster/02_eks-cluster-terraform
terraform init
terraform plan
terraform apply -auto-approve
```

This will then go and provision the Security Groups, the VPC, the Subnets, the EKS cluster, and the worker nodes. It should take around 10 minutes to bring up the full cluster.

Next we will use the output subcommand to output the aws-auth configmap which will give the worker nodes the ability to connect to the cluster.

```console
terraform output config_map_aws_auth > aws-auth.yaml
```

```console
terraform output kubeconfig > kubeconfig
```

With aws-auth.yaml and the kubeconfig file out you can then configure kubectl to use the kubeconfig file and apply the aws-auth configmap.

```console
export KUBECONFIG=kubeconfig
```

Now we can check the connection to the Amazon EKS cluster running kubectl.

```console
kubectl get all
```

Currently there are no nodes connected.
Now we can apply the aws-auth configmap. That way the worker nodes will connect to the master plane.

```console
kubectl apply -f aws-auth.yaml
```

Check the nodes get connected.

```console
kubectl get nodes -w
```

## Deploy nginx using terraform.

```console
cd 50-eks-terraform/source/k8s
terraform init
terraform apply
```

## Deploy nginx using kubectl.

```console
cd 50-eks-terraform/source/k8s/
kubectl apply -f sample/deployment-nginx.yaml
```

Check the deployment was successful.

```console
kubectl get pods
```

Call the service via the generated DNS name.

```console
kubectl get svc -o wide
```

## Setup ExternalDNS

[Source of the Tutorial] (https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/aws.md)

```console
cd eks/source/cluster/03_external-dns
kubectl apply -f external-dns-manifest.yaml
```

Verify ExternalDNS works

```console
kubectl apply -f deployment-nginx.yaml
```

The important part that has changed is the annotation added to the service. 

```yaml
annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx.tech-talk-ntt.com
```

## Generate ~/.kube/config if you haven't created the cluster.

If you haven't created the cluster you'll need a ~/.kube/config file containing the credentials to be able to communicate with the cluster. Please take a look below in the Tips & Tricks section on howto create kubeconfig for the Dev Users.

```console
aws eks update-kubeconfig --name=terraform-eks-demo --region=eu-west-1
```

Test the connection using the following command:

```console
kubectl get nodes
```

### Show the list of kubernetes contexts and select one

```console
kubectl config get-contexts
kubectl config use-context <context-name>
```

### Create a namespace and switch to it

```console
kubectl create namespace <NAMESPACE NAME>
kubectl config set-context $(kubectl config current-context) --namespace=<NAMESPACE NAME>
```

## Helm - the package manager for Kuberentes (using tiller)

[Installing Helm](https://helm.sh/docs/using_helm/#installing-helm)
> You can find very good description on how to use Helm with EKS here: [AWS EKS Worlshop Helm Intro](https://eksworkshop.com/helm_root/helm_intro/)

Once you have Helm ready, you can initialize the local CLI and also install Tiller into your Kubernetes cluster in one step (source - [Link](https://github.com/helm/helm/blob/master/docs/quickstart.md))

```console
helm init --history-max 200
```

### Tiller and role based access control

Source: https://raw.githubusercontent.com/helm/helm/master/docs/rbac.md

In `rbac-config.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

```console
kubectl create -f helm/rbac-config.yaml
```

Init helm installing tiller using the created service account.

```console
helm init --service-account tiller --history-max 200
```

Here you can find an example on howto Deploy Tiller in a namespace, restricted to deploying resources only in that namespace - [Link](https://github.com/helm/helm/blob/master/docs/rbac.md)

Now we should update the local list of charts: 

```console
helm repo update
```

Now that our repository Chart list has been updated, we can search for Charts.

```console
helm search
```

You can search using keyword argument, like nginx.

```console
helm search nginx
```

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Sample installing nginx. 

```console
helm install --name mywebserver bitnami/nginx
```

Sample installing Wordpress.

```console
helm install --name wordpress stable/wordpress
```

Connecto to the Wordpress site.

```console
echo http://$(kubectl get svc wordpress-wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

### Delete the application

Using this command you'll delete all the ressources incl. the AWS LoadBalnacer. 

```console
kubectl delete all -l app=XXXX
```

### Delete the EKS cluster using terraform

```console
terraform destroy
```

## Tips & Tricks

### Create EKS cluster using eksctl with auto scaling

```console
eksctl create cluster --name=aws-meetup-nttdata --nodes-min=3 --nodes-max=5 --region eu-west-1
```

> NOTE: You will still need to install and configure autoscaling. See the "Enable Autoscaling" section below. Also note that depending on your workloads you might need to use > a separate nodegroup for each AZ. See Zone-aware Autoscaling below for more info.

## Setting up kubectl access for an alternative user

To create a new user, we need to define a new user in the AWS IAM (preferably only programatic access; this user will not need access to the web console) and associate a new policy that allows this user to read/list EKS clusters.

Created policy `KubeUserPolicy`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "eks:DescribeUpdate",
                "eks:ListUpdates",
                "eks:DescribeCluster"
            ],
            "Resource": "arn:aws:eks:eu-west-1:016973021151:cluster/aws-hackandlearn-nttdata"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "eks:ListClusters",
            "Resource": "*"
        }
    ]
}
```

We also need to update the AWS authentication properties in the configmap/aws-auth configmap to give access to an AWS user to our cluster. We need to update that configmap to have our new user and any roles/cluster roles we want to associate with it. 

To edit the ConfigMap execite following command:

```console
kubectl edit cm/aws-auth -n kube-system
```

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::016973021151:role/eksctl-aws-hackandlearn-nttdata-n-NodeInstanceRole-1W32D2GH1UW9R
      username: system:node:{{EC2PrivateDNSName}}
  mapUsers: |
    - userarn: arn:aws:iam::016973021151:user/hackandlearn-dev
      username: hackandlearn-dev
      groups:
      - system:masters
kind: ConfigMap
metadata:
  creationTimestamp: 2019-04-23T21:39:45Z
  name: aws-auth
  namespace: kube-system
  resourceVersion: "34361"
  selfLink: /api/v1/namespaces/kube-system/configmaps/aws-auth
  uid: 4ff057af-6610-11e9-a9a7-06a17ceb360a
```

We can give the user one of the possible cluster roles (e.g. system:masters). You can get a list using following command:

```console
kubectl get clusterroles
```

### Create Kubeconfig for the Dev Users

Configure first the AWS CLI for the dev user using the user credentials from AWS IAM (aws_access_key_id and aws_secret_access_key).
To generate the kubeconfig in the `~/.kube` directory execute the following command: 

```console
aws eks update-kubeconfig --name=aws-hackandlearn-nttdata --region=eu-west-1
```

If there are some issues you can try to genreate a token using following command:

```console
aws-iam-authenticator token -i aws-hackandlearn-nttdata
```

### Deploy an App Using DockerHub als Registry (instead of AWS ECR)

Using Docker Hub you need to create a secret and use it later in the deployment yaml spec.
WIth the following command we create a secret with the name **dockerhubpull** in the **default** namespace.

```console
kubectl create -n default secret docker-registry dockerhubpull --docker-username=USERNAME --docker-server=docker.io --docker-email=EMAIL --docker-password=XXXXX
```

Inspecting the secret.

```console
kubectl get secret dockerhubpull --output=yaml
```

Here how you can decode the secret value. 

```console
kubectl get secret dockerhubpull --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

To use the secret you need to add it to the deployment configuration. 

```yaml
imagePullSecrets:
- name: dockerhubpull
```

### Install Prometheus using Helm

```console
helm install stable/prometheus \
--name prometheus \
--namespace prometheus \
--set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"
```

Use kubectl to port forward the Prometheus console to your local machine.

```console
kubectl --namespace=prometheus port-forward deploy/prometheus-server 9090
```

Point a web browser to **localhost:9090** to view the Prometheus console.

Choose a metric from the - insert metric at cursor menu, then choose Execute. Choose the Graph tab to show the metric over time. The following image shows container_memory_usage_bytes over time.

### Helm - Add a new repository

NGINX offers many different products via the default Helm Chart repository, but the NGINX standalone web server is not one of them.

There is a Chart for the NGINX standalone web server available via the Bitnami Chart repository.

To add the Bitnami Chart repo to our local list of searchable charts:

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Once that completes, we can search all Bitnami Charts:

```console
helm search bitnami
```

To install the bitname nginx server use the following command.

```console
helm install --name mywebserver bitnami/nginx
```

### Running a container (simple version)

The kubectl create line below will create a deployment named sample-nginx to ensure that there are always a nginx pod running.

```bash
kubectl create deployment --image nginx sample-nginx
```

You can find more samples here - [Link](https://github.com/kubernetes/examples/blob/master/staging/simple-nginx.md)

#### Expose your pods to the internet

```bash
kubectl expose deployment sample-nginx --port=80 --type=LoadBalancer
```

To see the newly created service including the public IP Adress execute following command.

```bash
kubectl get services
```

#### Clean Up (simple version)

To delete the two replicated containers, delete the deployment:
kubectl delete deployment sample-nginx

### How can I scale a node group to 0?

From CA 0.6 for GCE/GKE and CA 0.6.1 for AWS, it is possible to scale a node group to 0 (and obviously from 0), assuming that all scale-down conditions are met.

For AWS, if you are using nodeSelector, you need to tag the ASG with a node-template key "k8s.io/cluster-autoscaler/node-template/label/".

For example, for a node label of foo=bar, you would tag the ASG with:

```json
{
    "ResourceType": "auto-scaling-group",
    "ResourceId": "foo.example.com",
    "PropagateAtLaunch": true,
    "Value": "bar",
    "Key": "k8s.io/cluster-autoscaler/node-template/label/foo"
}
```

### 

```console
kubectl edit configmap -n kube-system aws-auth
```

Add a new mapRoles entry for the new worker node group.

```yaml
apiVersion: v1
data:
  mapRoles: |
    - rolearn: <ARN of instance role (not instance profile)>
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::111122223333:role/workers-1-10-NodeInstanceRole-U11V27W93CX5
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

Replace the <ARN of instance role (not instance profile)> snippet with the NodeInstanceRole value that you recorded, then save and close the file to apply the updated configmap.

Watch the status of your nodes and wait for your new worker nodes to join your cluster and reach the Ready status.

```console
kubectl get nodes --watch
```

### How to use ExternalDNS?

[For more Details follow this tutorial](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/aws.md)

Check your cluster has RBAC

```console
kubectl api-versions | grep rbac.authorization.k8s.io
```

## Requirements

### Install required tools for Windows

You can install all the needed tools using the package manager for windows [Chocolatey](https://chocolatey.org).

```console
choco install terraform -y
choco install eksctl -y
choco install awscli -y
choco install kubernetes-cli -y
choco install kubernetes-helm -y
choco install maven -y
choco install jdk8 -params 'installdir=c:\\java8'
```

### VS Code Kubernetes Extension

Really good VS Code Kubernetes extension.

https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools

## Furter Links

* [AWS EKS Workshop](https://eksworkshop.com/)
* [Running your first containers in Kubernetes](https://github.com/kubernetes/examples/blob/master/staging/simple-nginx.md)
* [Setting up Amazon EKS: What you must know](https://medium.com/@dmaas/setting-up-amazon-eks-what-you-must-know-9b9c39627fbc)
* [AWS Cost Savings by Utilizing Kubernetes Ingress with Classic ELB](https://akomljen.com/aws-cost-savings-by-utilizing-kubernetes-ingress-with-classic-elb/)
* [How to setup NGINX ingress controller on AWS clusters](https://medium.com/kokster/how-to-setup-nginx-ingress-controller-on-aws-clusters-7bd244278509)
* [Kubectl aliases Sebastian Daschner](https://github.com/sdaschner/ibm-cloud-tools/tree/master/kubectl)
* [Kubernetes Ingress with AWS ALB Ingress Controller](https://aws.amazon.com/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/)
* [AWS Ingress Controller](https://github.com/aws-samples/aws-workshop-for-kubernetes/blob/master/04-path-security-and-networking/405-ingress-controllers/readme.adoc)
* [Learning Kubernetes on EKS by Doing](https://medium.com/devopslinks/learning-kubernetes-on-eks-by-doing-part-4-ingress-on-eks-6c5e5a34920b)
* [How auth works in EKS with IAM Users](http://marcinkaszynski.com/2018/07/12/eks-auth.html)
* [Helm 2.x without Tiller | Jenkins X](https://jenkins-x.io/news/helm-without-tiller/)
* [Using Helm without Tiller](https://blog.giantswarm.io/what-you-yaml-is-what-you-get/)
* [90 Days AWS EKS in Production](https://kubedex.com/90-days-of-aws-eks-in-production/)
* [Tinder’s move to Kubernetes](https://medium.com/@tinder.engineering/tinders-move-to-kubernetes-cda2a6372f44)
* [Configure RBAC In Your Kubernetes Cluster](https://docs.bitnami.com/kubernetes/how-to/configure-rbac-in-your-kubernetes-cluster/)
* [Helm RBAC Tiller](https://github.com/helm/helm/blob/master/docs/rbac.md)
* [Setup AWS EKS Cluster using Terraform](https://www.esentri.com/building-a-kubernetes-cluster-on-aws-eks-using-terraform_part2/)
* [Deploy a full EKS cluster with Terraform](https://github.com/WesleyCharlesBlake/terraform-aws-eks)
* [Introducing Horizontal Pod Autoscaler for Amazon EKS](https://aws.amazon.com/blogs/opensource/horizontal-pod-autoscaling-eks/)
* [Amazon ECR](https://aws.amazon.com/ecr/?nc1=h_ls)
* [Easy AWS EKS cluster provisioning and user access](https://medium.com/solo-io/easy-aws-eks-cluster-provisioning-and-user-access-5e3cdc01dfc6)
* [Managing User or IAM Roles for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
* [Amazon Docs - EKS Optimized AMI](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)
* [EKS Worker Nodes YAML - Required data](https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml)
* [Amazon EKS A1 Instances Preview Program](https://github.com/aws/containers-roadmap/tree/master/preview-programs/eks-ec2-a1-preview)
* [Terraform EKS AWS Intro](https://learn.hashicorp.com/terraform/aws/eks-intro)
* [EKS Update Cluster (Managed Control Plane)](https://aws.amazon.com/de/blogs/compute/making-cluster-updates-easy-with-amazon-eks/)
* [EKS Worker Node Updates](https://docs.aws.amazon.com/eks/latest/userguide/update-workers.html)
* [Using ENI (IP Addresses Per Network Interface Per Instance Type)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI)
* [EKS Platform Versions](https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html)
* [Cluster Autoscaler on AWS](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md)
* [Medium - Cluster Autoscaler in Amazon EKS](https://medium.com/@alejandro.millan.frias/cluster-autoscaler-in-amazon-eks-d9f787176519)
* [External DNS for Services on AWS](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/aws.md)