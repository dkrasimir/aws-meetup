CLUSTER_NAME=aws-meetup-nttdata

#########################################
#				EKSCTL					#
#########################################

eksctl-create-cluster:
	eksctl create cluster --name=aws-meetup-nttdata --node-type=m4.large --region=eu-west-1
eksctl-delete-cluster:
	eksctl delete cluster --name=aws-meetup-nttdata
kubeconfig:
	aws eks update-kubeconfig --name=terraform-eks-demo --region=eu-west-1
show-aws-auth:
	kubectl describe cm aws-auth -n kube-system

#########################################
#				k8s dashboard			#
#########################################
install-dashboard:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

dashboard-rbac:
	kubectl apply -f k8s/dashboard/rbac-config.yaml

dashboard-token:
#	kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

dashboard-proxy:
	kubectl proxy &
open-dashboard:
	start chrome http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

#########################################
#			kubectl deployment		    #
#########################################
#kubectl config set-context $(kubectl config current-context) --namespace=awsmeetup
create-namespace:
	kubectl create namespace demo-aws-meetup
deploy-nginx:
	kubectl apply -f k8s/sample/deployment-nginx.yaml
delete-nginx:
	kubectl delete all -l app=nginx
get-all:
	kubectl get all --all-namespaces
#########################################
#				HELM					#
#########################################

#Create service account for tiller
helm-rbac:
	kubectl apply -f helm/rbac-config.yaml

#Inititialize the local cli and install tiller. 
#Setting --history-max on helm init is recommended as configmaps 
#and other objects in helm history can grow large in number if not purged by max limit. 
helm-init:
	helm init --service-account tiller --history-max 200

helm-add-bitnami-repo:
	helm repo add bitnami https://charts.bitnami.com/bitnami

helm-search:
	helm search wordpress
helm-install-wp:
	helm install --name wordpress stable/wordpress
helm-delete-wp:
	helm delete wordpress
helm-url-wordpress:
	@echo http://$$(kubectl get svc --namespace awsmeetup wordpress-wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
helm-user-wp:
	@echo Username: user
helm-password-wp:
	@echo Password: $$(kubectl get secret --namespace awsmeetup wordpress-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
helm-install-nginx:
	helm install --name mywebserver bitnami/nginx


#########################################
#				ExternalDNS				#
#########################################
external-dns:
	kubectl apply -f cluster/03_external-dns/external-dns-manifest.yaml -n kube-system
external-dns-sample:
	kubectl apply -f cluster/03_external-dns/deployment-nginx.yaml