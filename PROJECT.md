# FastAPI App - AWS ECS Deployment

Visão geral do projeto de deployment contínuo de aplicação FastAPI em AWS ECS usando Terraform, GitHub Actions e Docker Hub.

## Arquitetura

```
┌─────────────┐      ┌──────────────┐      ┌────────────────┐
│  GitHub     │      │ Docker Hub   │      │    AWS ECS   │
│  Actions    │─────▶│  Registry    │─────▶│   Fargate    │
│  (CI/CD)   │      │              │      │              │
└─────────────┘      └──────────────┘      └──────┬───────┘
                                                 │
                                          ┌──────▼───────┐
                                          │  ALB + Target │
                                          │     Group     │
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                           ┌─────────┐
                                           │ Internet │
                                           └─────────┘
```

## Componentes

### Aplicação
- **Framework:** FastAPI 0.115.0
- **Runtime:** Python 3.11
- **Servidor:** Uvicorn (porta 8000)
- **Endpoints:**
  - `GET /` - Retorna {"message": "Hello World!"}
  - `GET /health` - Health check para ALB

### Infraestrutura AWS
- **Região:** us-west-2 (Oregon)
- **VPC:** 10.0.0.0/16
- **Subnets:** 2 públicas (us-west-2a, us-west-2b)
- **ECS:** Fargate launch type
  - CPU: 256 unidades
  - Memory: 512 MB
  - Desired tasks: 1
- **Load Balancer:** Application Load Balancer (HTTP)
- **Logs:** CloudWatch Logs (retention: 7 dias)

### CI/CD
- **Repositório:** GitHub Actions
- **Registry:** Docker Hub (não usa Amazon ECR)
- **Autenticação:** OIDC (sem secrets estáticos)
- **Workflow:** Build, push Docker Hub, update ECS

## Estrutura do Projeto

```
opencode-teste/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD
├── terraform/
│   ├── main.tf               # Recursos AWS
│   ├── variables.tf           # Variáveis input
│   ├── outputs.tf            # Outputs úteis
│   └── terraform.tfvars      # Valores padrão (opcional)
├── main.py                  # Aplicação FastAPI
├── Dockerfile               # Definição da imagem Docker
├── requirements.txt          # Dependências Python
├── setup-oidc.sh          # Script setup OIDC AWS
├── setup-github.sh         # Script setup GitHub
├── PROJECT.md              # Este arquivo
├── DEPLOYMENT.md           # Guia de troubleshooting
└── README.md              # Documentação básica
```

## Configurações

### Variáveis de Ambiente GitHub Actions
- `AWS_ROLE_ARN` - ARN da role OIDC para autenticação
- `DOCKER_HUB_USERNAME` - Username Docker Hub
- `DOCKER_HUB_TOKEN` - Access token Docker Hub

### Variáveis Terraform
- `aws_region` - Região AWS (default: us-west-2)
- `project_name` - Nome do projeto (default: fastapi-app)
- `vpc_cidr` - CIDR block da VPC (default: 10.0.0.0/16)
- `github_repository` - Repositório GitHub (ex: owner/repo)
- `docker_hub_username` - Username Docker Hub
- `docker_image_name` - Nome da imagem (default: fastapi-app)
- `ecs_cluster_name` - Nome do cluster ECS (default: fastapi-cluster)
- `ecs_service_name` - Nome do serviço ECS (default: fastapi-service)
- `ecs_task_family` - Family da task definition (default: fastapi-task)
- `task_cpu` - CPU units (default: 256)
- `task_memory` - Memory em MB (default: 512)
- `desired_count` - Número de tasks (default: 1)

## IAM Roles

### github-actions-role
- **Uso:** Autenticação OIDC do GitHub Actions
- **Permissões:** PowerUserAccess + custom policy para iam:PassRole
- **Trust policy:** Apenas repositório específico pode assumir a role

### fastapi-app-ecs-execution-role
- **Uso:** ECS task execution
- **Permissões:** AmazonECSTaskExecutionRolePolicy
- **Trust:** ecs-tasks.amazonaws.com

### fastapi-app-ecs-task-role
- **Uso:** ECS task runtime
- **Permissões:** (customizável conforme necessário)
- **Trust:** ecs-tasks.amazonaws.com

## Workflow de Deployment

1. **Push para main** → GitHub Actions trigger
2. **Checkout** → Clone do repositório
3. **Configure AWS** → OIDC assume role
4. **Login Docker Hub** → Autenticação
5. **Build image** → Docker build com tag do commit
6. **Push Docker Hub** → Upload imagem
7. **Update task def** → Nova imagem na task definition
8. **Update service** → ECS cria nova task

## Custos Estimados (us-west-2)

- **ECS Fargate:** ~$15/mês (256 CPU, 512 MB, 24h/dia)
- **ALB:** ~$18/mês (ALB horas + LCU)
- **CloudWatch Logs:** ~$0.50/mês (7 dias retention)
- **Data Transfer:** ~$0.09/GB (para internet)

**Total estimado:** ~$34/mês (para 1 task rodando 24h)

## Próximas Melhorias

- [ ] Adicionar HTTPS com ACM Certificate
- [ ] Implementar Auto Scaling
- [ ] Adicionar staging environment
- [ ] Configurar Rollback automático
- [ ] Adicionar testes automatizados no CI
- [ ] Implementar monitoring avançado (CloudWatch Alarms)
- [ ] Adicionar WAF para segurança
- [ ] Migrar para ECR (maior integração AWS)
