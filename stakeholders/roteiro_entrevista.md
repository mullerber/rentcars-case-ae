# Roteiro de Entrevista — Stakeholder Discovery
## Área escolhida: Revenue / Pricing

## 1. Objetivo da entrevista

O objetivo desta entrevista simulada é entender como a área de Revenue / Pricing utiliza dados hoje, quais decisões de negócio precisam ser suportadas, quais KPIs são mais relevantes, quais dores existem no acesso e na confiança dos dados e quais necessidades futuras deveriam ser traduzidas em requisitos técnicos para o time de dados.

A escolha da área de Revenue / Pricing foi feita por ser a mais aderente ao escopo analítico construído no projeto, especialmente em temas como receita, conversão, cancelamentos, performance de parceiros e comportamento de reservas.

---

## 2. Contexto da área

A área de Revenue / Pricing tende a atuar em decisões como:

- acompanhamento de receita e volume de reservas
- análise de conversão ao longo do funil
- identificação de parceiros com melhor ou pior performance
- monitoramento de cancelamentos e impactos na receita
- priorização de oportunidades comerciais e operacionais por país, tier e parceiro
- entendimento de comportamento do usuário ao longo da jornada de compra

Nesse contexto, a qualidade da definição das métricas é crítica, porque decisões de pricing e priorização comercial podem ser distorcidas por problemas de duplicidade, cancelamentos, bots, reservas inválidas ou divergências entre “receita bruta” e “receita válida”.

---

## 3. Roteiro estruturado de perguntas

## 3.1 Objetivos da área

1. Quais são hoje os principais objetivos da área de Revenue / Pricing?
2. Quais decisões são tomadas semanal ou mensalmente com apoio de dados?
3. A área olha mais para crescimento de receita, eficiência de conversão, rentabilidade, retenção ou equilíbrio entre esses fatores?
4. Quais perguntas de negócio vocês mais tentam responder no dia a dia?
5. Hoje a área está mais orientada a diagnóstico do passado, monitoramento do presente ou decisão futura?

---

## 3.2 KPIs e definições de negócio

1. Quais são os KPIs mais importantes da área hoje?
2. Como vocês definem receita?  
   - Receita bruta?  
   - Receita líquida?  
   - Receita sem cancelamentos?  
   - Receita validada após exclusão de inconsistências?
3. Como vocês definem conversão?  
   - Sessão para reserva?  
   - Busca para reserva?  
   - Usuário para reserva?
4. Como vocês definem cancelamento?  
   - Reserva com status `cancelled`?  
   - Reserva com evento de cancelamento associado?  
   - Cancelamento confirmado apenas após reembolso?
5. Existe alguma métrica que hoje gera dúvida ou discussão recorrente entre áreas?
6. Quais métricas precisam de corte por parceiro, tier, país, dispositivo ou canal?
7. O que vocês consideram um parceiro saudável do ponto de vista de receita e cancelamento?
8. Existe alguma métrica de valor do cliente, como ticket médio, LTV ou recorrência, que já seja usada ou desejada?

---

## 3.3 Fontes de dados utilizadas hoje

1. Quais bases, relatórios ou dashboards a área utiliza atualmente?
2. Os dados vêm de uma fonte única ou de múltiplas planilhas, queries e dashboards?
3. Existe hoje alguma dependência de times técnicos para responder perguntas simples?
4. A área utiliza dados brutos, marts analíticos ou uma combinação de ambos?
5. Existe alguma diferença entre o número exibido em dashboards e o número usado em reuniões executivas?
6. Hoje vocês conseguem rastrear facilmente de onde veio cada métrica?

---

## 3.4 Dores no acesso e na confiança dos dados

1. Quais são hoje as maiores dificuldades para acessar os dados necessários?
2. Existe atraso frequente na atualização dos números?
3. Há métricas que a área evita usar por baixa confiança?
4. Já ocorreram divergências de definição entre Revenue / Pricing e outras áreas?
5. Existe dificuldade em entender o impacto de cancelamentos na leitura de receita?
6. Parceiros com dados ruins ou inconsistentes afetam decisões do time?
7. Hoje há dificuldade em separar comportamento real do usuário de tráfego bot ou anômalo?
8. Se você tivesse que apontar uma única dor mais crítica, qual seria?

---

## 3.5 Necessidades futuras

1. Que análises a área gostaria de fazer e ainda não consegue?
2. Existe interesse em acompanhar performance por cohort, parceiro, tier, dispositivo ou país com mais profundidade?
3. Há necessidade de acompanhamento quase em tempo real ou diário já seria suficiente?
4. Quais alertas automáticos fariam diferença para a área?
5. Existe interesse em priorizar parceiros com base em combinação de receita, cancelamento e rentabilidade?
6. Há necessidade de novos modelos analíticos voltados para pricing, elasticidade, performance de jornada ou fraude?

---

## 3.6 Relação entre negócio e engenharia de dados

1. O que faria os dados serem mais úteis no dia a dia da área?
2. O que precisa mudar para a área confiar mais nas métricas?
3. O time prefere dashboards executivos resumidos ou tabelas analíticas mais detalhadas?
4. Qual seria o formato ideal de entrega: dashboard, tabela analítica, camada semântica, alertas ou exportável?
5. Que tipo de documentação ajudaria mais: glossário, regra de cálculo, owner da métrica ou SLA?

---

## 4. Hipóteses de resposta esperada

Com base no contexto do case, é plausível esperar que a área de Revenue / Pricing valorize especialmente:

- receita válida e comparável ao longo do tempo
- clareza sobre impacto de cancelamentos
- visão segmentada por parceiro, tier, país e dispositivo
- confiança em métricas de conversão
- menor dependência de bases brutas e planilhas paralelas
- maior transparência sobre regras de exclusão de bots, duplicatas e reservas inválidas

Também é provável que exista sensibilidade em torno de métricas que parecem simples, mas mudam muito conforme a definição adotada, como:

- receita
- taxa de conversão
- taxa de cancelamento
- ticket médio
- LTV

---

## 5. Conflito de definição de métrica identificado

### Métrica escolhida: Receita

Um conflito plausível entre áreas é a definição de receita.

### Possível visão de Revenue / Pricing
A área pode preferir uma visão mais comercial e operacional, focada em reservas com potencial real de geração de valor, excluindo cancelamentos e inconsistências graves.

### Possível visão de Finance / Operações
Outra área pode querer uma visão mais conservadora, tratando receita apenas após confirmação financeira, exclusão de reembolsos ou aplicação de regras adicionais de liquidação.

### Risco do conflito
Se cada área usar uma definição diferente de receita, decisões de performance, priorização de parceiros e leitura de crescimento podem ficar inconsistentes.

### Proposta de arbitragem
A melhor saída seria formalizar pelo menos duas métricas distintas e nomeadas de forma explícita:

- `gross_booking_amount`: valor bruto da reserva
- `valid_revenue_amount`: valor elegível para análise comercial e analítica
- opcionalmente, no futuro, uma métrica financeira adicional, caso exista uma visão contábil diferente

O ponto principal é evitar o uso do termo genérico “receita” sem qualificação.

---

## 6. Resultado esperado da entrevista

Ao final da entrevista, o objetivo é sair com clareza sobre:

- quais métricas realmente importam para a área
- como cada métrica é definida em linguagem de negócio
- quais cortes analíticos são necessários
- quais limitações atuais impedem o uso eficaz dos dados
- quais requisitos técnicos precisam ser priorizados
- quais conflitos de definição precisam ser resolvidos com data contract

---

## 7. Observação final

Este roteiro foi desenhado para capturar não apenas pedidos explícitos da área, mas também conflitos de definição e necessidades que nem sempre aparecem quando os dados já existem, mas ainda não são consumidos com confiança.