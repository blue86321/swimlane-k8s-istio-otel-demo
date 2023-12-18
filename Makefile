.PHONY: build push install deploy undeploy uninstall

#################### Docker (prepare image) ####################
DOCKER_HUB_USER = blue86321
SERVICES := gateway goods pricing

build:
	@for svc in $(SERVICES); do \
		docker build -t $(DOCKER_HUB_USER)/swimlane-demo-$$svc-otel:1.0.0 -f services/$$svc/Dockerfile .; \
	done
push:
	docker login;
	@for svc in $(SERVICES); do \
		docker push $(DOCKER_HUB_USER)/swimlane-demo-$$svc-otel:1.0.0; \
	done

#################### Kubernetes ####################
RESOURCE_FILES := $(filter-out deployment/cert-manager-verifier.yaml,$(wildcard deployment/*.yaml))
install:
	@echo "---------- Install Istio Related CRD and Inject ----------"
	istioctl install --set profile=demo -y
	kubectl label namespace default istio-injection=enabled
	@echo "---------- Install cert-manager CRD ----------"
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
	@echo "---------- Verify cert-manager Installation ----------"
	@while true; do \
		kubectl apply -f deployment/cert-manager-verifier.yaml > /dev/null 2>&1 && break; \
		sleep 20; \
	done
	kubectl delete -f deployment/cert-manager-verifier.yaml
	@echo "---------- Install OpenTelemetry CRD ----------"
	kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.90.0/opentelemetry-operator.yaml
	@echo "---------- Install K8s Gateway CRD ----------"
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
deploy:
	@echo "---------- Deploying resources ----------"
	# auto-instrument resources MUST be deployed before applications
	# source: https://opentelemetry.io/docs/kubernetes/operator/automatic/#were-the-resources-deployed-in-the-right-order
	kubectl apply -f deployment/otel-auto-instrument.yaml
	@for file in $(RESOURCE_FILES); do \
		kubectl apply -f $$file; \
	done
	kubectl wait --for=condition=available deploy/gateway-deploy-main --timeout=300s
	kubectl port-forward svc/gateway-service 8080:8080
undeploy:
	@echo "---------- Deleting resources ----------"
	@for file in $(RESOURCE_FILES); do \
		kubectl delete --ignore-not-found=true -f $$file; \
	done
uninstall:
	@echo "---------- Uninstall OpenTelemetry CRD ----------"
	kubectl delete --ignore-not-found=true -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.90.0/opentelemetry-operator.yaml || true
	@echo "---------- Uninstall cert-manager CRD ----------"
	kubectl delete --ignore-not-found=true -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
	@echo "---------- Uninstall Istio CRD and namespace ----------"
	istioctl uninstall --purge -y || true
	kubectl delete --ignore-not-found=true namespace istio-system
