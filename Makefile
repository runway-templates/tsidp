TOOL := go run github.com/runway-templates/schema/cmd/tool@latest
IMAGE ?= ghcr.io/tailscale/tsidp:v0.0.21

.PHONY: test lint build run-dev

test: lint

lint:
	$(TOOL) lint template.yaml

build:
	@echo "nothing to build"

# Runs tsidp locally, locked down like on Runway. Without TS_AUTHKEY it
# prints a login link. State is gone when it stops.
run-dev:
	docker run --rm --read-only --user 1001:1001 \
	  --tmpfs /data:uid=1001,gid=1001 \
	  -e RUNWAY_TS_MANAGED=false \
	  -e TAILSCALE_USE_WIP_CODE=1 \
	  -e TS_AUTHKEY \
	  -e TS_STATE_DIR=/data \
	  -e TS_HOSTNAME=idp-dev \
	  -e TSIDP_USE_FUNNEL=false \
	  -e TSIDP_ENABLE_STS=true \
	  $(IMAGE)
