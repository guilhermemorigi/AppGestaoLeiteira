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

O schema é gerenciado pelo Hibernate (`spring.jpa.hibernate.ddl-auto=update`).

```
users           — id, username, password (hash), nome_completo, email, telefone, role, ativo
animals         — id, nome, idade, raca, numero_brinco, sexo, peso, data_nascimento, status
production      — id, animal_id, data, quantidade
expenses        — id, descricao, valor, data, categoria, origem
reminders       — id, titulo, descricao, data, concluido, origem
health_records  — id, animal_id, tipo, descricao, medicamento, veterinario, data, data_fim, custo, status, observacao, expense_id
vaccines        — id, animal_id, nome, data_aplicacao, proxima_dose, lote, veterinario, observacao, reminder_id
reproductions   — id, animal_id, tipo, data, touro, previsao_parto, status, observacao
stock_items     — id, nome, categoria, quantidade, unidade, quantidade_minima, preco_unitario, validade, observacao
```

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

O schema é gerenciado automaticamente pelo Hibernate (`spring.jpa.hibernate.ddl-auto=update`). As tabelas são criadas/atualizadas na inicialização do backend.

### Entidades principais

```
users          — id, nome, email, senha, ...
animals        — id, nome, raça, data_nascimento, user_id, ...
productions    — id, data, quantidade, animal_id, user_id, ...
expenses       — id, data, valor, descrição, categoria, user_id, ...
reminders      — id, titulo, data, descricao, concluido, user_id, ...
```

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
