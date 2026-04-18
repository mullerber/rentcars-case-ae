-- =========================================================
-- Q1: Taxa de conversão por funil (sessão → busca → reserva),
-- segmentada por país e device
-- =========================================================

with funnel_by_country_device as (

    select
        country,
        device,
        count(*) as total_sessions,
        -- has_search e has_booking já foram preparados no fct_sessions
        -- por isso a leitura do funil fica simples nesta etapa
        sum(case when has_search then 1 else 0 end) as sessions_with_search,
        sum(case when has_booking then 1 else 0 end) as sessions_with_booking
    from fct_sessions
    -- 1 linha final por combinação de país e dispositivo
    group by 1, 2

)

select
    country,
    device,
    total_sessions,
    sessions_with_search,
    sessions_with_booking,
    round(
        -- taxa da primeira etapa do funil:
        -- sessões que chegaram a fazer busca / total de sessões
        100.0 * sessions_with_search / nullif(total_sessions, 0),
        2
    ) as session_to_search_rate_pct,
    round(
        -- taxa da segunda etapa do funil:
        -- sessões com reserva / sessões com busca
        100.0 * sessions_with_booking / nullif(sessions_with_search, 0),
        2
    ) as search_to_booking_rate_pct,
    round(
        -- taxa final do funil:
        -- sessões com reserva / total de sessões
        100.0 * sessions_with_booking / nullif(total_sessions, 0),
        2
    ) as session_to_booking_rate_pct
from funnel_by_country_device
-- ordena primeiro pelos segmentos com maior volume
order by total_sessions desc, country, device;

-- =========================================================
-- Q2: Top 10 parceiros por receita nos últimos 90 dias,
-- excluindo cancelamentos
-- =========================================================

with reference_date as (

    select
        -- usa a maior data do próprio dataset como referência,
        -- em vez da data atual da máquina
        cast(max(booked_at) as date) as max_booked_date
    from fct_bookings

),

bookings_last_90_days as (

    select
        fb.partner_id,
        fb.partner_name,
        fb.partner_country,
        fb.partner_tier,
        fb.booking_id,
        fb.booked_at,
        fb.valid_revenue_amount
    from fct_bookings fb
    cross join reference_date rd
    where cast(fb.booked_at as date) >= rd.max_booked_date - interval '89 day'
      -- exclui reservas canceladas
      and fb.has_cancellation = false
      -- usa apenas receita válida já tratada na modelagem
      and fb.valid_revenue_amount is not null

),

partner_revenue as (

    select
        partner_id,
        partner_name,
        partner_country,
        partner_tier,
        count(*) as total_bookings,
        round(sum(valid_revenue_amount), 2) as total_revenue,
        round(avg(valid_revenue_amount), 2) as avg_booking_value
    from bookings_last_90_days
    -- agrega por parceiro e atributos descritivos
    group by 1, 2, 3, 4

)

select
    partner_id,
    partner_name,
    partner_country,
    partner_tier,
    total_bookings,
    total_revenue,
    avg_booking_value
from partner_revenue
-- top 10 por receita, com critério de desempate por volume
order by total_revenue desc, total_bookings desc
limit 10;

-- =========================================================
-- Q3: LTV dos usuários agrupados por cohort de primeiro acesso
-- (mês/ano)
-- =========================================================

with user_ltv as (

    select
        du.user_id,
        -- a cohort é definida pelo mês da primeira sessão do usuário
        date_trunc('month', du.first_session_at) as first_access_cohort_month,
        -- LTV aqui foi definido como a soma da receita válida observada
        -- por usuário dentro do horizonte do dataset
        coalesce(sum(fb.valid_revenue_amount), 0) as user_ltv
    from dim_users du
    left join fct_bookings fb
        on du.user_id = fb.user_id
       -- exclui reservas canceladas
       and fb.has_cancellation = false
       -- usa somente receita válida
       and fb.valid_revenue_amount is not null
    -- evita usuários sem first_session_at, que inviabilizariam a cohort
    where du.first_session_at is not null
    group by 1, 2

),

cohort_ltv as (

    select
        first_access_cohort_month,
        count(*) as total_users,
        round(sum(user_ltv), 2) as cohort_total_ltv,
        round(avg(user_ltv), 2) as avg_ltv_per_user,
        round(
            -- percentual de usuários da cohort que geraram alguma receita
            100.0 * sum(case when user_ltv > 0 then 1 else 0 end) / nullif(count(*), 0),
            2
        ) as pct_users_with_revenue
    from user_ltv
    group by 1

)

select
    first_access_cohort_month,
    total_users,
    cohort_total_ltv,
    avg_ltv_per_user,
    pct_users_with_revenue
from cohort_ltv
-- ordena cronologicamente as cohorts
order by first_access_cohort_month;

-- =========================================================
-- Q4: Detecção de sessões suspeitas de bot
-- mais de 50 buscas em uma janela de 5 minutos
-- =========================================================

with search_windows as (

    select
        a.session_id,
        -- cada searched_at da própria sessão vira um ponto de início de janela
        a.searched_at as window_start,
        count(*) as searches_in_5min_window
    from stg_searches a
    join stg_searches b
        on a.session_id = b.session_id
       -- conta quantas buscas da mesma sessão ocorreram
       -- dentro dos 5 minutos seguintes ao ponto inicial
       and b.searched_at between a.searched_at and a.searched_at + interval '5 minute'
    group by 1, 2

),

session_peak_activity as (

    select
        session_id,
        -- pega o pico de atividade da sessão em qualquer janela móvel de 5 min
        max(searches_in_5min_window) as max_searches_in_5min
    from search_windows
    group by 1

),

first_suspicious_window as (

    select
        sw.session_id,
        -- identifica o primeiro instante em que a sessão ultrapassou o limiar
        min(sw.window_start) as first_suspicious_window_start
    from search_windows sw
    where sw.searches_in_5min_window > 50
    group by 1

),

session_total_searches as (

    select
        session_id,
        count(*) as total_searches_in_session,
        min(searched_at) as first_search_at,
        max(searched_at) as last_search_at
    from stg_searches
    group by 1

)

select
    spa.session_id,
    s.user_id,
    s.country,
    s.device,
    s.channel,
    s.is_bot,
    sts.total_searches_in_session,
    spa.max_searches_in_5min,
    fsw.first_suspicious_window_start,
    sts.first_search_at,
    sts.last_search_at
from session_peak_activity spa
join session_total_searches sts
    on spa.session_id = sts.session_id
left join first_suspicious_window fsw
    on spa.session_id = fsw.session_id
left join stg_sessions s
    on spa.session_id = s.session_id
-- regra do case: mais de 50 buscas em uma janela de 5 minutos
where spa.max_searches_in_5min > 50
order by spa.max_searches_in_5min desc, sts.total_searches_in_session desc;

-- =========================================================
-- Q5: Taxa de cancelamento por parceiro com identificação
-- de outliers estatísticos (> 2σ)
-- =========================================================

with partner_cancellations as (

    select
        partner_id,
        partner_name,
        partner_country,
        partner_tier,
        count(*) as total_bookings,
        sum(
            case
                -- considera cancelada tanto a reserva com status cancelled
                -- quanto a que possui evento de cancelamento associado
                when booking_status = 'cancelled' or has_cancellation = true then 1
                else 0
            end
        ) as cancelled_bookings
    from fct_bookings
    group by 1, 2, 3, 4

),

partner_cancellation_rate as (

    select
        partner_id,
        partner_name,
        partner_country,
        partner_tier,
        total_bookings,
        cancelled_bookings,
        round(
            -- taxa de cancelamento do parceiro
            100.0 * cancelled_bookings / nullif(total_bookings, 0),
            2
        ) as cancellation_rate_pct
    from partner_cancellations

),

stats as (

    select
        -- média e desvio-padrão da taxa de cancelamento entre parceiros
        avg(cancellation_rate_pct) as avg_cancellation_rate_pct,
        stddev_samp(cancellation_rate_pct) as stddev_cancellation_rate_pct
    from partner_cancellation_rate

)

select
    pcr.partner_id,
    pcr.partner_name,
    pcr.partner_country,
    pcr.partner_tier,
    pcr.total_bookings,
    pcr.cancelled_bookings,
    pcr.cancellation_rate_pct,
    round(s.avg_cancellation_rate_pct, 2) as avg_cancellation_rate_pct,
    round(s.stddev_cancellation_rate_pct, 2) as stddev_cancellation_rate_pct,
    round(
        -- z_score mostra quantos desvios-padrão o parceiro está acima/abaixo da média
        (pcr.cancellation_rate_pct - s.avg_cancellation_rate_pct)
        / nullif(s.stddev_cancellation_rate_pct, 0),
        2
    ) as z_score,
    case
        -- outlier estatístico solicitado no enunciado:
        -- taxa acima de média + 2 desvios-padrão
        when pcr.cancellation_rate_pct > s.avg_cancellation_rate_pct + 2 * s.stddev_cancellation_rate_pct
        then true
        else false
    end as is_outlier_gt_2sigma
from partner_cancellation_rate pcr
cross join stats s
-- primeiro mostra os outliers e depois os maiores cancelamentos
order by is_outlier_gt_2sigma desc, pcr.cancellation_rate_pct desc, pcr.total_bookings desc;