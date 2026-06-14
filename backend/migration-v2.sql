-- Migration v2: DAG Prerequisites + Reflections + Activity improvements
-- Run this AFTER schema.sql and seed.sql have been applied

-- Add new columns to activities
ALTER TABLE activities ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS difficulty INTEGER DEFAULT 1;

-- Prerequisites (DAG edges)
CREATE TABLE IF NOT EXISTS activity_prerequisites (
  activity_id UUID REFERENCES activities(id) ON DELETE CASCADE,
  prerequisite_id UUID REFERENCES activities(id) ON DELETE CASCADE,
  PRIMARY KEY (activity_id, prerequisite_id)
);

-- Activity Reflections (recall gate)
CREATE TABLE IF NOT EXISTS activity_reflections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID REFERENCES activities(id),
  phase_id UUID REFERENCES phases(id),
  content TEXT NOT NULL,
  key_takeaways TEXT[] DEFAULT '{}',
  difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5),
  time_spent_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_time_logs_activity ON time_logs(activity_id);
CREATE INDEX IF NOT EXISTS idx_prereqs_activity ON activity_prerequisites(activity_id);
CREATE INDEX IF NOT EXISTS idx_prereqs_prerequisite ON activity_prerequisites(prerequisite_id);
CREATE INDEX IF NOT EXISTS idx_reflections_activity ON activity_reflections(activity_id);

-- ============================================
-- SEED PREREQUISITES (DAG edges)
-- Each activity must have its prerequisites completed before becoming available
-- ============================================
INSERT INTO activity_prerequisites (activity_id, prerequisite_id)
SELECT a1.id, a2.id
FROM activities a1
JOIN activities a2 ON a1.phase_id = a2.phase_id
WHERE 
  -- Phase 0: Finance Foundations - sequential
  (a1.name LIKE 'Find bond yields%' AND a2.name LIKE 'Define & compute market cap%') OR
  (a1.name LIKE 'Find bond yields%' AND a2.name LIKE 'Damodaran Foundations%') OR
  
  -- Phase 1: Probability - sequential
  (a1.name LIKE 'Implement Monte Carlo%' AND a2.name LIKE 'Solve EV puzzles%') OR
  (a1.name LIKE 'Implement Monte Carlo%' AND a2.name LIKE 'Blitzstein Introduction%') OR
  (a1.name LIKE 'Build Kelly criterion%' AND a2.name LIKE 'Implement Monte Carlo%') OR
  (a1.name LIKE 'Compute confidence intervals%' AND a2.name LIKE 'Implement Monte Carlo%') OR
  
  -- Phase 2: Financial Math - sequential
  (a1.name LIKE 'Implement bond pricer%' AND a2.name LIKE 'Shreve Financial%') OR
  (a1.name LIKE 'Create binomial tree%' AND a2.name LIKE 'Implement bond pricer%') OR
  (a1.name LIKE 'Build Black-Scholes pricer%' AND a2.name LIKE 'Create binomial tree%') OR
  (a1.name LIKE 'Portfolio optimization%' AND a2.name LIKE 'Build Black-Scholes pricer%') OR
  
  -- Phase 3: Valuation - sequential
  (a1.name LIKE 'DCF Valuation: TCS%' AND a2.name LIKE 'Damodaran Valuation Course%') OR
  (a1.name LIKE 'DCF Valuation: Reliance%' AND a2.name LIKE 'DCF Valuation: TCS%') OR
  (a1.name LIKE 'DCF Valuation: HDFC%' AND a2.name LIKE 'DCF Valuation: Reliance%') OR
  (a1.name LIKE 'Prepare 5-page valuation%' AND a2.name LIKE 'DCF Valuation: HDFC%') OR
  
  -- Phase 4: Portfolio Theory - sequential
  (a1.name LIKE 'Build mini BlackRock%' AND a2.name LIKE 'Expected Returns%') OR
  (a1.name LIKE 'Implement Mean-Variance%' AND a2.name LIKE 'Build mini BlackRock%') OR
  (a1.name LIKE 'Implement Risk Parity%' AND a2.name LIKE 'Implement Mean-Variance%') OR
  (a1.name LIKE 'Backtest with simple%' AND a2.name LIKE 'Implement Risk Parity%') OR
  
  -- Phase 5: Time Series - sequential
  (a1.name LIKE 'Forecast NIFTY%' AND a2.name LIKE 'Forecasting: Principles%') OR
  (a1.name LIKE 'Model India VIX%' AND a2.name LIKE 'Forecast NIFTY%') OR
  (a1.name LIKE 'Build regime-switching%' AND a2.name LIKE 'Model India VIX%') OR
  
  -- Phase 6: Derivatives - sequential
  (a1.name LIKE 'Implement Black-Scholes%' AND a2.name LIKE 'Hull Options%') OR
  (a1.name LIKE 'Build binomial option%' AND a2.name LIKE 'Implement Black-Scholes%') OR
  (a1.name LIKE 'Compute Greeks%' AND a2.name LIKE 'Build binomial option%') OR
  (a1.name LIKE 'Simulate hedging%' AND a2.name LIKE 'Compute Greeks%') OR
  (a1.name LIKE 'Build options market-making%' AND a2.name LIKE 'Simulate hedging%') OR
  
  -- Phase 7: Game Theory - sequential
  (a1.name LIKE 'Simulate market-making%' AND a2.name LIKE 'Game Theory 101%') OR
  (a1.name LIKE 'Model exchange auction%' AND a2.name LIKE 'Simulate market-making%') OR
  (a1.name LIKE 'Implement Nash equilibrium%' AND a2.name LIKE 'Model exchange auction%') OR
  
  -- Phase 8: Financial ML - sequential
  (a1.name LIKE 'Build alpha pipeline%' AND a2.name LIKE 'Advances in Financial ML%') OR
  (a1.name LIKE 'Train XGBoost model%' AND a2.name LIKE 'Build alpha pipeline%') OR
  (a1.name LIKE 'Implement backtesting%' AND a2.name LIKE 'Train XGBoost model%') OR
  
  -- Phase 9: RL - sequential
  (a1.name LIKE 'Simulate RL agent for portfolio%' AND a2.name LIKE 'David Silver UCL%') OR
  (a1.name LIKE 'RL agent for trade%' AND a2.name LIKE 'Simulate RL agent for portfolio%') OR
  
  -- Phase 10: Engineering - sequential
  (a1.name LIKE 'Build data pipeline%' AND a2.name LIKE 'Designing Data-Intensive%') OR
  (a1.name LIKE 'Build factor engine%' AND a2.name LIKE 'Build data pipeline%') OR
  (a1.name LIKE 'Productionize portfolio%' AND a2.name LIKE 'Build factor engine%') OR
  (a1.name LIKE 'Build risk engine%' AND a2.name LIKE 'Productionize portfolio%') OR
  (a1.name LIKE 'Mock order execution%' AND a2.name LIKE 'Build risk engine%')
ON CONFLICT DO NOTHING;

-- Inter-phase prerequisites
-- Phase 1 requires Phase 0 completion (all Phase 0 activities done)
INSERT INTO activity_prerequisites (activity_id, prerequisite_id)
SELECT a1.id, a2.id
FROM activities a1, activities a2
WHERE a1.phase_id = 'a0000000-0000-0000-0000-000000000001'
  AND a2.phase_id = 'a0000000-0000-0000-0000-000000000000'
  AND a2.name LIKE 'Find bond yields%'
ON CONFLICT DO NOTHING;

-- Phase 2 requires Phase 1 completion
INSERT INTO activity_prerequisites (activity_id, prerequisite_id)
SELECT a1.id, a2.id
FROM activities a1, activities a2
WHERE a1.phase_id = 'a0000000-0000-0000-0000-000000000002'
  AND a2.phase_id = 'a0000000-0000-0000-0000-000000000001'
  AND a2.name LIKE 'Build Kelly criterion%'
ON CONFLICT DO NOTHING;

-- Phase 3 requires Phase 2 completion
INSERT INTO activity_prerequisites (activity_id, prerequisite_id)
SELECT a1.id, a2.id
FROM activities a1, activities a2
WHERE a1.phase_id = 'a0000000-0000-0000-0000-000000000003'
  AND a2.phase_id = 'a0000000-0000-0000-0000-000000000002'
  AND a2.name LIKE 'Portfolio optimization%'
ON CONFLICT DO NOTHING;

-- Phase 4 requires Phase 3 completion
INSERT INTO activity_prerequisites (activity_id, prerequisite_id)
SELECT a1.id, a2.id
FROM activities a1, activities a2
WHERE a1.phase_id = 'a0000000-0000-0000-0000-000000000004'
  AND a2.phase_id = 'a0000000-0000-0000-0000-000000000003'
  AND a2.name LIKE 'Prepare 5-page valuation%'
ON CONFLICT DO NOTHING;

-- Set display_order for activities within each phase
UPDATE activities SET display_order = 1 WHERE name LIKE 'Read Little Book%';
UPDATE activities SET display_order = 2 WHERE name LIKE 'Read Intelligent%';
UPDATE activities SET display_order = 3 WHERE name LIKE 'Damodaran Foundations%';
UPDATE activities SET display_order = 4 WHERE name LIKE 'Damodaran Corporate%';
UPDATE activities SET display_order = 5 WHERE name LIKE 'Khan Academy Finance%';
UPDATE activities SET display_order = 6 WHERE name LIKE 'Define & compute market%';
UPDATE activities SET display_order = 7 WHERE name LIKE 'Find bond yields%';
UPDATE activities SET display_order = 8 WHERE name LIKE 'Read Investopedia%';
UPDATE activities SET display_order = 9 WHERE name LIKE 'Study Damodaran valuation%';

UPDATE activities SET display_order = 1 WHERE name LIKE 'Blitzstein Introduction%';
UPDATE activities SET display_order = 2 WHERE name LIKE 'Mosteller 50%';
UPDATE activities SET display_order = 3 WHERE name LIKE 'Heard on the Street%';
UPDATE activities SET display_order = 4 WHERE name LIKE 'MIT OCW 6.041%';
UPDATE activities SET display_order = 5 WHERE name LIKE 'Harvard Stat110%';
UPDATE activities SET display_order = 6 WHERE name LIKE 'Solve EV puzzles%';
UPDATE activities SET display_order = 7 WHERE name LIKE 'Implement Monte Carlo%';
UPDATE activities SET display_order = 8 WHERE name LIKE 'Compute confidence%';
UPDATE activities SET display_order = 9 WHERE name LIKE 'Build Kelly criterion%';

-- Set difficulty ratings
UPDATE activities SET difficulty = 1 WHERE estimated_minutes <= 120;
UPDATE activities SET difficulty = 2 WHERE estimated_minutes > 120 AND estimated_minutes <= 240;
UPDATE activities SET difficulty = 3 WHERE estimated_minutes > 240 AND estimated_minutes <= 360;
UPDATE activities SET difficulty = 4 WHERE estimated_minutes > 360 AND estimated_minutes <= 480;
UPDATE activities SET difficulty = 5 WHERE estimated_minutes > 480;
ALTER TABLE schedule ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;
