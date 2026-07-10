#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
REGISTRY="${REGISTRY:?}"
TAG="${GIT_SHA:?}"
IMAGE="$REGISTRY/function-app:$TAG"

echo "=== Building hosted agent container ==="
cd $REPO_ROOT/app

echo "=== Install deps ==="

uv sync

echo "===  Ruff check ==="
uv run ruff check . --fix --output-format=github

echo "===  Ruff format ==="
uv run ruff format . --check --diff

echo "===  Pyrefly type check ==="
uv run pyrefly check

echo "===  Pylint ==="
uv run pylint function_app.py -rn -sn --rcfile=../pylintrc

echo "=== No Tests yet ==="
# uv run pytest -v --timeout=30 -x
# # check test coverage

echo "===  Build container ==="
cd "$REPO_ROOT"
podman build --platform linux/amd64 -t "$IMAGE" $REPO_ROOT/app

echo "===  Container scan ==="
trivy image --severity CRITICAL,HIGH \
  --format sarif --output "trivy-sarif" \
  "$IMAGE" || true

echo "===  SBOM ==="
trivy image --format cyclonedx \
  --output "sbom-cdx.json" \
  "$IMAGE"

echo "===  Push ==="
ACR_NAME="$(echo "$REGISTRY" | cut -d. -f1)"
az acr login --name "$ACR_NAME"
podman push "$IMAGE"

echo "===  Attach SBOM ==="
oras login "$REGISTRY" --identity-token-stdin <<< "$(az acr login --name "$ACR_NAME" --expose-token --query accessToken -o tsv 2>/dev/null)"
oras attach "$IMAGE" \
  --artifact-type application/vnd.cyclonedx+json \
  "sbom-cdx.json"
