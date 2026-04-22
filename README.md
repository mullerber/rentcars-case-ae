# Rentcars - Senior Analytics Engineer Case

## 1. Visão geral

Este repositório contém a solução do case técnico para a vaga de **Senior Analytics Engineer** da Rentcars.

O objetivo da solução é transformar dados brutos de sessões, buscas, reservas, cancelamentos e parceiros em uma base analítica confiável, organizada e testável, usando **dbt** como ferramenta principal de modelagem.

Ao longo do case, a solução foi estruturada para combinar fundação técnica, análise de negócio, visualização e documentação de governança.

- modelagem em camadas
- padronização e limpeza dos dados
- testes de qualidade
- criação de marts analíticos
- fatos incrementais com deduplicação explícita
- análises em SQL com resultados exportados
- dashboard executivo com storytelling
- documentação de governança e stakeholder discovery

---

## 2. Objetivo da solução

A solução foi desenhada para:

- padronizar e limpar os dados de entrada
- deduplicar registros problemáticos
- validar regras de qualidade dos dados
- organizar a modelagem em camadas com responsabilidades claras
- preparar dimensões e fatos para consumo analítico
- suportar análises de conversão, receita, cancelamento e comportamento de navegação

---

## 3. Stack utilizada

- Python 3.11
- dbt-core 1.11.8
- dbt-duckdb 1.10.1
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

Os datasets contêm problemas de qualidade propositalmente inseridos, como:

- duplicatas
- inconsistências de capitalização
- datas logicamente inválidas
- outliers
- sessões classificadas como bot
- valores monetários inválidos

---

## 5. Arquitetura da solução

A modelagem foi organizada em quatro camadas:

- **Raw**: dados brutos carregados via `dbt seed`
- **Staging**: cast, padronização, deduplicação e flags técnicas
- **Intermediate**: joins e enriquecimento analítico
- **Marts**: dimensões e fatos finais para consumo analítico

### Fluxo conceitual

Raw → Staging → Intermediate → Marts

### Diagrama ASCII do modelo

```text
raw_sessions ───────► stg_sessions ───────────────► int_sessions_enriched ───────► fct_sessions
raw_searches ───────► stg_searches ───────────────┘
raw_bookings ───────► stg_bookings ───────► int_bookings_enriched ───────────────► fct_bookings
raw_cancellations ──► stg_cancellations ──────────┘
raw_partners ───────► stg_partners ───────────────► dim_partners
stg_sessions + stg_bookings ───────────────────────────────────────────────────────► dim_users
```

---

## 6. Estrutura do projeto

```text
rentcars_case/
├── models/
│   ├── staging/
│   │   ├── sources.yml
│   │   ├── schema.yml
│   │   ├── stg_sessions.sql
│   │   ├── stg_searches.sql
│   │   ├── stg_bookings.sql
│   │   ├── stg_cancellations.sql
│   │   └── stg_partners.sql
│   ├── intermediate/
│   │   ├── schema.yml
│   │   ├── int_bookings_enriched.sql
│   │   └── int_sessions_enriched.sql
│   └── marts/
│       ├── schema.yml
│       ├── dim_partners.sql
│       ├── dim_users.sql
│       ├── fct_bookings.sql
│       └── fct_sessions.sql
├── seeds/
│   ├── raw_sessions.csv
│   ├── raw_searches.csv
│   ├── raw_bookings.csv
│   ├── raw_cancellations.csv
│   └── raw_partners.csv
├── tests/
│   └── generic/
│       ├── test_valid_session_timing.sql
│       └── test_valid_trip_dates.sql
├── sql/
│   ├── queries.sql
│   └── results/
│       ├── q1_funnel_country_device.csv
│       ├── q2_top_10_partners_revenue_90d.csv
│       ├── q3_ltv_by_user_cohort.csv
│       ├── q4_suspected_bot_sessions.csv
│       └── q5_partner_cancellation_outliers.csv
├── dashboard/
│   ├── data
│   │   ├── fct_bookings.csv
│   │   └── fct_session.csv
│   ├── dashboard.pdf
│   ├── rentcars_dashboard_case.twbx
│   └── slide_apresentacao.pdf
├── stakeholders/
│   ├── roteiro_entrevista.md
│   ├── requisitos_tecnicos.md
│   └── data_contract.yaml
├── analyses/
├── snapshots/
├── macros/
├── governance.md
├── dbt_project.yml
├── .gitignore
└── README.md
```
---

## 7. Como executar o projeto

### 7.1 Pré-requisitos

- Python 3.11+
- ambiente virtual configurado
- dependências instaladas
- `profiles.yml` configurado para DuckDB

### 7.2 Instalação das dependências

```bash
pip install dbt-core dbt-duckdb
```

### 7.3 Exemplo de `profiles.yml`

Exemplo de configuração para DuckDB:

```yaml
rentcars_case:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: C:\Users\Muller\rentcars_case\dev.duckdb
      threads: 1
```

### 7.4 Carregamento dos dados

```bash
dbt seed
```

### 7.5 Execução dos modelos

```bash
dbt run
```

### 7.6 Execução dos testes

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

Foi utilizado `sources.yml` para formalizar a entrada dos dados brutos no dbt, referenciando diretamente as tabelas carregadas via `dbt seed`.

Essa decisão melhora:

- rastreabilidade
- legibilidade
- padronização das referências
- documentação do pipeline

### 9.2 Camada de staging

Os modelos `stg_*` foram criados para concentrar:

- deduplicação com `row_number()`
- cast de tipos
- padronização de case
- limpeza básica
- criação de flags técnicas de qualidade

A camada de staging foi usada para deixar o dado consistente e previsível, sem concentrar lógica analítica final.

### 9.3 Camada intermediate

Os modelos `int_*` foram criados para centralizar joins e enriquecimento antes da camada final.

#### `int_bookings_enriched`

Modelo no grão de uma linha por reserva, enriquecido com dados de parceiro e cancelamento.

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

### 9.4 Marts

Foram implementados os marts mínimos exigidos:

- `dim_partners`
- `dim_users`
- `fct_bookings`
- `fct_sessions`

#### `dim_partners`

Dimensão no grão de uma linha por parceiro, contendo atributos cadastrais e comerciais.

#### `dim_users`

Dimensão derivada no grão de uma linha por usuário, consolidando primeira e última sessão, primeira e última reserva, além de contagens de sessões e reservas. Na componente de sessões, foram consideradas apenas sessões analíticas com `is_bot = false`.

#### `fct_bookings`

Fato de reservas no grão de uma linha por booking, enriquecido com dados de parceiro e cancelamento.

#### `fct_sessions`

Fato de sessões no grão de uma linha por sessão, enriquecido com contagem de buscas e reservas.

---

## 10. Estratégia de materialização

### 10.1 Views

Os modelos de staging, intermediate e dimensões foram materializados como `view` no ambiente atual, mantendo a transformação transparente e simples para iteração local.

Os fatos finais foram implementados como incrementais via configuração explícita nos próprios modelos.

### 10.2 Incremental

Os fatos finais foram implementados como modelos incrementais:

- `fct_bookings`
- `fct_sessions`

#### Estratégia adotada

- `materialized='incremental'`
- `incremental_strategy='delete+insert'`
- `unique_key='booking_id'` para `fct_bookings`
- `unique_key='session_id'` para `fct_sessions`

#### Justificativa

A estratégia incremental foi adotada porque:

- o case exige explicitamente fatos incrementais
- fatos representam tabelas finais de consumo analítico
- essa abordagem é mais aderente a cenários reais de produção
- o uso de `unique_key` e deduplicação explícita reduz risco de dupla contagem
- o reprocessamento da borda do maior timestamp com `>=` reduz risco de perda de registros em cenários de timestamps empatados


#### Deduplicação explícita

Mesmo nos facts incrementais, foi mantida deduplicação explícita por chave única usando `row_number()` para reforçar integridade e previsibilidade da carga.

---

## 11. Testes implementados

Foram implementados testes nativos do dbt:

- `not_null`
- `unique`
- `accepted_values`
- `relationships`

Também foram implementados testes customizados via macros próprias:

- `valid_session_timing`
- `valid_trip_dates`

Os testes foram aplicados principalmente na camada de staging para validar integridade estrutural e regras básicas de negócio, e também nos marts para garantir unicidade e relacionamento nas tabelas finais.

---

## 12. Regras e remediações de qualidade adotadas

Até esta etapa, foram tratados ou sinalizados problemas como:

- duplicatas
- inconsistência de case em colunas categóricas
- valores monetários inválidos
- flags técnicas de anomalia
- datas inválidas em buscas e reservas
- relacionamento entre entidades
- necessidade de exclusão de registros logicamente inválidos para a camada analítica
- exclusão de tráfego bot das camadas analíticas de sessão


Exemplo de remediação aplicada:

- Em `stg_searches`, registros com `dropoff_date < pickup_date` foram removidos da camada analítica de staging para garantir consistência das análises e viabilizar o teste customizado de datas válidas.

- Em `stg_bookings`, registros com datas inválidas foram mantidos e sinalizados via `is_invalid_trip_dates` para análise e controle de qualidade.

- Em `int_sessions_enriched`, na `fct_sessions` e no componente de sessões de `dim_users`, sessões marcadas como bot foram excluídas da camada analítica, em linha com a regra de negócio definida no dicionário de dados.

---

## 13. Estado atual da implementação

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
- marts:
  - `dim_partners`
  - `dim_users`
  - `fct_bookings`
  - `fct_sessions`
- facts incrementais funcionando
- suíte dbt com `dbt run` e `dbt test` executando com sucesso, totalizando 61 testes aprovados
- `sql/queries.sql` com respostas para Q1 a Q5 do desafio analítico
- resultados exportados em CSV na pasta `sql/results/`
- dashboard analítico com 5 visualizações
- slides de apresentação do desafio 3
- `governance.md` com problemas de qualidade, remediações, SLA, glossário e política de PII
- `stakeholders/roteiro_entrevista.md`
- `stakeholders/requisitos_tecnicos.md`
- `stakeholders/data_contract.yaml`

---

## 14. Limitações conhecidas

Apesar da entrega completa dos cinco desafios do case, algumas limitações permanecem por se tratar de um contexto externo, com prazo curto e sem acesso ao ambiente real da empresa.

Os principais pontos são:

- algumas definições de negócio, especialmente em métricas como receita e cancelamento, foram estruturadas como proposta para o case e não como contrato oficial da empresa
- o ambiente utilizado foi local, baseado em DuckDB, com foco em simplicidade de execução e iteração rápida
- o dashboard foi construído a partir de exportações analíticas, e não conectado diretamente a um ambiente produtivo
- os artefatos de stakeholder discovery foram simulados com base no dicionário de dados, nos modelos implementados e em hipóteses plausíveis de uma área de Revenue / Pricing

---

## 15. Melhorias futuras e próximos passos

Com mais tempo, eu priorizaria:

- ampliar testes nos marts com regras adicionais de negócio
- adicionar métricas derivadas mais consolidadas para consumo executivo
- enriquecer documentação com catálogo mais detalhado por coluna
- evoluir monitoramento de qualidade e SLA de dados
- expandir a camada analítica para suportar novos cortes e indicadores
- revisar a estratégia incremental para cenários com atualizações retroativas mais complexas
- consolidar modelos agregados adicionais para parceiros, cohorts e qualidade operacional
- evoluir o monitoramento recorrente de qualidade com alertas automáticos
- ampliar a camada semântica para métricas de negócio mais frequentes
- aprofundar o stakeholder discovery com validação direta junto às áreas funcionais
- refinar o data contract com owners reais, horários operacionais e critérios oficiais de consumo

---

## 16. Observação final

A solução buscou equilibrar profundidade técnica, clareza analítica e documentação de negócio dentro do escopo e do prazo do case.

O projeto foi estruturado para entregar:

- uma base dbt confiável e testável
- respostas analíticas em SQL com resultados exportados
- um dashboard executivo com storytelling
- documentação de governança e qualidade
- artefatos de discovery e formalização de métricas para uma área de negócio

Como se trata de um case externo, parte das definições e contratos foi construída como proposta plausível, ancorada no dicionário de dados, nos modelos implementados e nas análises realizadas.