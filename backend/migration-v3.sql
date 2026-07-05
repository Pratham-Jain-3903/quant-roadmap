-- Migration v3: mastery, evidence, review queue, and role-track metadata

ALTER TABLE activities ADD COLUMN IF NOT EXISTS skill_tags TEXT[] DEFAULT '{}';
ALTER TABLE activities ADD COLUMN IF NOT EXISTS mastery_score INTEGER DEFAULT 0 CHECK (mastery_score BETWEEN 0 AND 100);
ALTER TABLE activities ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS next_review_at TIMESTAMPTZ;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS evidence_url TEXT;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS assessment_type TEXT DEFAULT 'task';
ALTER TABLE activities ADD COLUMN IF NOT EXISTS pass_criteria TEXT;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS why_this_task TEXT;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS role_track TEXT DEFAULT 'core';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS evidence_url TEXT;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS validation_notes TEXT;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS result_summary TEXT;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS interview_story TEXT;

CREATE TABLE IF NOT EXISTS skill_mastery (
  skill_id TEXT PRIMARY KEY,
  skill_name TEXT NOT NULL,
  score INTEGER DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  evidence_count INTEGER DEFAULT 0,
  last_assessed_at TIMESTAMPTZ,
  next_review_at TIMESTAMPTZ,
  confidence INTEGER DEFAULT 0 CHECK (confidence BETWEEN 0 AND 100),
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activities_next_review ON activities(next_review_at);
CREATE INDEX IF NOT EXISTS idx_activities_skill_tags ON activities USING GIN(skill_tags);
CREATE INDEX IF NOT EXISTS idx_skill_mastery_next_review ON skill_mastery(next_review_at);

UPDATE activities
SET assessment_type = CASE
  WHEN category ILIKE '%book%' OR name ILIKE 'Read %' THEN 'reading'
  WHEN category ILIKE '%project%' OR name ILIKE '%build%' OR name ILIKE '%implement%' THEN 'project'
  WHEN name ILIKE '%solve%' OR name ILIKE '%problem%' THEN 'problem_set'
  WHEN name ILIKE '%mock%' OR category ILIKE '%interview%' THEN 'mock_interview'
  WHEN name ILIKE '%report%' OR name ILIKE '%research%' THEN 'write_up'
  ELSE COALESCE(assessment_type, 'task')
END
WHERE assessment_type IS NULL OR assessment_type = 'task';

UPDATE activities
SET skill_tags = ARRAY_REMOVE(ARRAY[
  CASE WHEN name ILIKE '%probab%' OR name ILIKE '%bayes%' OR name ILIKE '%EV%' OR name ILIKE '%combinator%' THEN 'probability' END,
  CASE WHEN name ILIKE '%stat%' OR name ILIKE '%confidence%' OR name ILIKE '%hypothesis%' THEN 'statistics' END,
  CASE WHEN name ILIKE '%option%' OR name ILIKE '%black-scholes%' OR name ILIKE '%greek%' OR name ILIKE '%hedg%' THEN 'options' END,
  CASE WHEN name ILIKE '%portfolio%' OR name ILIKE '%factor%' OR name ILIKE '%risk parity%' THEN 'portfolio' END,
  CASE WHEN name ILIKE '%backtest%' OR name ILIKE '%alpha%' THEN 'backtesting' END,
  CASE WHEN name ILIKE '%data%' OR name ILIKE '%pipeline%' OR name ILIKE '%SQL%' THEN 'data_engineering' END,
  CASE WHEN name ILIKE '%C++%' OR name ILIKE '%engine%' OR name ILIKE '%execution%' OR name ILIKE '%order%' THEN 'systems' END,
  CASE WHEN name ILIKE '%valuation%' OR name ILIKE '%DCF%' OR name ILIKE '%Damodaran%' THEN 'valuation' END
], NULL)
WHERE skill_tags = '{}' OR skill_tags IS NULL;

UPDATE activities
SET pass_criteria = CASE assessment_type
  WHEN 'reading' THEN 'Write a 5-bullet recall summary and one open question.'
  WHEN 'problem_set' THEN 'Record attempted/correct score and review misses.'
  WHEN 'project' THEN 'Attach evidence URL, validation notes, and result summary.'
  WHEN 'mock_interview' THEN 'Record self/interviewer score and misses.'
  WHEN 'write_up' THEN 'Attach a concise thesis, result, and caveats.'
  ELSE 'Write recall notes and mark what changed in your understanding.'
END
WHERE pass_criteria IS NULL;

UPDATE activities
SET why_this_task = CASE
  WHEN skill_tags && ARRAY['probability'] THEN 'Builds the probability base used in quant interviews and modeling.'
  WHEN skill_tags && ARRAY['statistics'] THEN 'Turns market observations into defensible inference.'
  WHEN skill_tags && ARRAY['options'] THEN 'Supports derivatives interviews, Greeks, and hedging intuition.'
  WHEN skill_tags && ARRAY['portfolio'] THEN 'Connects research ideas to AWM and portfolio construction.'
  WHEN skill_tags && ARRAY['backtesting'] THEN 'Converts ideas into tested strategies with leakage checks.'
  WHEN skill_tags && ARRAY['data_engineering','systems'] THEN 'Builds the trading infrastructure credibility behind research work.'
  ELSE 'Moves the roadmap toward verifiable quant capability.'
END
WHERE why_this_task IS NULL;

UPDATE activities
SET role_track = CASE
  WHEN skill_tags && ARRAY['data_engineering','systems'] THEN 'quant_dev'
  WHEN skill_tags && ARRAY['portfolio','backtesting','statistics'] THEN 'awm_quant'
  WHEN skill_tags && ARRAY['options','probability'] THEN 'options_mm'
  ELSE 'core'
END
WHERE role_track IS NULL OR role_track = 'core';

INSERT INTO skill_mastery (skill_id, skill_name, score, evidence_count, last_assessed_at, next_review_at, confidence, notes)
SELECT
  tag,
  INITCAP(REPLACE(tag, '_', ' ')),
  COALESCE(ROUND(AVG(NULLIF(a.mastery_score, 0)))::INTEGER, 0),
  COUNT(*) FILTER (WHERE a.evidence_url IS NOT NULL),
  MAX(a.completed_at),
  MIN(a.next_review_at),
  LEAST(100, COUNT(*) FILTER (WHERE a.status = 'completed') * 10),
  'Auto-created from activity skill tags.'
FROM activities a
CROSS JOIN LATERAL UNNEST(COALESCE(a.skill_tags, '{}')) AS tag
GROUP BY tag
ON CONFLICT (skill_id) DO UPDATE SET
  skill_name = EXCLUDED.skill_name,
  evidence_count = EXCLUDED.evidence_count,
  last_assessed_at = EXCLUDED.last_assessed_at,
  next_review_at = EXCLUDED.next_review_at,
  confidence = EXCLUDED.confidence,
  updated_at = NOW();
