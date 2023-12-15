.PHONY: build push install deploy undeploy uninstall

#################### Docker (prepare image) ####################
DOCKER_HUB_USER = blue86321
SERVICES := gateway goods pricing

build:
	@for svc in $(SERVICES); do \
		docker build -t $(DOCKER_HUB_USER)/swimlane-demo-$$svc:1.0.0 -f services/$$svc/Dockerfile .; \
	done
push:
	docker login;
	@for svc in $(SERVICES); do \
		docker push $(DOCKER_HUB_USER)/swimlane-demo-$$svc:1.0.0; \
	done

#################### Kubernetes ####################
RESOURCE_FILES := $(wildcard deployment/*.yaml)
install:
	@echo "---------- Install Istio Related CRD and Inject ----------"
	istioctl install --set profile=demo -y
	kubectl label namespace default istio-injection=enabled
deploy:
	@echo "---------- Deploying resources ----------"
	@for file in $(RESOURCE_FILES); do \
		kubectl apply -f $$file; \
	done
undeploy:
	@echo "---------- Deleting resources ----------"
	@for file in $(RESOURCE_FILES); do \
		kubectl delete --ignore-not-found=true -f $$file; \
	done
uninstall:
	@echo "---------- Uninstall Istio CRD and namespace ----------"
	istioctl uninstall --purge -y || true
	kubectl delete --ignore-not-found=true namespace istio-system
