# AppGestaoLeiteira

Sistema de gestão para produção leiteira voltado a agricultores familiares. Permite o controle de animais, registro diário de produção de leite, controle financeiro e lembretes de manejo/saúde do rebanho.

---

## Sumário

- [Visão Geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Backend — Spring Boot](#backend--spring-boot)
- [Frontend — Flutter](#frontend--flutter)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Endpoints da API](#endpoints-da-api)
- [Banco de Dados](#banco-de-dados)
- [Contribuindo](#contribuindo)

---

## Visão Geral

O **AppGestaoLeiteira** é composto por:

- **Backend**: API REST desenvolvida com Spring Boot (Java 17), responsável por persistir os dados no PostgreSQL e expor os endpoints consumidos pelo app.
- **Frontend**: Aplicativo mobile (e desktop) desenvolvido em Flutter, que consome a API REST e exibe visualizações gráficas da produção.

---

## Funcionalidades

- **Dashboard inteligente** com resumo da produção e gráficos de evolução (fl_chart)
- **Gestão do rebanho** — cadastro, edição, ficha completa por animal e status (Ativo, Lactação, Seco, Vendido, Morto)
- **Registro de produção** — lançamento diário de produção de leite por animal
- **Controle financeiro** — registro e edição de despesas operacionais
- **Saúde & tratamentos** — doenças, exames, cirurgias e vermifugação, com custo
- **Vacinação** — calendário de vacinas e próximas doses
- **Reprodução** — cio, cobertura, inseminação, diagnóstico de gestação e parto
- **Estoque** — ração, medicamentos e insumos, com alerta de estoque baixo
- **Agenda de manejo** — lembretes com marcação de concluído
- **Usuários** — cadastro, login e perfis ADMIN / OPERADOR

### Regras automáticas (backend)

| Evento | Efeito |
|--------|--------|
| Registro de saúde com custo > 0 | Gera uma despesa (categoria *Veterinário*) que acompanha o custo; zerar o custo ou excluir o registro remove a despesa. A despesa só pode ser alterada pelo registro de saúde. |
| Vacina com próxima dose | Cria um lembrete na Agenda para a data; alterar/remover a próxima dose atualiza/remove o lembrete. |
| Reprodução do tipo *Parto* | Muda o status do animal para *Lactação* (exceto Vendido/Morto). |
| Exclusão de animal com histórico | Bloqueada (409) para preservar o histórico — use o status Vendido/Morto. |
| Cadastro público (`/signup`) | Cria sempre OPERADOR; o primeiro usuário do sistema vira ADMIN. O último ADMIN ativo não pode ser excluído, desativado ou rebaixado. |

---

## Tecnologias

### Backend

| Tecnologia        | Versão     |
|-------------------|------------|
| Java              | 17         |
| Spring Boot       | 3.2.5      |
| Spring Data JPA   | —          |
| Hibernate         | (via JPA)  |
| PostgreSQL        | 12+        |
| Maven             | 3.x        |

### Frontend

| Tecnologia        | Versão     |
|-------------------|------------|
| Flutter           | Stable     |
| Dart              | >= 3.0.0   |
| fl_chart          | 0.70.0     |
| http              | 1.6.0      |
| intl              | 0.19.0     |

---

## Arquitetura

```
┌─────────────────────────────────────┐
│           Flutter App               │
│  (Android / iOS / Windows / Web)    │
│                                     │
│   views → ApiService (HTTP/JSON)    │
└──────────────────┬──────────────────┘
                   │ REST /api/**
                   ▼
┌─────────────────────────────────────┐
│        Spring Boot API (8080)       │
│                                     │
│  Controllers → Services → Repos     │
│  (regras de negócio e validação     │
│   ficam nos services)               │
│                                     │
│  ┌──────────────────────────────┐   │
│  │         PostgreSQL           │   │
│  │       (localhost:5432)       │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

Erros da API seguem o formato `{"timestamp": ..., "status": 409, "message": "..."}`; o app exibe a `message` ao usuário.

---

## Pré-requisitos

### Gerais

- [Git](https://git-scm.com/)

### Backend

- [Java 17 (JDK)](https://adoptium.net/)
- [Maven 3.x](https://maven.apache.org/) (o projeto não inclui o wrapper `mvnw`; também é possível rodar pela IDE)
- [PostgreSQL 12+](https://www.postgresql.org/download/)

### Frontend

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio / Xcode (para emuladores) **ou** dispositivo físico conectado

---

## Configuração do Ambiente

### Banco de Dados

1. Monte o banco `gestao_leiteira` executando os scripts de [`database/`](database/) em ordem (detalhes em [Banco de Dados](#banco-de-dados)).
2. Informe a senha do PostgreSQL em `backend/src/main/resources/application-local.properties` (arquivo fora do git):

```properties
spring.datasource.password=sua_senha
```

Ou use variáveis de ambiente: `DB_URL` (padrão `jdbc:postgresql://localhost:5432/gestao_leiteira`), `DB_USERNAME` e `DB_PASSWORD`.

> O backend **não cria nem altera tabelas**: o Hibernate roda em `ddl-auto=validate` e o backend não sobe se as entidades não baterem com o banco.

---

## Backend — Spring Boot

```bash
cd backend
mvn clean install        # compilar
mvn spring-boot:run      # iniciar (http://localhost:8080)
mvn test                 # testes
```

Ou execute `LeiteiraApplication` pela IDE.

---

## Frontend — Flutter

```bash
cd frontend
flutter pub get
flutter run                 # dispositivo/emulador padrão
flutter run -d windows      # ou chrome, android, ios...
```

### URL da API

Por padrão o app usa `http://10.0.2.2:8080/api` no emulador Android (aponta para o PC) e `http://localhost:8080/api` nas demais plataformas. Para um celular físico ou outro servidor:

```bash
flutter run --dart-define=API_URL=http://192.168.0.10:8080/api
```

### Testes

```bash
flutter test                                   # testes unitários
# teste de integração contra um backend real (use um banco de testes):
flutter test test/api_contract_test.dart --dart-define=API_URL=http://localhost:8080/api
```

---

## Estrutura do Projeto

```
AppGestaoLeiteira/
├── backend/                                   # API Spring Boot
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/gestao/leiteira/
│       │   ├── LeiteiraApplication.java       # Entry point
│       │   ├── config/WebConfig.java          # CORS
│       │   ├── controller/                    # Endpoints REST (finos)
│       │   ├── service/                       # Regras de negócio e validações
│       │   ├── repository/                    # Spring Data JPA
│       │   ├── model/                         # Entidades JPA
│       │   ├── exception/                     # ApiException + handler global
│       │   └── security/PasswordHasher.java   # Hash de senhas (PBKDF2)
│       └── resources/application.properties
│
└── frontend/                                  # App Flutter
    ├── lib/
    │   ├── main.dart                          # Entry point & navegação
    │   ├── models/models.dart                 # Models + (de)serialização da API
    │   ├── services/api_service.dart          # Cliente HTTP da API
    │   ├── theme/app_theme.dart               # Tema e widgets compartilhados
    │   └── views/                             # Telas (lista + formulário por módulo)
    └── test/
```

---

## Endpoints da API

Base URL: `http://localhost:8080/api`

Todos os módulos abaixo têm `GET /`, `GET /{id}`, `POST /`, `PUT /{id}` e `DELETE /{id}`.

| Módulo | Rota base | Rotas extras |
|--------|-----------|--------------|
| Animais | `/animals` | — |
| Produção | `/production` | `GET /animal/{animalId}` |
| Despesas | `/expenses` | — |
| Lembretes | `/reminders` | `PATCH /{id}/status?concluido=true` |
| Saúde | `/health` | `GET /animal/{animalId}` |
| Vacinas | `/vaccines` | `GET /animal/{animalId}` |
| Reprodução | `/reproduction` | `GET /animal/{animalId}` |
| Estoque | `/stock` | `PATCH /{id}/quantidade?delta=-5` |
| Usuários | `/users` | `POST /signup`, `POST /login` |

Registros ligados a animais referenciam o animal assim: `{"animal": {"id": 1}, ...}`. Datas usam ISO 8601 (`2026-10-26T00:00:00.000`).

---

## Banco de Dados

### Montando o banco (DBeaver ou psql)

Execute os scripts de [`database/`](database/) em ordem:

| Script | Conectado em | O que faz |
|--------|--------------|-----------|
| `00_criar_banco.sql` | `postgres` (auto-commit ligado) | Cria o banco `gestao_leiteira` |
| `01_schema.sql` | `gestao_leiteira` | Cria as 9 tabelas, constraints e índices (em transação) |
| `02_migrar_dados.sql` | `gestao_leiteira` | *(Opcional)* Copia os dados do banco antigo `postgres` via `dblink` — troque `SUA_SENHA` antes e não salve |
| `03_validacao.sql` | `gestao_leiteira` | Consultas de conferência (somente leitura) |
| `04_limpeza_banco_antigo.sql` | `postgres` | *(Opcional, comentado)* Remove as tabelas antigas depois de validar |
| `dados_teste.sql` | `gestao_leiteira` | *(Testes)* **Apaga** animais, produção, financeiro, saúde, vacinas, reprodução, agenda e estoque e recria um cenário completo de fazenda. Mantém os usuários e cria `maria` (ADMIN), `joao` e `carlos` (inativo), todos com senha `1234`. Pode ser reexecutado. |

### Tabelas

```
users           — id, username, password (hash), nome_completo, email, telefone, role, ativo
animals         — id, nome, idade, raca, numero_brinco, sexo, peso, data_nascimento, status
production      — id, animal_id → animals, data, quantidade
expenses        — id, descricao, valor, data, categoria, origem ('SAUDE' = automática)
reminders       — id, titulo, descricao, data, concluido, origem ('VACINA' = automático)
health_records  — id, animal_id → animals, tipo, descricao, ..., custo, status, expense_id → expenses
vaccines        — id, animal_id → animals, nome, data_aplicacao, proxima_dose, ..., reminder_id → reminders
reproductions   — id, animal_id → animals, tipo, data, touro, previsao_parto, status, observacao
stock_items     — id, nome, categoria, quantidade, unidade, quantidade_minima, preco_unitario, validade, observacao
```

### Convenções

- IDs `BIGINT GENERATED BY DEFAULT AS IDENTITY`; textos `TEXT`; dinheiro `NUMERIC(12,2)`; quantidades `DOUBLE PRECISION`.
- Datas `TIMESTAMP` sem fuso, porque o backend usa `LocalDateTime` (data/hora local da fazenda).
- FKs para `animals` são `ON DELETE RESTRICT` (histórico preservado); os vínculos automáticos `expense_id`/`reminder_id` são `ON DELETE SET NULL`.
- Toda FK tem índice `(animal_id, data)`, que atende a ficha do animal e as listagens ordenadas.
- Status e tipos são `TEXT` sem `CHECK`, porque as opções vivem nas telas do app. Só `role` e `origem`, controlados pelo backend, têm `CHECK`.

### Alterando a estrutura

Como o Hibernate só valida, toda mudança nas entidades exige um script novo em `database/` (ex.: `05_adiciona_coluna_x.sql`), executado antes de subir o backend.

---

## Contribuindo

1. Faça um fork do repositório
2. Crie uma branch para sua feature: `git checkout -b feature/minha-feature`
3. Commit suas alterações: `git commit -m 'feat: adiciona minha feature'`
4. Push para a branch: `git push origin feature/minha-feature`
5. Abra um Pull Request

### Padrão de commits (Conventional Commits)

```
feat:     nova funcionalidade
fix:      correção de bug
docs:     alterações na documentação
style:    formatação, sem mudança de lógica
refactor: refatoração de código
test:     adição ou correção de testes
chore:    tarefas de manutenção
```

---

> Desenvolvido para apoiar agricultores familiares no controle eficiente da produção leiteira.
