-- Quant Study Tracker - PostgreSQL Schema
-- Run this on your Neon database

-- 1. Phases (from roadmap: Phase 0-10 + Quant Engineering)
CREATE TABLE IF NOT EXISTS phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  phase_number INTEGER NOT NULL,
  duration_weeks INTEGER,
  hours_per_week INTEGER,
  weight INTEGER DEFAULT 5,
  description TEXT,
  display_order INTEGER,
  color TEXT DEFAULT '#666',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Activities / Topics within each phase
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_id UUID REFERENCES phases(id),
  name TEXT NOT NULL,
  category TEXT DEFAULT 'task',
  sub_category TEXT,
  status TEXT DEFAULT 'pending',
  estimated_minutes INTEGER,
  resource_url TEXT,
  resource_name TEXT,
  notes TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Schedule (MBA classes + study blocks + projects)
CREATE TABLE IF NOT EXISTS schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  activity_id UUID REFERENCES activities(id),
  phase_id UUID REFERENCES phases(id),
  category TEXT DEFAULT 'study',
  subject TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  is_recurring BOOLEAN DEFAULT false,
  recurrence_rule TEXT,
  color TEXT DEFAULT '#4a90d9',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Time Logs (study session tracking)
CREATE TABLE IF NOT EXISTS time_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID REFERENCES activities(id),
  phase_id UUID REFERENCES phases(id),
  duration_minutes INTEGER NOT NULL,
  logged_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  source TEXT DEFAULT 'manual'
);

-- 5. Projects & Challenges
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT DEFAULT 'project',
  phase_id UUID REFERENCES phases(id),
  is_completed BOOLEAN DEFAULT false,
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Books
CREATE TABLE IF NOT EXISTS books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  author TEXT,
  phase_id UUID REFERENCES phases(id),
  status TEXT DEFAULT 'not_started',
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Journal / Notes
CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  mood TEXT,
  phase_id UUID REFERENCES phases(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Daily Stats (auto-computed via API)
CREATE TABLE IF NOT EXISTS daily_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL UNIQUE,
  total_minutes INTEGER DEFAULT 0,
  phases_studied TEXT[] DEFAULT '{}',
  has_streak BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Weekly Reports (generated)
CREATE TABLE IF NOT EXISTS weekly_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,
  total_minutes INTEGER DEFAULT 0,
  phase_breakdown JSONB DEFAULT '{}',
  schedule_adherence NUMERIC(5,2) DEFAULT 0,
  streak_count INTEGER DEFAULT 0,
  best_day DATE,
  worst_day DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_activities_phase ON activities(phase_id);
CREATE INDEX IF NOT EXISTS idx_schedule_start ON schedule(start_time);
CREATE INDEX IF NOT EXISTS idx_schedule_phase ON schedule(phase_id);
CREATE INDEX IF NOT EXISTS idx_time_logs_date ON time_logs(logged_at);
CREATE INDEX IF NOT EXISTS idx_time_logs_phase ON time_logs(phase_id);
CREATE INDEX IF NOT EXISTS idx_journal_created ON journal_entries(created_at);
CREATE INDEX IF NOT EXISTS idx_books_phase ON books(phase_id);
CREATE INDEX IF NOT EXISTS idx_projects_phase ON projects(phase_id);