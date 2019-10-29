TAG ?= 6.2.3.21
TAG_TRACK ?= $(shell echo ${TAG} | sed 's/\([0-9]\+\.[0-9]\+\).*$$/\1/g')
TAG_TRACK2 ?= $(shell echo ${TAG} | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*$$/\1/g')

$(info ---- TAG = $(TAG))
$(info ---- TAG_TRACK = $(TAG_TRACK))
$(info ---- TAG_TRACK2 = $(TAG_TRACK2))
REGISTRY ?= gcr.io/strapdata-gcp-partnership/

REPO_NAME ?= elassandra-operator

include tools/gcloud.Makefile
include tools/crd.Makefile
include tools/var.Makefile
include tools/app.Makefile

UPSTREAM_IMAGE = docker.repo.strapdata.com/strapdata/strapkop-operator:$(TAG)
APP_MAIN_IMAGE ?= $(REGISTRY)$(REPO_NAME):$(TAG)
APP_MAIN_IMAGE_TRACK ?= $(REGISTRY)$(REPO_NAME):$(TAG_TRACK)
APP_MAIN_IMAGE_TRACK2 ?= $(REGISTRY)$(REPO_NAME):$(TAG_TRACK2)

APP_DEPLOYER_IMAGE ?= $(REGISTRY)$(REPO_NAME)/deployer:$(TAG)
APP_DEPLOYER_IMAGE_TRACK ?= $(REGISTRY)$(REPO_NAME)/deployer:$(TAG_TRACK)
APP_DEPLOYER_IMAGE_TRACK2 ?= $(REGISTRY)$(REPO_NAME)/deployer:$(TAG_TRACK2)

NAME ?= elassandra-1
APP_PARAMETERS ?= { \
  "APP_INSTANCE_NAME": "$(NAME)", \
  "NAMESPACE": "$(NAMESPACE)", \
  "APP_IMAGE": "$(APP_MAIN_IMAGE)" \
}

TESTER_IMAGE ?= $(REGISTRY)$(REPO_NAME)/tester:$(TAG)
TESTER_IMAGE_TRACK ?= $(REGISTRY)$(REPO_NAME)/tester:$(TAG_TRACK)
TESTER_IMAGE_TRACK2 ?= $(REGISTRY)$(REPO_NAME)/tester:$(TAG_TRACK2)

APP_TEST_PARAMETERS ?= { \
  "testerImage": "$(TESTER_IMAGE)" \
}


app/build:: .build/strapkop/deployer \
            .build/strapkop/strapkop \
            .build/strapkop/tester \



.build/strapkop: | .build
	mkdir -p "$@"


.build/strapkop/deployer: deployer/* \
                           manifest/* \
                           schema.yaml \
                           .build/var/APP_DEPLOYER_IMAGE \
                           .build/var/MARKETPLACE_TOOLS_TAG \
                           .build/var/REGISTRY \
                           .build/var/TAG \
                           | .build/strapkop
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)$(REPO_NAME)" \
	    --build-arg TAG="$(TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    --tag "$(APP_DEPLOYER_IMAGE_TRACK)" \
		--tag "$(APP_DEPLOYER_IMAGE_TRACK2)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	docker push "$(APP_DEPLOYER_IMAGE_TRACK)"
	docker push "$(APP_DEPLOYER_IMAGE_TRACK2)"
	@touch "$@"


.build/strapkop/strapkop:
							.build/var/APP_MAIN_IMAGE \
							.build/var/REGISTRY \
                            .build/var/TAG \
                           | .build/strapkop

	docker pull $(UPSTREAM_IMAGE)
	docker tag "$(UPSTREAM_IMAGE)" "$(APP_MAIN_IMAGE)"
	docker tag "$(UPSTREAM_IMAGE)" "$(APP_MAIN_IMAGE_TRACK)"
	docker tag "$(UPSTREAM_IMAGE)" "$(APP_MAIN_IMAGE_TRACK2)"
	docker push "$(APP_MAIN_IMAGE)"
	docker push "$(APP_MAIN_IMAGE_TRACK)"
	docker push "$(APP_MAIN_IMAGE_TRACK2)"
	@touch "$@"

.build/strapkop/tester:   .build/var/TESTER_IMAGE \
                           $(shell find apptest -type f) \
                           | .build/strapkop
	$(call print_target,$@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" --tag "$(TESTER_IMAGE_TRACK)" --tag "$(TESTER_IMAGE_TRACK2)" .
	docker push "$(TESTER_IMAGE)"
	docker push "$(TESTER_IMAGE_TRACK)"
	docker push "$(TESTER_IMAGE_TRACK2)"
	@touch "$@"
