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
- **Frontend**: Aplicativo mobile (e desktop) desenvolvido em Flutter, com banco de dados SQLite local para cache e visualizações gráficas da produção.

---

## Funcionalidades

- **Dashboard inteligente** com resumo da produção e gráficos de evolução (fl_chart)
- **Gestão do rebanho** — cadastro, edição e listagem de animais
- **Registro de produção** — lançamento diário de produção de leite por animal
- **Controle financeiro** — registro de despesas operacionais
- **Lembretes de manejo** — vacinas, consultas e tarefas agendadas
- **Autenticação de usuários** — cadastro e login
- **Relatórios detalhados** com drill-down por animal

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
| sqflite           | 2.3.0      |
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
│  ┌─────────┐   ┌──────────────────┐ │
│  │ SQLite  │   │   HTTP Client    │ │
│  │ (local) │   │  (api_service)   │ │
│  └─────────┘   └────────┬─────────┘ │
└───────────────────────┬─┴───────────┘
                        │ REST (HTTP/JSON)
                        ▼
┌─────────────────────────────────────┐
│        Spring Boot API (8080)       │
│                                     │
│  Controllers → Services → Repos     │
│                                     │
│  ┌──────────────────────────────┐   │
│  │         PostgreSQL           │   │
│  │       (localhost:5432)       │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## Pré-requisitos

### Gerais

- [Git](https://git-scm.com/)

### Backend

- [Java 17 (JDK)](https://adoptium.net/)
- [Maven 3.x](https://maven.apache.org/) ou use o wrapper `mvnw` incluso
- [PostgreSQL 12+](https://www.postgresql.org/download/)

### Frontend

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio / Xcode (para emuladores) **ou** dispositivo físico conectado

Verifique as instalações:

```bash
# Java
java -version

# Maven
mvn -version

# Flutter
flutter doctor
```

---

## Configuração do Ambiente

### Banco de Dados (PostgreSQL)

1. Inicie o PostgreSQL e acesse o cliente `psql`:

```sql
-- Crie o banco de dados (se não existir)
CREATE DATABASE postgres;

-- Crie o usuário (se necessário)
CREATE USER postgres WITH PASSWORD 'sua_senha';
GRANT ALL PRIVILEGES ON DATABASE postgres TO postgres;
```

2. Edite o arquivo `backend/src/main/resources/application.properties` com suas credenciais:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/postgres
spring.datasource.username=postgres
spring.datasource.password=sua_senha
```

> **Atenção:** nunca suba credenciais reais para o repositório. Utilize variáveis de ambiente em produção.

### Variáveis de Ambiente (opcional — produção)

Para sobrescrever as propriedades sem editar o arquivo:

```bash
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/postgres
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=sua_senha
```

---

## Backend — Spring Boot

### Instalar dependências e compilar

```bash
cd backend

# Com Maven instalado globalmente
mvn clean install

# Ou com o wrapper do projeto (não requer Maven global)
./mvnw clean install       # Linux / macOS
mvnw.cmd clean install     # Windows
```

### Iniciar o servidor

```bash
# Com Maven
mvn spring-boot:run

# Com o wrapper
./mvnw spring-boot:run       # Linux / macOS
mvnw.cmd spring-boot:run     # Windows
```

O servidor estará disponível em: `http://localhost:8080`

### Gerar o JAR e executar

```bash
mvn clean package
java -jar target/leiteira-0.0.1-SNAPSHOT.jar
```

### Executar testes

```bash
mvn test
```

---

## Frontend — Flutter

### Instalar dependências

```bash
cd frontend
flutter pub get
```

### Verificar dispositivos disponíveis

```bash
flutter devices
```

### Iniciar o aplicativo

```bash
# Dispositivo/emulador padrão
flutter run

# Plataforma específica
flutter run -d android
flutter run -d ios
flutter run -d windows
flutter run -d chrome          # Web
```

### Build para produção

```bash
# Android (APK)
flutter build apk --release

# Android (App Bundle para Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# Web
flutter build web --release
```

### Executar testes

```bash
flutter test
```

---

## Estrutura do Projeto

```
AppGestaoLeiteira/
│
├── backend/                          # API Spring Boot
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/gestao/leiteira/
│   │   │   │   ├── LeiteiraApplication.java     # Entry point
│   │   │   │   ├── controller/                  # REST controllers
│   │   │   │   │   ├── AnimalController.java
│   │   │   │   │   ├── ProductionController.java
│   │   │   │   │   ├── ExpenseController.java
│   │   │   │   │   ├── ReminderController.java
│   │   │   │   │   └── UserController.java
│   │   │   │   ├── model/                       # Entidades JPA
│   │   │   │   │   ├── Animal.java
│   │   │   │   │   ├── Production.java
│   │   │   │   │   ├── Expense.java
│   │   │   │   │   ├── Reminder.java
│   │   │   │   │   └── User.java
│   │   │   │   ├── repository/                  # Spring Data JPA
│   │   │   │   │   ├── AnimalRepository.java
│   │   │   │   │   ├── ProductionRepository.java
│   │   │   │   │   ├── ExpenseRepository.java
│   │   │   │   │   ├── ReminderRepository.java
│   │   │   │   │   └── UserRepository.java
│   │   │   │   └── service/                     # Regras de negócio
│   │   │   └── resources/
│   │   │       └── application.properties       # Configurações
│   │   └── test/                                # Testes unitários
│   └── pom.xml                                  # Dependências Maven
│
└── frontend/                         # App Flutter
    ├── lib/
    │   ├── main.dart                            # Entry point & rotas
    │   ├── models/
    │   │   └── models.dart                      # Data models
    │   ├── services/
    │   │   ├── api_service.dart                 # Comunicação HTTP
    │   │   └── database_service.dart            # SQLite local
    │   └── views/                               # Telas do app
    │       ├── dashboard_view.dart
    │       ├── login_view.dart
    │       ├── signup_view.dart
    │       ├── animal_list_view.dart
    │       ├── animal_form_view.dart
    │       ├── animal_detail_view.dart
    │       ├── production_list_view.dart
    │       ├── production_form_view.dart
    │       ├── expense_list_view.dart
    │       ├── expense_form_view.dart
    │       ├── reminder_list_view.dart
    │       └── reminder_form_view.dart
    ├── pubspec.yaml                             # Dependências Flutter
    └── analysis_options.yaml                    # Configuração do linter
```

---

## Endpoints da API

Base URL: `http://localhost:8080`

### Usuários

| Método | Rota               | Descrição              |
|--------|--------------------|------------------------|
| POST   | `/users`           | Cadastrar usuário      |
| POST   | `/users/login`     | Autenticar usuário     |
| GET    | `/users/{id}`      | Buscar usuário por ID  |

### Animais

| Método | Rota               | Descrição              |
|--------|--------------------|------------------------|
| GET    | `/animals`         | Listar animais         |
| POST   | `/animals`         | Cadastrar animal       |
| GET    | `/animals/{id}`    | Buscar animal por ID   |
| PUT    | `/animals/{id}`    | Atualizar animal       |
| DELETE | `/animals/{id}`    | Remover animal         |

### Produção

| Método | Rota                  | Descrição                     |
|--------|-----------------------|-------------------------------|
| GET    | `/productions`        | Listar registros de produção  |
| POST   | `/productions`        | Registrar produção            |
| GET    | `/productions/{id}`   | Buscar registro por ID        |
| PUT    | `/productions/{id}`   | Atualizar registro            |
| DELETE | `/productions/{id}`   | Remover registro              |

### Despesas

| Método | Rota               | Descrição              |
|--------|--------------------|------------------------|
| GET    | `/expenses`        | Listar despesas        |
| POST   | `/expenses`        | Cadastrar despesa      |
| GET    | `/expenses/{id}`   | Buscar despesa por ID  |
| PUT    | `/expenses/{id}`   | Atualizar despesa      |
| DELETE | `/expenses/{id}`   | Remover despesa        |

### Lembretes

| Método | Rota               | Descrição              |
|--------|--------------------|------------------------|
| GET    | `/reminders`       | Listar lembretes       |
| POST   | `/reminders`       | Criar lembrete         |
| GET    | `/reminders/{id}`  | Buscar lembrete por ID |
| PUT    | `/reminders/{id}`  | Atualizar lembrete     |
| DELETE | `/reminders/{id}`  | Remover lembrete       |

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
