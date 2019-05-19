terraform-init:
	terraform init

terraform-plan:
	terraform plan

terraform-apply:
	terraform apply

terraform-clean:
	rm -rf .terraform *.tfstate *.tfstate.backup

#Set K8s kontext
#kubectl config get-contexts
#kubectl config use-context <context-name>

#Change Namespace
#kubectl config set-context $(kubectl config current-context) --namespace=awscommunity
kubectl-set-namespace:
	kubectl config set-context aws --namespace=awscommunity

kubectl-svc-wide:
	kubectl get svc -o wide

kubernetes-scale:
	kubernetes scale deployment nginx --replicas 3

create-guestbook-app:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-service.json
	
