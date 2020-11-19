
IAAS=aws
DOCKER_OPTS=--rm -v $(PWD):/brokerpak -w /brokerpak #--network=host
CSB=cfplatformeng/csb

.PHONY: build
build: $(IAAS)-services-*.brokerpak

$(IAAS)-services-*.brokerpak: *.yml terraform/*/*.tf terraform/*.tf 
	docker run $(DOCKER_OPTS) $(CSB) pak build

SECURITY_USER_NAME := $(or $(SECURITY_USER_NAME), aws-broker)
SECURITY_USER_PASSWORD := $(or $(SECURITY_USER_PASSWORD), aws-broker-pw)

.PHONY: run
run: build aws_access_key_id aws_secret_access_key
	docker run $(DOCKER_OPTS) \
	-p 8080:8080 \
	-e SECURITY_USER_NAME \
	-e SECURITY_USER_PASSWORD \
	-e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
	-e "DB_TYPE=sqlite3" \
	-e "DB_PATH=/tmp/csb-db" \
	$(CSB) serve

.PHONY: docs
docs: build
	docker run $(DOCKER_OPTS) \
	$(CSB) pak docs /brokerpak/$(shell ls *.brokerpak)

.PHONY: run-examples
run-examples: build
	docker run $(DOCKER_OPTS) \
	-e SECURITY_USER_NAME \
	-e SECURITY_USER_PASSWORD \
	-e "GSB_API_HOSTNAME=host.docker.internal" \
	-e USER \
	$(CSB) pak run-examples /brokerpak/$(shell ls *.brokerpak)

# fetching bits for cf push broker
cloud-service-broker:
	wget $(shell curl -sL https://api.github.com/repos/pivotal/cloud-service-broker/releases/latest | jq -r '.assets[] | select(.name == "cloud-service-broker") | .browser_download_url')
	chmod +x ./cloud-service-broker

APP_NAME := $(or $(APP_NAME), cloud-service-broker-aws)
DB_TLS := $(or $(DB_TLS), skip-verify)

.PHONY: push-broker
push-broker: cloud-service-broker build aws_access_key_id aws_secret_access_key
	MANIFEST=cf-manifest.yml APP_NAME=$(APP_NAME) DB_TLS=$(DB_TLS) ../scripts/push-broker.sh

.PHONY: aws_access_key_id
aws_access_key_id:
ifndef AWS_ACCESS_KEY_ID
	$(error variable AWS_ACCESS_KEY_ID not defined)
endif

.PHONY: aws_secret_access_key
aws_secret_access_key:
ifndef AWS_SECRET_ACCESS_KEY
	$(error variable AWS_SECRET_ACCESS_KEY not defined)
endif

.PHONY: clean
clean:
	- rm $(IAAS)-services-*.brokerpak
	- rm ./cloud-service-broker
