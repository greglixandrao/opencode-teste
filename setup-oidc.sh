#!/bin/bash

set -e

PROFILE="AdministratorAccess-689513261716"
REGION="us-west-2"

echo "Criando OIDC Provider e Role IAM para GitHub Actions..."

GITHUB_URL="https://token.actions.githubusercontent.com"

GITHUB_THUMBPRINT=$(openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443 </dev/null 2>/dev/null | openssl x509 -fingerprint -noout | sed 's/://g' | sed 's/SHA1 Fingerprint=//')

echo "Thumbprint do GitHub OIDC: $GITHUB_THUMBPRINT"

OIDC_PROVIDER_ARN=$(aws --profile $PROFILE iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, \`token.actions.githubusercontent.com\`)].Arn" --output text)

if [ -z "$OIDC_PROVIDER_ARN" ]; then
    echo "Criando OIDC Provider do GitHub..."
    OIDC_PROVIDER_ARN=$(aws --profile $PROFILE iam create-open-id-connect-provider \
        --url $GITHUB_URL \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list $GITHUB_THUMBPRINT \
        --query "OpenIDConnectProviderArn" \
        --output text)
    echo "OIDC Provider criado: $OIDC_PROVIDER_ARN"
else
    echo "OIDC Provider já existe: $OIDC_PROVIDER_ARN"
fi

ACCOUNT_ID=$(aws --profile $PROFILE sts get-caller-identity --query Account --output text)

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:*:*"
        }
      }
    }
  ]
}
EOF
)

echo "Criando IAM Role para GitHub Actions..."
ROLE_ARN=$(aws --profile $PROFILE iam create-role \
    --role-name github-actions-role \
    --assume-role-policy-document "$TRUST_POLICY" \
    --query "Role.Arn" \
    --output text)

echo "IAM Role criada: $ROLE_ARN"

echo "Anexando policy PowerUserAccess à role..."
aws --profile $PROFILE iam attach-role-policy \
    --role-name github-actions-role \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

echo ""
echo "=========================================="
echo "Configuração concluída com sucesso!"
echo "=========================================="
echo ""
echo "OIDC Provider ARN: $OIDC_PROVIDER_ARN"
echo "IAM Role ARN: $ROLE_ARN"
echo ""
echo "Configure o seguinte secret no GitHub:"
echo "  AWS_ROLE_ARN: $ROLE_ARN"
echo ""
echo "Opcionalmente, você pode restringir o acesso editando a trust policy da role:"
echo "  aws --profile $PROFILE iam update-assume-role-policy \\"
echo "    --role-name github-actions-role \\"
echo "    --policy-document '...'"
echo ""
