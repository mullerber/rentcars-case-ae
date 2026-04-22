# Governance and Data Quality

## 1. Objetivo

Este documento resume os principais pontos de governança e qualidade de dados considerados na solução do case técnico da Rentcars.
Os objetivos são:

- identificar e documentar os principais problemas de qualidade presentes nos dados brutos
- registrar as regras de remediação e validação aplicadas no pipeline dbt
- definir critérios mínimos para considerar os dados confiáveis para consumo analítico
- descrever o tratamento proposto para campos sensíveis (PII)
- descrever, em alto nível, os modelos analíticos finais utilizados no projeto

---

## 2. Escopo

A governança aqui descrita cobre os datasets brutos abaixo e seus respectivos modelos analíticos derivados.

### Datasets brutos
- `raw_sessions`
- `raw_searches`
- `raw_bookings`
- `raw_cancellations`
- `raw_partners`

### Modelos finais utilizados
- `dim_partners`
- `dim_users`
- `fct_bookings`
- `fct_sessions`

---

## 3. Problemas de qualidade identificados

Os dados do case contêm problemas intencionais de qualidade. Abaixo estão os principais pontos identificados.

### 3.1 Duplicatas
Presentes em múltiplas tabelas, incluindo:

- `raw_sessions`
- `raw_searches`
- `raw_bookings`
- `raw_cancellations`
- `raw_partners`

**Risco:** dupla contagem em métricas operacionais e financeiras.

### 3.2 Inconsistência de capitalização e padronização textual
Exemplos:

- `device` em `raw_sessions`
- `country` em `raw_sessions`
- `status` em `raw_bookings`
- `status` em `raw_partners`
- localidades em `raw_searches` e `raw_bookings`

**Risco:** segmentação incorreta e falhas em filtros e agregações.

### 3.3 Datas logicamente inválidas
Exemplos:

- `dropoff_date < pickup_date` em `raw_searches`
- `dropoff_date < pickup_date` em `raw_bookings`
- `ended_at <= started_at` em sessões
- `days_before_pickup` negativo em cancelamentos

**Risco:** erros em análise de jornada, duração, disponibilidade e operações.

### 3.4 Outliers e valores inválidos
Exemplos:

- `total_amount < 0`
- `total_amount = 0`
- `total_amount > 15000`
- sessões muito longas
- comissões potencialmente fora da faixa esperada

**Risco:** distorção de KPIs, receita e indicadores de comportamento.

### 3.5 Tráfego automatizado / bot
O dicionário de dados informa sessões com `is_bot = true` e anomalias em volume de buscas por sessão.

**Risco:** inflação artificial do funil e distorção de métricas de conversão.

### 3.6 Integridade relacional
Relacionamentos relevantes:

- `searches.session_id -> sessions.session_id`
- `bookings.session_id -> sessions.session_id`
- `bookings.partner_id -> partners.partner_id`
- `cancellations.booking_id -> bookings.booking_id`

**Risco:** joins incorretos, perda de rastreabilidade e métricas incompletas.

### 3.7 Sessão anônima
Sessão sem `user_id`, representando visitante não autenticado.

---

## 4. Estratégia de remediação adotada

A estratégia foi separar claramente:

- **tratamento estrutural** na camada `staging`
- **enriquecimento e semântica** na camada `intermediate`
- **consumo final** na camada `marts`

### 4.1 Duplicatas
Tratadas com `row_number()` e manutenção do registro mais recente por chave natural:

- `session_id`
- `search_id`
- `booking_id`
- `cancellation_id`
- `partner_id`

### 4.2 Padronização de texto e categorias
Aplicada via:

- `lower()`
- `upper()`
- `trim()`

Campos normalizados incluem:

- status
- device
- country
- localidades
- categorias

### 4.3 Datas inválidas

#### `stg_searches`
Registros com `dropoff_date < pickup_date` foram removidos da camada analítica.

#### `stg_bookings`
Registros com datas inválidas foram mantidos e sinalizados por flag:

- `is_invalid_trip_dates`

### 4.4 Outliers e valores inválidos em reservas
Em `stg_bookings`, foram criadas flags para:

- `is_negative_total_amount`
- `is_zero_total_amount`
- `is_high_total_amount`

Essas flags foram usadas posteriormente para compor a lógica de receita válida.

### 4.5 Bots
As regras analíticas adotadas consideram a exclusão de sessões bot e, por consequência, das análises de comportamento, funil e jornada derivadas dessas sessões.

Isso foi refletido em:

- `int_sessions_enriched`
- `fct_sessions`
- componente de sessões de `dim_users`

### 4.6 Receita válida
Em `int_bookings_enriched`, foi criada a lógica:

- `is_valid_revenue_booking`
- `valid_revenue_amount`

Critérios considerados:

- booking com status analiticamente válido
- parceiro ativo
- ausência de inconsistências críticas de valor e datas

---

## 5. Validações implementadas

### 5.1 Testes nativos do dbt
Foram implementados testes de:

- `not_null`
- `unique`
- `accepted_values`
- `relationships`

### 5.2 Testes customizados
Foram implementados testes customizados via SQL/macros próprias:

- `valid_session_timing`
- `valid_trip_dates`

### 5.3 Evidência de execução
Ao final da construção do pipeline:

- `dbt run` executou com sucesso
- `dbt test` executou com sucesso
- 61 testes foram aprovados

Esses testes cobrem tanto integridade estrutural quanto regras de negócio fundamentais.

---

## 6. Catálogo resumido dos modelos finais

### 6.1 `dim_partners`
**Grão:** 1 linha por parceiro

**Finalidade:** fornecer atributos cadastrais e comerciais de parceiros para análises de receita, cancelamento e performance.

**Campos-chave e atributos relevantes:**

- `partner_id`
- `partner_name`
- `partner_country`
- `partner_tier`
- `partner_status`
- `commission_rate`
- `is_active_partner`

### 6.2 `dim_users`
**Grão:** 1 linha por usuário

**Finalidade:** consolidar a jornada histórica do usuário em nível analítico.

**Campos e métricas relevantes:**

- `user_id`
- `first_session_at`
- `last_session_at`
- `total_sessions`
- `first_booking_at`
- `last_booking_at`
- `total_bookings`

**Observação:** na componente de sessões, foram consideradas apenas sessões analíticas com `is_bot = false`.

### 6.3 `fct_bookings`
**Grão:** 1 linha por reserva

**Finalidade:** fato principal de reservas para análises de receita, cancelamento, parceiro e comportamento transacional.

**Campos e métricas relevantes:**

- `booking_id`
- `session_id`
- `user_id`
- `partner_id`
- `booked_at`
- `booking_status`
- `has_cancellation`
- `valid_revenue_amount`
- `partner_tier`
- `partner_country`

### 6.4 `fct_sessions`
**Grão:** 1 linha por sessão analítica

**Finalidade:** fato principal de sessões para análise de funil, dispositivo, país, comportamento de busca e jornada.

**Campos e métricas relevantes:**

- `session_id`
- `user_id`
- `started_at`
- `country`
- `device`
- `channel`
- `has_search`
- `has_booking`
- `total_searches`
- `total_bookings`

---

## 7. Glossário de métricas

### Receita válida
Valor de reserva considerado elegível para análise de receita após aplicação das regras de consistência e semântica analítica.

### Taxa de conversão
Proporção de sessões que resultam em ao menos uma reserva confirmada, podendo ser desdobrada por etapa do funil quando necessário.

### Taxa de cancelamento
Percentual de reservas canceladas em relação ao total de reservas da base analisada, podendo ser ajustado conforme a definição de negócio adotada.

### LTV observado
Soma da receita válida observada com base apenas no período disponível no dataset, sem projeção futura de valor de vida do cliente.

### Parceiro ativo
Parceiro com status analítico `active`, considerado apto para compor análises operacionais e financeiras.

---

## 8. SLA e critérios de confiabilidade

Para este case, um dado pode ser considerado **confiável para consumo analítico** quando os critérios abaixo forem atendidos.

### 8.1 Execução técnica
- `dbt run` concluído com sucesso
- `dbt test` concluído com sucesso

### 8.2 Testes críticos sem falha
Nenhuma falha em:

- unicidade de chaves principais
- obrigatoriedade de campos críticos
- integridade relacional
- regras customizadas de datas e timing

### 8.3 Consumo a partir da camada correta
O consumo analítico deve ser feito preferencialmente a partir de:

- `fct_bookings`
- `fct_sessions`
- `dim_partners`
- `dim_users`

e não diretamente dos dados brutos.

### 8.4 Thresholds propostos
Para ambiente produtivo, eu adotaria como thresholds mínimos:

- 0 falhas em testes críticos (`unique`, `not_null`, `relationships`)
- 0 falhas em regras customizadas de consistência temporal
- atualização dos marts concluída antes da disponibilização do dashboard

---

## 9. Política de PII

### 9.1 Campos sensíveis identificados
Os principais campos sensíveis observados foram:

- `user_id`
- `contact_email`

### 9.2 Diretriz de tratamento

#### `user_id`
- tratar como identificador pseudonimizado
- evitar exposição desnecessária em dashboards executivos
- restringir uso a análises em que o nível usuário seja realmente necessário

#### `contact_email`
- tratar como dado sensível de contato
- não expor em dashboards ou relatórios amplos
- aplicar mascaramento ou exclusão em contextos analíticos não operacionais

### 9.3 Princípios propostos
- mínimo privilégio de acesso
- exposição apenas por necessidade de negócio
- preferência por agregação em vez de exibição de identificadores
- mascaramento em contextos de compartilhamento amplo

---

## 10. Riscos residuais e limitações

Mesmo com as validações implementadas, permanecem pontos de atenção:

- regras de fraude ainda são simplificadas
- outliers podem exigir tratamento mais sofisticado em produção
- métricas como LTV foram calculadas no horizonte observado do dataset, e não como projeção completa de vida do cliente
- a política de bots foi aplicada na camada analítica de sessões, mas poderia evoluir para uma estratégia de classificação mais robusta

---

## 11. Melhorias futuras recomendadas

Com mais tempo, eu priorizaria:

- ampliar testes de negócio na camada mart
- criar monitoramento recorrente de qualidade por execução
- automatizar alertas para falhas críticas
- aprofundar regras de fraude em sessões, reservas e cancelamentos
- expandir glossário e catálogo por coluna para consumo corporativo
- formalizar owners, periodicidade e SLA por domínio de dado
- validar se `refund_amount` não excede o `total_amount` da reserva associada

---

## 12. Conclusão

A solução priorizou uma base analítica confiável, testável e com regras claras de negócio, apoiada em modelagem em camadas, validações dbt e remediações explícitas para os principais problemas de qualidade.

Com isso, o projeto ficou mais preparado para consumo analítico e para uso em dashboards e análises executivas.
