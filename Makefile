# Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# from .github/workflows/default_plan_unit_tests.yml

IMAGE := viya4-iac-azure:terratest

buildTests:
ifeq ($(shell docker images -q $(IMAGE) 2> /dev/null),)
	docker build -t $(IMAGE) -f Dockerfile.terratest .
endif

checkEnv:
ifndef TF_VAR_subscription_id
	$(error TF_VAR_subscription_id is undefined)
endif
ifndef TF_VAR_tenant_id
	$(error TF_VAR_tenant_id is undefined)
endif
ifndef TF_VAR_client_id
	$(error TF_VAR_client_id is undefined)
endif
ifndef TF_VAR_client_secret
	$(error TF_VAR_client_secret is undefined)
endif


runTests: checkEnv buildTests
	docker run -it --rm \
            -e TF_VAR_subscription_id=$(TF_VAR_subscription_id) \
            -e TF_VAR_tenant_id=$(TF_VAR_tenant_id) \
            -e TF_VAR_client_id=$(TF_VAR_client_id) \
            -e TF_VAR_client_secret=$(TF_VAR_client_secret) \
            -v $(pwd):/viya4-iac-azure \
            $(IMAGE) -v

clean:
	docker image rm $(IMAGE)