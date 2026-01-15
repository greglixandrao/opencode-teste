# FastAPI App - ECS Deployment

Aplicação FastAPI simples com deployment em AWS ECS usando Terraform e CI/CD com GitHub Actions.

## Estrutura do Projeto

- `main.py` - Aplicação FastAPI
- `Dockerfile` - Imagem Docker
- `requirements.txt` - Dependências Python
- `.github/workflows/deploy.yml` - Workflow GitHub Actions
- `terraform/` - Código Terraform para infraestrutura AWS

## Aplicação FastAPI

A aplicação possui dois endpoints:
- `GET /` - Retorna "Hello World!"
- `GET /health` - Health check

## Inicializar Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Configurar OIDC no Terraform

Execute o Terraform com as variáveis obrigatórias:
```bash
cd terraform
terraform init
terraform plan -var="github_repository=seu-usuario/seu-repo" -var="docker_hub_username=seu-usuario-dockerhub"
terraform apply -var="github_repository=seu-usuario/seu-repo" -var="docker_hub_username=seu-usuario-dockerhub"
```

Copie o valor do output `github_actions_role_arn` para usar no próximo passo.

## Configurar OIDC na AWS

Execute o script para criar o OIDC Provider e a IAM Role:
```bash
./setup-oidc.sh
```

O script irá criar:
- OIDC Provider do GitHub na AWS
- IAM Role `github-actions-role` com policy PowerUserAccess

Copie o ARN da role gerada para usar nos secrets do GitHub.

## Inicializar Terraform

```bash
cd terraform
terraform init
terraform plan -var="github_repository=seu-usuario/seu-repo" -var="docker_hub_username=seu-usuario-dockerhub"
terraform apply -var="github_repository=seu-usuario/seu-repo" -var="docker_hub_username=seu-usuario-dockerhub"
```

## Variáveis de Ambiente GitHub Actions

Configure os seguintes secrets no seu repositório GitHub:
- `AWS_ROLE_ARN` - ARN da role do OIDC (output do script setup-oidc.sh)
- `DOCKER_HUB_USERNAME` - Seu username do Docker Hub
- `DOCKER_HUB_TOKEN` - Token de acesso do Docker Hub

## Deploy

Ao fazer push para a branch `main`, o GitHub Actions irá:
1. Buildar a imagem Docker
2. Fazer push para Docker Hub
3. Atualizar o serviço ECS usando autenticação OIDC com AWS

## Acessar a Aplicação

Após o deploy, acesse a aplicação através do DNS do Application Load Balancer:
```
http://<ALB-DNS-NAME>
```

## Outputs Terraform

- `alb_dns_name` - DNS do Application Load Balancer
- `github_actions_role_arn` - ARN da role IAM para GitHub Actions OIDC
- `ecs_cluster_name` - Nome do cluster ECS
- `ecs_service_name` - Nome do serviço ECS
