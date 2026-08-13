# Exam Event Analytics – Power BI Dashboard

## Project Overview

This project analyzes exam-event telemetry to understand candidate activity, manual interaction behavior, section-level patterns, hourly activity, and question-level interaction intensity.

The analysis was developed using PostgreSQL and Microsoft Power BI.

## Dataset Summary

- Candidates: 88,001
- Recorded events: approximately 8.25 million
- Manual interactions: approximately 764K
- Average manual interactions per candidate: 8.69
- Average questions observed: 24.83
- Average sections observed: approximately 3.95
- Auto Save rate: 90.73%
- Questions analyzed: 25

## Dashboard Pages

### 1. Exam Overview

Provides a high-level view of:

- Total candidates
- Total events
- Manual interactions
- Average manual interactions
- Auto Save rate
- Events over time
- Active candidates over time
- Manual interaction rate over time
- Candidate interaction segments
- Section interaction rates
- Question type and language interaction patterns

### 2. Candidate Behavior

Provides a deeper view of:

- Candidate interaction segments
- Average manual interactions by segment
- Average questions observed
- Average sections observed
- Candidate-level behavior details

### 3. Question Analysis

Provides:

- Section filter
- Language filter
- Question type filter
- Interaction intensity by question type and language
- Top questions by interaction intensity
- Question-level analysis for all 25 questions

## Key Findings

1. Auto Save events represent approximately 90.73% of recorded activity.
2. Typical Interaction is the largest candidate segment at 46.32%.
3. Section 4 has the lowest observed manual interaction rate at approximately 7.66%.
4. Interaction activity varies substantially across exam hours.
5. Question 25 appears as a notable interaction-intensity outlier.
6. Interaction telemetry should not be interpreted as exam performance or question correctness.

## Recommendations

- Investigate questions with unusually high interaction intensity.
- Review whether interaction patterns are associated with question design or navigation behavior.
- Compare interaction behavior across sections and languages.
- Combine telemetry with scores and answer correctness before evaluating question difficulty or candidate performance.

## Limitations

The dataset contains event telemetry rather than exam scores or answer correctness. Therefore, interaction frequency should not automatically be interpreted as candidate performance or question difficulty.

Some hourly periods contain relatively few observations, so small-sample spikes should be interpreted cautiously.

## Tools Used

- PostgreSQL
- SQL
- Microsoft Power BI
- GitHub

## Repository Contents

- `powerbi/` – Power BI dashboard
- `report/` – PDF report and insights document
- `screenshots/` – Dashboard screenshots
- `sql/` – SQL analysis scripts
