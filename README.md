# API Financeira

Sistema de transferências bancárias com Node.js e SQL Server. O servidor roda em http://localhost:3000

## Tecnologias

- Node.js
- Express
- SQL Server

## Como rodar o projeto via terminal (bash ou cmd)

### 1. Clone o repositório

```bash
git clone https://github.com/Victor-Rei-Dev/api-financeiro.git
cd api-financeiro
```

### 2. Instale as dependências necessárias

``` bash
npm install
```

### 3. Configure o banco de dados

Execute o script `script.sql` no SQL Server Management Studio, e o banco será criado automaticamente. É necessário ter o SQL Server 12 ou superior instalado.

### 4. Configure as variáveis de ambiente

Crie um arquivo `.env`:

```env
DB_SERVER=localhost
DB_DATABASE=Financeiro
DB_USER=node_user
DB_PASSWORD=senha123
```

Não suba o `.env` para o GitHub.

### 5. Execute o projeto

```bash
npm run dev
```

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/cadastrar` | Criar novo usuário e nova conta |
| POST | `/api/login` | Fazer login |
| POST | `/api/transferir/:id_enviador` | Realizar transferência |
| GET  | `/api/buscarUsuario/:id_usu` | Buscar usuário  |
| DELETE  | `/api/deletarUsuario/:id_usu`| Deletar usuário| 
| GET  | `/api/extrato/:id_conta` | Ver extrato da conta |
| PATCH  | `/api/depositarSaldo/:id_conta`| Depositar saldo |
| GET | `/api/buscarConta/:id_conta` | Buscar conta |
| PATCH | `/api/atualizarLimite/:id_conta` | Alterar limite de transferência da conta|
| DELETE | `/api/deletarConta/:id_conta` | Deletar conta |

## Exemplos de uso via bash

### Cadastrar usuário

```bash
curl -X POST http://localhost:3000/api/cadastrar \
  -H "Content-Type: application/json" \
  -d '{"nome":"Joao","email":"joao@email.com","senha":"123","cpf":"12345678901","tel":"11111111111"}'
```

### Fazer login

```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json"  \
  -d '{"email":"joao@email.com","senha":"123"}'
```

## Funcionalidades

-  Cadastro de usuários com hash de senha (SHA-256)
-  Login simples
-  Busca de usuários e contas
-  Transferências com controle de concorrência (UPDLOCK)
-  Limite diário de transferência, sendo o padrão R$ 5.000,00
-  Extrato com histórico e saldo antes/depois
-  As rotas de DELETE realizam desativação lógica (soft delete), e não removem os dados do banco.
