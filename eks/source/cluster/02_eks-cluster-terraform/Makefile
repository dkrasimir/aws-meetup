#Step 1: Terraform Init for the state.
terraform-init:
	terraform init

#Step 2: Terraform Plan to do a dry run
terraform-plan:
	terraform plan
#Step 3: Terraform apply (in this case with auto-approve to skip the yes question)
terraform-apply:
	terraform apply -auto-approve

#Step4: create the aws-auth file needed for the registration of the worker nodes. +
terraform-aws-auth:
	terraform output config_map_aws_auth > aws-auth.yaml

#Step5: create the kubeconfig file needed for kubectl to be able to connect to the cluster.
terraform-kubeconfig:
	terraform output kubeconfig > kubeconfig

#Step6a: COpy the kubeconfig in ~/.kube/
cp-kubeconfig:
	cp kubeconfig ~/.kube/

#Step6b:
export-kubeconfig:
	export KUBECONFIG=kubeconfig

#Step7: Check kubectl can connect to the cluster
kubecstl-get-all:
	kubectl get all



