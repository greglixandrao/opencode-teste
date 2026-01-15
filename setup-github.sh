#!/bin/bash

set -e

echo "Iniciando setup do repositório Git e GitHub..."

AWS_ROLE_ARN="arn:aws:iam::689513261716:role/github-actions-role"

if [ ! -d .git ]; then
    echo "Inicializando repositório Git local..."
    git init
    git add .
    git commit -m "Initial commit - FastAPI app with ECS deployment"
    echo "Repositório Git local inicializado!"
else
    echo "Repositório Git já existe."
fi

echo ""
echo "Criando repositório no GitHub..."
REPO_NAME=$(basename $(pwd))
gh repo create $REPO_NAME --public --source=. --remote=origin --push

echo ""
echo "Configurando secret AWS_ROLE_ARN no repositório..."
gh secret set AWS_ROLE_ARN --body "$AWS_ROLE_ARN"

echo ""
echo "=========================================="
echo "Repositório configurado com sucesso!"
echo "=========================================="
echo ""
echo "Repositório: $REPO_NAME"
echo "URL: $(gh repo view --json url -q .url)"
echo ""
echo "Secrets configurados:"
echo "  ✓ AWS_ROLE_ARN"
echo ""
echo "Próximos passos:"
echo "1. Configure DOCKER_HUB_USERNAME: gh secret set DOCKER_HUB_USERNAME"
echo "2. Configure DOCKER_HUB_TOKEN: gh secret set DOCKER_HUB_TOKEN"
echo "3. Execute o Terraform para criar a infraestrutura ECS"
echo ""
