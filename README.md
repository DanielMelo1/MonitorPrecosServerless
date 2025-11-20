# Monitor de Preços Serverless

Sistema de monitoramento de preços de produtos utilizando arquitetura Serverless na AWS.

## 🏗️ Arquitetura
```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   GitHub    │ ──► │  CodePipeline │ ──► │   CodeBuild     │
└─────────────┘     └──────────────┘     └─────────────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────┐
│                      AWS SAM Deploy                         │
└─────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   Lambda    │   │   Lambda    │   │   Lambda    │
│  Coleta     │   │ Processamento│   │   API      │
└─────────────┘   └─────────────┘   └─────────────┘
         │                 │                 │
         └────────┬────────┘                 │
                  ▼                          │
         ┌─────────────┐                     │
         │Step Functions│                    │
         └─────────────┘                     │
                  │                          │
                  ▼                          ▼
         ┌─────────────────────────────────────┐
         │            DynamoDB                 │
         │  ┌───────────┐  ┌───────────────┐  │
         │  │ Produtos  │  │  Histórico    │  │
         │  └───────────┘  └───────────────┘  │
         └─────────────────────────────────────┘
                          │
                          ▼
                  ┌─────────────┐
                  │ API Gateway │
                  └─────────────┘
```

## 🚀 Tecnologias Utilizadas

- **AWS SAM** - Infraestrutura como Código (IaC)
- **AWS Lambda** - Funções serverless (Python 3.12)
- **Amazon DynamoDB** - Banco de dados NoSQL
- **AWS Step Functions** - Orquestração de workflows
- **Amazon API Gateway** - Exposição da API REST
- **Terraform** - IaC para CI/CD
- **AWS CodePipeline** - Pipeline de CI/CD
- **AWS CodeBuild** - Build automatizado

## 📁 Estrutura do Projeto
```
MonitorPrecosServerless/
├── src/
│   ├── collect_data/
│   │   └── app.py          # Lambda de coleta de preços
│   ├── process_data/
│   │   └── app.py          # Lambda de processamento
│   └── api_query/
│       └── app.py          # Lambda de consulta API
├── ci-cd/
│   ├── main.tf             # Terraform para CI/CD
│   ├── variables.tf        # Variáveis do Terraform
│   └── buildspec.yml       # Especificação do CodeBuild
├── template.yaml           # Template AWS SAM
├── samconfig.toml          # Configuração do SAM
└── README.md
```

## 🔧 Pré-requisitos

- AWS CLI configurado
- AWS SAM CLI
- Docker (para build local)
- Terraform (para CI/CD)
- Python 3.12

## 🚀 Como Executar

### 1. Clone o repositório
```bash
git clone https://github.com/DanielMelo1/MonitorPrecosServerless.git
cd MonitorPrecosServerless
```

### 2. Build da aplicação
```bash
sam build --use-container
```

### 3. Deploy para AWS
```bash
sam deploy --guided
```

### 4. Testar a aplicação

Após o deploy, acesse o Step Functions no console AWS e inicie uma execução.

### 5. Consultar via API
```bash
curl https://{api-id}.execute-api.us-east-1.amazonaws.com/Prod/produtos/PROD-12345
```

## 📊 Funcionalidades

- **Coleta de Preços**: Simula a coleta de preços de produtos
- **Processamento**: Verifica mudanças e atualiza histórico
- **Histórico**: Mantém registro de todas as alterações de preço
- **API REST**: Consulta preços atuais e histórico via HTTP GET
- **Orquestração**: Step Functions coordena o fluxo de coleta e processamento

## 🔄 CI/CD Pipeline

O projeto inclui configuração completa de CI/CD usando Terraform:
```bash
cd ci-cd
terraform init
terraform apply -var="github_owner=SEU_USUARIO" -var="github_repo=MonitorPrecosServerless" -var="github_token=SEU_TOKEN"
```

## 📝 Exemplo de Resposta da API
```json
{
  "produtoAtual": {
    "lastKnownPrice": 91.07,
    "productId": "PROD-12345",
    "updatedAt": "2025-11-20T01:47:31.356901"
  },
  "historico": [
    {
      "newPrice": 91.07,
      "oldPrice": 0.0,
      "historyId": "e1d2feac-bae9-4651-bd38-b004faac1ae9",
      "productId": "PROD-12345",
      "timestamp": "2025-11-20T01:47:31.436544"
    }
  ]
}
```

## 🧹 Limpeza dos Recursos

Para deletar todos os recursos criados:
```bash
# Deletar CI/CD
cd ci-cd
terraform destroy

# Deletar aplicação
cd ..
sam delete --stack-name PriceMonitorStack
```

## 👤 Autor

**Daniel Melo**

- GitHub: [@DanielMelo1](https://github.com/DanielMelo1)
- LinkedIn: [Daniel Melo](https://www.linkedin.com/in/danielaugustormelo/)

## 📄 Licença

Este projeto está sob a licença MIT.