# Rentcars - Senior Analytics Engineer Case

## 1. Visão geral

Este repositório contém a solução do case técnico para a vaga de Senior Analytics Engineer da Rentcars.

O projeto foi estruturado para atender aos requisitos de modelagem de dados com dbt, testes de qualidade, construção de marts analíticos e documentação técnica. Nesta etapa, o foco principal foi consolidar a base analítica com `sources`, camada de `staging`, camada `intermediate` e testes de integridade.

---

## 2. Objetivo da solução

Construir uma base analítica confiável e organizada a partir dos dados brutos de sessões, buscas, reservas, cancelamentos e parceiros, com separação clara entre camadas técnicas e analíticas.

A solução foi desenhada para:

- padronizar e limpar os dados de entrada
- deduplicar registros
- validar regras de qualidade
- preparar entidades enriquecidas para facts e dimensions
- suportar análises de conversão, receita, cancelamento e comportamento de navegação

---

## 3. Stack utilizada

- Python 3.11
- dbt-core
- dbt-duckdb
- DuckDB
- VS Code
- DBeaver

---

## 4. Dados de entrada

Os dados brutos do case foram carregados localmente via `dbt seed` e estão disponíveis no DuckDB como tabelas em `main.*`.

Datasets utilizados:

- `raw_sessions`
- `raw_searches`
- `raw_bookings`
- `raw_cancellations`
- `raw_partners`

Os datasets contêm problemas de qualidade intencionais, como:

- duplicatas
- inconsistência de capitalização
- datas logicamente inválidas
- outliers
- sessões classificadas como bot

---

## 5. Arquitetura da solução

A modelagem foi organizada em quatro camadas:

- **Raw**: dados brutos carregados via `dbt seed`
- **Staging**: cast, padronização, deduplicação e flags técnicas
- **Intermediate**: joins e enriquecimento analítico
- **Marts**: dimensões e fatos finais para consumo analítico

### Fluxo conceitual

Raw → Staging → Intermediate → Marts

---

## 6. Estrutura do projeto

```text
rentcars_case/
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── seeds/
├── tests/
│   └── generic/
├── target/
└── README.md
```

---

## 7. Como executar o projeto

### Pré-requisitos

- Python 3.11+
- ambiente virtual configurado
- dependências instaladas
- `profiles.yml` configurado para DuckDB

### Instalação das dependências

```bash
pip install dbt-core dbt-duckdb
```

### Carregamento dos dados

```bash
dbt seed
```

### Execução dos modelos

```bash
dbt run
```

### Execução dos testes

```bash
dbt test
```

---

## 8. Configuração local com DuckDB

O ambiente local utiliza DuckDB como banco analítico.

Exemplo de arquivo local:

```text
C:\Users\Muller\rentcars_case\dev.duckdb
```

### Observação importante

Se o DBeaver estiver com o arquivo `dev.duckdb` aberto, o dbt pode falhar por lock no banco. Durante a execução de `dbt run` e `dbt test`, o ideal é manter o DBeaver fechado.

---

## 9. Decisões técnicas de modelagem

### 9.1 Sources

Foi utilizado `sources.yml` para formalizar a entrada dos dados brutos no dbt, referenciando as tabelas carregadas via `dbt seed`.

### 9.2 Staging

Os modelos `stg_*` foram criados para concentrar:

- deduplicação com `row_number()`
- cast de tipos
- padronização de texto e capitalização
- limpeza básica
- criação de flags técnicas de qualidade

A camada de staging foi usada para deixar o dado consistente e previsível, sem aplicar lógica analítica pesada.

### 9.3 Intermediate

Os modelos `int_*` foram criados para centralizar joins e enriquecer entidades antes da camada final de consumo.

Modelos implementados até o momento:

- `int_bookings_enriched`
- `int_sessions_enriched`

#### `int_bookings_enriched`

Modelo no grão de uma linha por reserva, enriquecido com dados de parceiro e cancelamento. Ele prepara a base para a futura `fct_bookings`.

Principais atributos derivados:

- `has_cancellation`
- `is_valid_revenue_booking`
- `valid_revenue_amount`

#### `int_sessions_enriched`

Modelo no grão de uma linha por sessão, enriquecido com agregações de buscas e reservas por `session_id`.

Principais atributos derivados:

- `total_searches`
- `total_bookings`
- `has_search`
- `has_booking`

### 9.4 Estratégia geral

A separação entre `staging`, `intermediate` e `marts` foi adotada para manter o projeto legível, testável e aderente às boas práticas de modelagem pedidas no case.

---

## 10. Testes implementados

Foram implementados testes nativos do dbt:

- `not_null`
- `unique`
- `accepted_values`
- `relationships`

Também foram implementados testes customizados via macros próprias:

- `valid_session_timing`
- `valid_trip_dates`

Esses testes foram aplicados principalmente na camada de staging para validar integridade estrutural e regras básicas de negócio.

---

## 11. Estado atual da implementação

### Concluído

- `sources.yml`
- staging completo:
  - `stg_sessions`
  - `stg_searches`
  - `stg_bookings`
  - `stg_cancellations`
  - `stg_partners`
- testes nativos no staging
- testes customizados
- intermediate:
  - `int_bookings_enriched`
  - `int_sessions_enriched`

### Em andamento

- documentação completa da camada intermediate
- construção dos marts mínimos exigidos:
  - `dim_partners`
  - `dim_users`
  - `fct_bookings`
  - `fct_sessions`

---

## 12. Regras e remediações de qualidade já tratadas

Até esta etapa, foram tratados ou sinalizados problemas como:

- duplicatas
- inconsistência de case em colunas categóricas
- valores monetários inválidos
- flags técnicas de anomalia
- datas inválidas em buscas e reservas
- relacionamento entre entidades

Os testes foram utilizados para validar se o resultado final dos modelos respeita as regras esperadas após o tratamento.

---

## 13. Limitações atuais

Até esta etapa, o foco foi consolidar a fundação do projeto dbt com `sources`, `staging`, `intermediate` e testes.

Os seguintes componentes ainda estão em evolução:

- marts finais
- queries SQL analíticas
- dashboard
- documentação de governança
- artefatos de stakeholder discovery

---

## 14. Próximos passos

- criar `dim_partners`
- criar `dim_users`
- criar `fct_bookings`
- criar `fct_sessions`
- finalizar documentação dos marts
- consolidar queries SQL do desafio analítico
- construir dashboard e apresentação
- finalizar `governance.md`
- finalizar `roteiro_entrevista.md`, `requisitos_tecnicos.md` e `data_contract.yaml`

---

## 15. Observação final

A proposta desta solução foi priorizar uma base dbt consistente, testável e organizada, de forma a suportar com segurança as próximas etapas do case.