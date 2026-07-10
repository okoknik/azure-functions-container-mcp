# Infrastructure

OpenTofu-managed Azure infrastructure for Foundry Agents.

## Directory structure

```
infra/
├── environments/
│   └── dev/          # All infra: RG, ACR, App Config, and the agent module
└── modules/
    ├── agent/               # Core agent infra: storage, search, cosmos, AI Foundry, model, cap hosts, connections, role assignments
    └── agent_deployment/    # (WIP) Agent application + deployment — not yet wired into dev
```

## Environment

| Environment | State backend | Purpose |
|---|---|---|
| `dev` | Azure Storage (`dev.terraform.tfstate`) | Single environment for all infrastructure |

## Resources created

### `dev` (root)

| Resource | Detail |
|---|---|
| Resource group | Named `{name}{postfix}-rg` |
| Container Registry | `containerRegistryFoundryAgent`, Basic SKU |
| App Configuration | `appConf{postfix}` |
| Random string | 4-char numeric postfix for unique naming |
| Role assignment | AcrPush for deploying identity |

### Via `modules/agent`

| Resource | Detail |
|---|---|
| Storage Account | `{prefix}{postfix}stor`, Standard ZRS, managed-identity auth |
| Azure AI Search | `{prefix}{postfix}-search`, Standard SKU |
| Cosmos DB | `{prefix}{postfix}cosmos`, Session consistency, GlobalDocumentDB |
| AI Foundry account | `{prefix}{postfix}-shared`, AIServices kind, S0 |
| AI Foundry project | `standard-agent-project` |
| Model deployment | `{model_name}-{postfix}`, GlobalStandard, default `gpt-5.4-nano` / `2026-03-17` |
| Capability hosts | Account-level + project-level, Agents kind |
| Connections | Storage, Search, Cosmos — all AAD auth |
| Role assignments | Storage Blob Data Contributor, Search Index Data Contributor, Search Service Contributor, Cosmos DB Operator, Cosmos DB SQL Contributor (data-plane), AcrPull (project → ACR), Foundry User (deploying identity → AI Foundry) |

## How the pieces fit together

```
dev
 ├── creates RG + ACR ──────────────> CI pushes image :sha
 ├── creates AI Foundry account ────> hosts project, model, capability hosts
 ├── creates storage/search/cosmos ─> connected to project via AAD
 └── creates capability hosts ──────> enables hosted agent runtime
```

## Variables

### `dev`

| Variable | Default | Description |
|---|---|---|
| `name` | `foundry-agent` | Name prefix for resources |
| `location` | `swedencentral` | Azure region |
| `tags` | `{owner: me, managed_by: terraform}` | Resource tags |
| `agent_image_tag` | `initial` | Container image tag (set by CI/CD) |
| `agent_replicas` | `2` | Fixed replica count (min = max) |

### Via `modules/agent`

| Variable | Default | Description |
|---|---|---|
| `ai_services_name_prefix` | `foundry` | Prefix for AI Foundry account name |
| `project_name` | `standard-agent-project` | AI Foundry project name |
| `model_name` | `gpt-5.4-nano` | Model to deploy |
| `model_version` | `2026-03-17` | Model version |
| `model_capacity` | `1` | Model deployment capacity |
| `agent_image_tag` | `latest` | Container image tag |
| `agent_replicas` | `1` | Fixed replica count |
| `application_name` | `insights-agent-app` | Agent application name |
| `deployment_name` | `insights-deployment` | Agent deployment name |
| `agent_name` | `insights-agent` | Registered agent name |

## Deploy

```bash
tofu -chdir=infra/environments/dev init
tofu -chdir=infra/environments/dev apply
```

Remote state is stored in Azure Storage (`foundry-agent-tfstate` RG, `tfstatefoundryagent` account, `tfstate` container, key `dev.terraform.tfstate`).
