-- ============================================================
-- EXAM EVENT ANALYTICS
-- PostgreSQL SQL Analysis
-- ============================================================


-- ============================================================
-- Q1. Total number of events
-- ============================================================

SELECT
    COUNT(*) AS total_events
FROM candidate_log;


-- ============================================================
-- Q2. Total unique candidates
-- ============================================================

SELECT
    COUNT(DISTINCT candidate_id) AS unique_candidates
FROM candidate_log;


-- ============================================================
-- Q3. Exam time range
-- ============================================================

SELECT
    MIN(logged_at) AS first_event,
    MAX(logged_at) AS last_event
FROM candidate_log;


-- ============================================================
-- Q4. Activity types and their frequency
-- ============================================================

SELECT
    activity,
    COUNT(*) AS event_count
FROM candidate_log
GROUP BY activity
ORDER BY event_count DESC;


-- ============================================================
-- Q5. Check NULL values in important columns
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE log_id IS NULL) AS null_log_id,
    COUNT(*) FILTER (WHERE candidate_id IS NULL) AS null_candidate_id,
    COUNT(*) FILTER (WHERE logged_at IS NULL) AS null_logged_at,
    COUNT(*) FILTER (WHERE activity IS NULL) AS null_activity,
    COUNT(*) FILTER (WHERE question_section IS NULL) AS null_section,
    COUNT(*) FILTER (WHERE question_type IS NULL) AS null_question_type,
    COUNT(*) FILTER (WHERE question_language IS NULL) AS null_language,
    COUNT(*) FILTER (WHERE question_response IS NULL) AS null_response
FROM candidate_log;


-- ============================================================
-- Q6. Check whether candidate_id + log_id is unique
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (candidate_id, log_id)) AS unique_event_keys
FROM candidate_log;


-- ============================================================
-- Q7. Activity frequency and percentage
-- ============================================================

SELECT
    activity,
    COUNT(*) AS event_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM candidate_log
GROUP BY activity
ORDER BY event_count DESC;


-- ============================================================
-- Q8. Create cleaned event view
-- ============================================================

CREATE OR REPLACE VIEW candidate_log_clean AS
SELECT
    candidate_id,
    log_id,
    logged_at,
    subject_id,
    candidate_status,
    question_display_id,
    question_section,
    activity,
    question_type,
    question_language,
    question_response,
    all_options,

    CASE
        WHEN activity = 'Auto Save' THEN 1
        ELSE 0
    END AS is_auto_save,

    CASE
        WHEN activity <> 'Auto Save' THEN 1
        ELSE 0
    END AS is_manual_interaction

FROM candidate_log;


-- ============================================================
-- Q9. Preview cleaned event data
-- ============================================================

SELECT *
FROM candidate_log_clean
LIMIT 10;


-- ============================================================
-- Q10. Create candidate summary view
-- ============================================================

CREATE OR REPLACE VIEW candidate_summary AS
SELECT
    candidate_id,

    COUNT(*) AS total_events,

    SUM(is_auto_save) AS auto_save_events,

    SUM(is_manual_interaction) AS manual_interactions,

    COUNT(DISTINCT question_display_id) AS unique_questions,

    COUNT(DISTINCT question_section) AS sections_seen,

    COUNT(DISTINCT question_type) AS question_types_seen,

    COUNT(DISTINCT question_language) AS languages_seen,

    MIN(logged_at) AS first_observed_event,

    MAX(logged_at) AS last_observed_event,

    MAX(logged_at) - MIN(logged_at) AS observed_event_span

FROM candidate_log_clean

GROUP BY candidate_id;


-- ============================================================
-- Q11. Preview candidate summary
-- ============================================================

SELECT *
FROM candidate_summary
LIMIT 10;


-- ============================================================
-- Q12. Candidate-level average metrics
-- ============================================================

SELECT
    COUNT(*) AS candidates,

    ROUND(AVG(total_events), 2) AS avg_total_events,

    ROUND(AVG(manual_interactions), 2) AS avg_manual_interactions,

    ROUND(AVG(auto_save_events), 2) AS avg_auto_saves,

    ROUND(AVG(unique_questions), 2) AS avg_unique_questions,

    ROUND(AVG(sections_seen), 2) AS avg_sections_seen,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM observed_event_span) / 60
        ),
        2
    ) AS avg_observed_span_minutes

FROM candidate_summary;


-- ============================================================
-- Q13. Minimum and maximum candidate behavior
-- ============================================================

SELECT
    MIN(manual_interactions) AS min_manual_interactions,
    MAX(manual_interactions) AS max_manual_interactions,

    MIN(unique_questions) AS min_questions,
    MAX(unique_questions) AS max_questions,

    MIN(sections_seen) AS min_sections,
    MAX(sections_seen) AS max_sections

FROM candidate_summary;


-- ============================================================
-- Q14. Candidate manual interaction percentiles
-- ============================================================

SELECT
    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY manual_interactions)::numeric,
        2
    ) AS p25_manual,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY manual_interactions)::numeric,
        2
    ) AS median_manual,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY manual_interactions)::numeric,
        2
    ) AS p75_manual,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY manual_interactions)::numeric,
        2
    ) AS p90_manual,

    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY manual_interactions)::numeric,
        2
    ) AS p95_manual

FROM candidate_summary;


-- ============================================================
-- Q15. Create candidate behavior segmentation
-- ============================================================

CREATE OR REPLACE VIEW candidate_behavior AS
SELECT
    *,
    CASE
        WHEN manual_interactions <= 3
            THEN 'Low Interaction'

        WHEN manual_interactions <= 11
            THEN 'Typical Interaction'

        WHEN manual_interactions <= 20
            THEN 'High Interaction'

        ELSE 'Very High Interaction'
    END AS interaction_segment

FROM candidate_summary;


-- ============================================================
-- Q16. Candidate interaction segment distribution
-- ============================================================

SELECT
    interaction_segment,
    COUNT(*) AS candidates,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM candidate_behavior

GROUP BY interaction_segment

ORDER BY
    CASE interaction_segment
        WHEN 'Low Interaction' THEN 1
        WHEN 'Typical Interaction' THEN 2
        WHEN 'High Interaction' THEN 3
        WHEN 'Very High Interaction' THEN 4
    END;


-- ============================================================
-- Q17. Section-level interaction analysis
-- ============================================================

SELECT
    question_section,

    COUNT(*) AS total_events,

    COUNT(DISTINCT candidate_id) AS candidates,

    SUM(is_manual_interaction) AS manual_interactions,

    ROUND(
        SUM(is_manual_interaction) * 100.0
        / COUNT(*),
        2
    ) AS manual_interaction_rate

FROM candidate_log_clean

GROUP BY question_section

ORDER BY question_section;


-- ============================================================
-- Q18. Most interacted-with questions
-- ============================================================

SELECT
    question_section,
    question_display_id,
    question_type,
    question_language,

    COUNT(*) AS total_events,

    COUNT(DISTINCT candidate_id) AS candidates,

    SUM(is_manual_interaction) AS manual_interactions

FROM candidate_log_clean

GROUP BY
    question_section,
    question_display_id,
    question_type,
    question_language

ORDER BY manual_interactions DESC

LIMIT 20;


-- ============================================================
-- Q19. Normalized question interaction intensity
-- ============================================================

SELECT
    question_section,
    question_display_id,
    question_type,
    question_language,

    COUNT(DISTINCT candidate_id) AS candidates,

    SUM(is_manual_interaction) AS manual_interactions,

    ROUND(
        SUM(is_manual_interaction)::numeric
        / NULLIF(COUNT(DISTINCT candidate_id), 0),
        2
    ) AS manual_interactions_per_candidate

FROM candidate_log_clean

GROUP BY
    question_section,
    question_display_id,
    question_type,
    question_language

HAVING COUNT(DISTINCT candidate_id) >= 1000

ORDER BY manual_interactions_per_candidate DESC

LIMIT 20;


-- ============================================================
-- Q20. Compare question types and languages
-- ============================================================

SELECT
    question_type,
    question_language,

    COUNT(DISTINCT candidate_id) AS candidates,

    SUM(is_manual_interaction) AS manual_interactions,

    ROUND(
        SUM(is_manual_interaction)::numeric
        / NULLIF(COUNT(DISTINCT candidate_id), 0),
        2
    ) AS manual_interactions_per_candidate

FROM candidate_log_clean

GROUP BY
    question_type,
    question_language;


-- ============================================================
-- Q21. Time-of-day / hourly event analysis
-- ============================================================

SELECT
    DATE_TRUNC('hour', logged_at) AS hour,

    COUNT(*) AS total_events,

    SUM(is_manual_interaction) AS manual_interactions,

    COUNT(DISTINCT candidate_id) AS active_candidates

FROM candidate_log_clean

GROUP BY DATE_TRUNC('hour', logged_at)

ORDER BY hour;


-- ============================================================
-- Q22. Hourly manual interaction rate
-- ============================================================

SELECT
    DATE_TRUNC('hour', logged_at) AS hour,

    COUNT(*) AS total_events,

    SUM(is_manual_interaction) AS manual_interactions,

    COUNT(DISTINCT candidate_id) AS active_candidates,

    ROUND(
        SUM(is_manual_interaction)::numeric
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS manual_interaction_rate

FROM candidate_log_clean

GROUP BY DATE_TRUNC('hour', logged_at)

ORDER BY hour;


-- ============================================================
-- Q23. Create hourly behavior view
-- ============================================================

CREATE OR REPLACE VIEW hourly_behavior AS
SELECT
    DATE_TRUNC('hour', logged_at) AS hour,

    COUNT(*) AS total_events,

    SUM(is_manual_interaction) AS manual_interactions,

    COUNT(DISTINCT candidate_id) AS active_candidates,

    ROUND(
        SUM(is_manual_interaction)::numeric
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS manual_interaction_rate

FROM candidate_log_clean

GROUP BY DATE_TRUNC('hour', logged_at);


-- ============================================================
-- Q24. Create section behavior view
-- ============================================================

CREATE OR REPLACE VIEW section_behavior AS
SELECT
    question_section,

    COUNT(*) AS total_events,

    COUNT(DISTINCT candidate_id) AS candidates,

    SUM(is_manual_interaction) AS manual_interactions,

    ROUND(
        SUM(is_manual_interaction)::numeric
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS manual_interaction_rate

FROM candidate_log_clean

GROUP BY question_section;


-- ============================================================
-- Q25. Create question behavior view
-- ============================================================

CREATE OR REPLACE VIEW question_behavior AS
SELECT
    question_section,
    question_display_id,
    question_type,
    question_language,

    COUNT(DISTINCT candidate_id) AS candidates,

    COUNT(*) AS total_events,

    SUM(is_manual_interaction) AS manual_interactions,

    ROUND(
        SUM(is_manual_interaction)::numeric
        / NULLIF(COUNT(DISTINCT candidate_id), 0),
        2
    ) AS manual_interactions_per_candidate

FROM candidate_log_clean

GROUP BY
    question_section,
    question_display_id,
    question_type,
    question_language;