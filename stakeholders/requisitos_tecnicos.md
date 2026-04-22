# Requisitos Técnicos — Tradução das Necessidades da Área
## Área escolhida: Revenue / Pricing

## 1. Objetivo

Este documento traduz, para a perspectiva técnica, as necessidades levantadas na entrevista simulada com a área de Revenue / Pricing.

O foco é conectar dores e objetivos de negócio a entregáveis concretos de dados, como:

- novas métricas
- regras de cálculo
- tabelas analíticas
- ajustes em modelos dbt
- requisitos de atualização e confiabilidade

---

## 2. Resumo das necessidades levantadas

Com base no roteiro de entrevista, as principais necessidades da área podem ser resumidas em cinco blocos:

1. **Receita confiável e comparável ao longo do tempo**
2. **Visão clara do funil de conversão**
3. **Monitoramento de cancelamentos com foco em impacto operacional**
4. **Capacidade de priorizar parceiros por receita, cancelamento e tier**
5. **Maior confiança nas definições de métricas e menor dependência de bases brutas**

---

## 3. Situação atual (as-is)

Hoje, a área de Revenue / Pricing provavelmente enfrenta um cenário com as seguintes características:

- uso de múltiplas fontes ou visões diferentes para responder perguntas parecidas
- dependência de dados ainda próximos do bruto
- risco de divergência entre números de receita, conversão e cancelamento
- baixa transparência sobre exclusões de bots, duplicatas e reservas inválidas
- dificuldade para entender rapidamente o impacto de cancelamentos por parceiro
- pouca clareza sobre qual métrica deve ser usada em cada decisão

Do ponto de vista técnico, isso costuma significar:

- queries repetidas para calcular métricas parecidas
- filtros sendo refeitos de forma inconsistente
- baixo reuso entre análises
- dificuldade de governança sobre a definição oficial dos indicadores

---

## 4. Situação desejada (to-be)

Após a implementação dos modelos dbt, a área deveria consumir os dados prioritariamente a partir de modelos analíticos estáveis e testados.

### Visão desejada
- receita analisada a partir de `fct_bookings`
- conversão analisada a partir de `fct_sessions`
- parceiros analisados via `dim_partners`
- usuários analisados via `dim_users`
- métricas formalizadas com nome, definição, owner e SLA

### Resultado esperado
- menor dependência de bases brutas
- maior consistência entre dashboards e análises ad hoc
- maior velocidade para responder perguntas de negócio
- menor ambiguidade sobre regras de cálculo
- maior confiança em cortes por parceiro, dispositivo, país e tier

---

## 5. Tradução das necessidades em requisitos técnicos

## 5.1 Receita confiável

### Necessidade de negócio
A área precisa acompanhar receita de forma consistente, sem inflar resultados com reservas inválidas, canceladas ou associadas a parceiros que não deveriam compor a análise principal.

### Requisito técnico
Manter uma métrica padronizada de receita analítica em `fct_bookings`, derivada da lógica criada em `int_bookings_enriched`.

### Implementação já realizada
- `is_valid_revenue_booking`
- `valid_revenue_amount`

### Evolução recomendada
Formalizar `valid_revenue_amount` como métrica principal de receita analítica para consumo da área.

Outras possíveis visões de receita, como receita bruta ou uma eventual receita líquida, devem ser tratadas como definições alternativas e formalizadas apenas se houver necessidade real de uso por outra área.

### Benefício
Evita o uso genérico do termo “receita” sem qualificação.

---

## 5.2 Funil de conversão confiável

### Necessidade de negócio
A área precisa entender o funil de conversão entre sessão, busca e reserva sem contaminação por tráfego bot ou por definições inconsistentes.

### Requisito técnico
Usar `fct_sessions` como fato oficial de sessão analítica, com flags explícitas de jornada.

### Implementação já realizada
- `has_search`
- `has_booking`
- `total_searches`
- `total_bookings`
- exclusão de bots da camada analítica de sessão

### Evolução recomendada
Criar, no futuro, uma camada semântica ou modelo derivado com métricas prontas de funil por:

- país
- dispositivo
- canal
- usuário autenticado vs anônimo

### Benefício
Reduz a necessidade de recalcular funil em queries manuais.

---

## 5.3 Monitoramento de cancelamentos

### Necessidade de negócio
A área precisa entender onde os cancelamentos se concentram e quais parceiros mais impactam a operação.

### Requisito técnico
Usar `fct_bookings` com apoio dos atributos de cancelamento já enriquecidos em `int_bookings_enriched`.

### Implementação já realizada
- `has_cancellation`
- `cancellation_id`
- `cancelled_at`
- `cancellation_reason`
- `refund_amount`
- `refund_status`
- `days_before_pickup`
- `is_late_cancellation`

### Evolução recomendada
Criar um modelo adicional, por exemplo `fct_partner_operational_quality`, agregando por parceiro:

- total de reservas
- total de cancelamentos
- taxa de cancelamento
- taxa de cancelamento tardio
- receita válida
- ticket médio

### Benefício
Entregar visão operacional pronta para priorização de parceiros.

---

## 5.4 Priorização por parceiro e tier

### Necessidade de negócio
A área precisa comparar parceiros não só por receita, mas também por risco operacional e posicionamento comercial.

### Requisito técnico
Combinar dados de `fct_bookings` com atributos de `dim_partners`.

### Implementação já realizada
A `fct_bookings` já carrega atributos úteis para isso:

- `partner_name`
- `partner_country`
- `partner_tier`
- `partner_status`
- `commission_rate`

### Evolução recomendada
Criar um modelo agregado por parceiro com KPIs consolidados, permitindo leitura de:

- receita
- cancelamento
- ticket médio
- participação no volume
- tier
- status

### Benefício
Apoiar decisões comerciais e operacionais com menor esforço analítico.

---

## 5.5 Valor do usuário / cohort

### Necessidade de negócio
A área pode querer entender quais grupos de usuários geram mais valor ao longo do tempo.

### Requisito técnico
Usar `dim_users` como base de cohort e `fct_bookings` como base de monetização.

### Implementação já realizada
- `first_session_at`
- `first_booking_at`
- `total_sessions`
- `total_bookings`
- cálculo analítico de LTV observado em SQL

### Evolução recomendada
Criar um modelo agregado por cohort, por exemplo `agg_user_cohort_ltv`, contendo:

- cohort de primeiro acesso
- total de usuários
- receita válida total
- LTV médio observado
- percentual de usuários com receita

### Benefício
Evitar que esse tipo de análise dependa sempre de query manual.

---

## 6. Novos modelos recomendados

Com base nas necessidades levantadas, os principais modelos adicionais recomendados seriam:

### 6.1 `agg_partner_kpis`
**Grão:** 1 linha por parceiro

**Objetivo:** consolidar indicadores de receita, cancelamento, ticket médio e participação no volume.

### 6.2 `agg_conversion_by_segment`
**Grão:** 1 linha por combinação de segmento analítico  
Ex.: país + dispositivo + canal

**Objetivo:** entregar funil pronto para acompanhamento por segmento.

### 6.3 `agg_user_cohort_ltv`
**Grão:** 1 linha por cohort de primeiro acesso

**Objetivo:** acompanhar valor observado por cohort sem necessidade de query ad hoc recorrente.

### 6.4 `agg_partner_operational_quality`
**Grão:** 1 linha por parceiro

**Objetivo:** monitorar qualidade operacional com foco em cancelamento, atraso, risco e impacto econômico.

---

## 7. Métricas que deveriam ser formalizadas

As seguintes métricas deveriam ter definição oficial e contrato mínimo:

- receita bruta
- receita válida
- taxa de conversão
- taxa de cancelamento
- ticket médio
- LTV observado
- taxa de cancelamento tardio
- participação de receita por tier
- participação de receita por parceiro

---

## 8. Conflito de definição de métrica

## Métrica: Receita

### Possível conflito
A área de Revenue / Pricing pode querer olhar a receita sob ótica comercial, enquanto áreas como Finance ou Operações podem adotar critérios mais conservadores.

### Risco
Usar uma única métrica chamada apenas “receita” gera ambiguidade e perda de confiança.

### Proposta técnica
Formalizar `valid_revenue_amount` como métrica padrão para o case e tratar outras possíveis definições de receita como versões alternativas, caso sejam necessárias para outras áreas.

### Regra de governança
Dashboards e análises devem usar a métrica explicitamente nomeada, evitando a palavra “receita” sem qualificador.

---

## 9. Requisitos não funcionais

Além das regras de cálculo, a área também demanda requisitos não funcionais.

### 9.1 Confiabilidade
- dados só devem ser consumidos após `dbt run` e `dbt test` executarem com sucesso
- nenhuma falha em testes críticos

### 9.2 Atualização
- periodicidade mínima diária para dashboards e análises executivas
- horários de atualização devem ser conhecidos pela área usuária

### 9.3 Transparência
- cada métrica precisa ter definição documentada
- os filtros de exclusão (bots, duplicatas, reservas inválidas) devem ser claros

### 9.4 Reusabilidade
- sempre que possível, métricas recorrentes devem sair de modelos agregados e não de SQL ad hoc repetido

---

## 10. Conclusão

A tradução das necessidades da área de Revenue / Pricing mostra que o principal valor do trabalho de dados aqui não está apenas em armazenar ou transformar tabelas, mas em formalizar métricas, reduzir ambiguidade e entregar uma camada analítica confiável para tomada de decisão.

Os modelos já construídos no projeto atendem uma parte relevante dessas necessidades, mas ainda existe espaço para evoluir o consumo com modelos agregados, contratos de métricas e maior formalização da camada semântica.