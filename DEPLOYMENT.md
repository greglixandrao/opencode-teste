# Deployment Guide - Troubleshooting

Guia de troubleshooting para deployment da aplicação FastAPI em AWS ECS.

## Workflow Falhou - GitHub Actions

### Erro: "No value for required variable"
```
Error: No value for required variable
```
**Causa:** Variáveis não foram passadas ao comando Terraform.
**Solução:**
```bash
export TF_VAR_github_repository=seu-usuario/seu-repo
export TF_VAR_docker_hub_username=seu-usuario
terraform apply -auto-approve
```

### Erro: "AccessDeniedException when calling RegisterTaskDefinition"
```
User is not authorized to perform: iam:PassRole on resource
```
**Causa:** Role GitHub Actions não tem permissão para assumir roles ECS.
**Solução:** Verifique se a policy `github-actions-pass-role` existe:
```bash
aws --profile seu-profile iam get-role-policy \
  --role-name github-actions-role \
  --policy-name github-actions-pass-role
```

### Erro: "EntityAlreadyExists: Role with name already exists"
```
Error: creating IAM Role: Role with name github-actions-role already exists
```
**Causa:** Role foi criada manualmente pelo script `setup-oidc.sh`.
**Solução 1:** Importar para Terraform:
```bash
cd terraform
terraform import aws_iam_role.github_actions github-actions-role
```

**Solução 2:** Remover role manualmente e recriar via Terraform:
```bash
aws --profile seu-profile iam delete-role --role-name github-actions-role
terraform apply
```

### Erro: "MalformedPolicyDocument: Trust policy must evaluate"
```
Error: Trust policy must evaluate, using StringEquals, StringLike or StringEqualsIgnoreCase
```
**Causa:** OIDC provider URL incorreto ou condition ausente.
**Solução:** Verifique `terraform/main.tf`:
```hcl
condition {
  test     = "StringEquals"
  variable = "token.actions.githubusercontent.com:aud"
  values   = ["sts.amazonaws.com"]
}

condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"
  values   = ["repo:seu-usuario/seu-repo:ref:refs/heads/main"]
}
```

## Aplicação Não Responde

### Verificar status das tasks ECS
```bash
aws --profile seu-profile ecs list-tasks \
  --cluster fastapi-cluster \
  --service-name fastapi-service \
  --region us-west-2
```

### Verificar logs das tasks
```bash
aws --profile seu-profile logs tail /ecs/fastapi-app \
  --region us-west-2 \
  --follow
```

### Verificar eventos do serviço ECS
```bash
aws --profile seu-profile ecs describe-services \
  --cluster fastapi-cluster \
  --services fastapi-service \
  --region us-west-2 \
  --query 'services[0].events'
```

### Verificar health checks do ALB
```bash
aws --profile seu-profile describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:REGION:ACCOUNT:targetgroup/NAME/ID \
  --region us-west-2
```

## Aplicação Retorna Erro 5xx

### Erro 503 Service Unavailable
**Causa:** Tasks ECS não estão rodando ou health check falhando.
**Soluções:**
1. Verificar se tasks estão rodando:
```bash
aws --profile seu-profile ecs list-tasks --cluster fastapi-cluster
```

2. Verificar se imagem Docker Hub é pública:
```bash
curl https://hub.docker.com/v2/repositories/seu-usuario/fastapi-app/tags/
```

3. Testar health check localmente:
```bash
curl http://localhost:8000/health
```

4. Ajustar configuração de health check no Terraform:
```hcl
health_check {
  enabled             = true
  healthy_threshold   = 2
  interval            = 30
  path                = "/health"
  matcher             = "200"
  timeout             = 5
  unhealthy_threshold = 2
}
```

## Issues de OIDC

### OIDC Provider já existe
```
Error: Provider with url already exists
```
**Causa:** Provider foi criado manualmente pelo script `setup-oidc.sh`.
**Solução:** Remover do Terraform, usar o existente:
```bash
# Adicione data source para OIDC provider existente
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
```

### Trust condition não aceita repositório específico
**Causa:** Formato incorreto do `sub` condition.
**Solução:** Use `StringLike` em vez de `StringEquals`:
```hcl
condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"
  values   = ["repo:seu-usuario/seu-repo:ref:refs/heads/*"]
}
```

## Issues de Docker

### Build falha no GitHub Actions
**Causa:** Dockerfile inválido ou dependências ausentes.
**Solução:** Testar build localmente:
```bash
docker build -t test-image .
docker run -p 8000:8000 test-image
curl http://localhost:8000/health
```

### Pull image falha em ECS
**Causa:** Imagem não existe ou credenciais erradas.
**Solução:** Verificar Docker Hub:
```bash
docker login -u seu-usuario
docker pull seu-usuario/fastapi-app:latest
```

## Issues de Networking

### ALB não acessível
**Verificações:**
1. Security Group do ALB permite tráfego HTTP (porta 80)
```bash
aws --profile seu-profile ec2 describe-security-groups \
  --group-ids sg-ALB-ID \
  --query 'SecurityGroups[0].IpPermissions'
```

2. Security Group do ECS permite tráfego do ALB
3. Route table tem rota para Internet Gateway

### Tasks ECS não tem acesso à internet
**Causa:** Tasks Fargate sem IP público ou security group bloqueando saída.
**Solução:** Verifique configuração de network no Terraform:
```hcl
network_configuration {
  subnets          = aws_subnet.public[*].id
  security_groups  = [aws_security_group.ecs.id]
  assign_public_ip = true
}
```

## Debugging Avançado

### Habilitar execute command em ECS
1. Adicione ao task definition:
```hcl
enable_execute_command = true
```

2. Execute comando na task:
```bash
aws --profile seu-profile ecs execute-command \
  --cluster fastapi-cluster \
  --task ID \
  --container fastapi-app \
  --command "/bin/sh" \
  --interactive
```

### Verificar CloudWatch Logs em tempo real
```bash
aws --profile seu-profile logs tail /ecs/fastapi-app \
  --region us-west-2 \
  --follow \
  --format short
```

### Recriar deployment do zero
```bash
# 1. Destruir infraestrutura
cd terraform
terraform destroy -auto-approve

# 2. Remover role manualmente se necessário
aws --profile seu-profile iam delete-role --role-name github-actions-role

# 3. Recriar do zero
./setup-oidc.sh
terraform init
terraform plan -var="github_repository=seu-usuario/seu-repo" -var="docker_hub_username=seu-usuario"
terraform apply -auto-approve -var="github_repository=seu-usuario/seu-repo" -var="docker_hub_username=seu-usuario"
```

## Monitoramento

### Adicionar alarmes do CloudWatch
```bash
# CPU Utilization > 80%
aws --profile seu-profile cloudwatch put-metric-alarm \
  --alarm-name ecs-cpu-high \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Unhealthy Host Count > 0
aws --profile seu-profile cloudwatch put-metric-alarm \
  --alarm-name ecs-unhealthy \
  --metric-name UnhealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 60 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold
```

## Recursos Úteis

- [ECS Troubleshooting Guide](https://docs.aws.amazon.com/AmazonECS/latest/userguide/troubleshooting.html)
- [ALB Troubleshooting Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/troubleshooting-elb.html)
- [GitHub Actions Debug Logging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
- [Docker Hub Docs](https://docs.docker.com/)
