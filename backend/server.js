const express = require('express');
const cors = require('cors');
const db = require('./db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ============================================
// PHASES
// ============================================
app.get('/api/phases', async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM phases ORDER BY display_order'
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/phases/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, duration_weeks, hours_per_week, weight, description, color, progress_pct } = req.body;
    const result = await db.query(
      `UPDATE phases SET 
        name = COALESCE($1, name),
        duration_weeks = COALESCE($2, duration_weeks),
        hours_per_week = COALESCE($3, hours_per_week),
        weight = COALESCE($4, weight),
        description = COALESCE($5, description),
        color = COALESCE($6, color)
       WHERE id = $7 RETURNING *`,
      [name, duration_weeks, hours_per_week, weight, description, color, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// ACTIVITIES
// ============================================
app.get('/api/activities', async (req, res) => {
  try {
    const { phase_id, category } = req.query;
    let query = 'SELECT a.*, p.name as phase_name, p.color as phase_color FROM activities a JOIN phases p ON a.phase_id = p.id';
    const params = [];
    const conditions = [];

    if (phase_id) {
      conditions.push(`a.phase_id = $${params.length + 1}`);
      params.push(phase_id);
    }
    if (category) {
      conditions.push(`a.category = $${params.length + 1}`);
      params.push(category);
    }

    if (conditions.length) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    query += ' ORDER BY a.created_at';

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/activities/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const completed_at = status === 'completed' ? new Date() : null;
    const result = await db.query(
      `UPDATE activities SET 
        status = COALESCE($1, status),
        notes = COALESCE($2, notes),
        completed_at = $3
       WHERE id = $4 RETURNING *`,
      [status, notes, completed_at, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// SCHEDULE
// ============================================
app.get('/api/schedule', async (req, res) => {
  try {
    const { start, end, category } = req.query;
    let query = `
      SELECT s.*, p.name as phase_name, p.color as phase_color 
      FROM schedule s 
      LEFT JOIN phases p ON s.phase_id = p.id
    `;
    const params = [];
    const conditions = [];

    if (start) {
      conditions.push(`s.start_time >= $${params.length + 1}`);
      params.push(start);
    }
    if (end) {
      conditions.push(`s.end_time <= $${params.length + 1}`);
      params.push(end);
    }
    if (category) {
      conditions.push(`s.category = $${params.length + 1}`);
      params.push(category);
    }

    if (conditions.length) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    query += ' ORDER BY s.start_time';

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/schedule', async (req, res) => {
  try {
    const { title, description, phase_id, category, subject, start_time, end_time, color } = req.body;
    const result = await db.query(
      `INSERT INTO schedule (title, description, phase_id, category, subject, start_time, end_time, color)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [title, description, phase_id, category || 'study', subject, start_time, end_time, color || '#4a90d9']
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/schedule/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, phase_id, category, start_time, end_time, color } = req.body;
    const result = await db.query(
      `UPDATE schedule SET
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        phase_id = COALESCE($3, phase_id),
        category = COALESCE($4, category),
        start_time = COALESCE($5, start_time),
        end_time = COALESCE($6, end_time),
        color = COALESCE($7, color),
        updated_at = NOW()
       WHERE id = $8 RETURNING *`,
      [title, description, phase_id, category, start_time, end_time, color, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/schedule/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('DELETE FROM schedule WHERE id = $1', [id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// TIME LOGS
// ============================================
app.get('/api/time-logs', async (req, res) => {
  try {
    const { date, phase_id, start, end } = req.query;
    let query = `
      SELECT tl.*, p.name as phase_name, p.color as phase_color
      FROM time_logs tl
      JOIN phases p ON tl.phase_id = p.id
    `;
    const params = [];
    const conditions = [];

    if (date) {
      conditions.push(`DATE(tl.logged_at) = $${params.length + 1}`);
      params.push(date);
    }
    if (phase_id) {
      conditions.push(`tl.phase_id = $${params.length + 1}`);
      params.push(phase_id);
    }
    if (start) {
      conditions.push(`tl.logged_at >= $${params.length + 1}`);
      params.push(start);
    }
    if (end) {
      conditions.push(`tl.logged_at <= $${params.length + 1}`);
      params.push(end);
    }

    if (conditions.length) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    query += ' ORDER BY tl.logged_at DESC';

    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/time-logs', async (req, res) => {
  try {
    const { activity_id, phase_id, duration_minutes, notes, source } = req.body;
    const result = await db.query(
      `INSERT INTO time_logs (activity_id, phase_id, duration_minutes, notes, source)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [activity_id, phase_id, duration_minutes, notes, source || 'manual']
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// PROJECTS
// ============================================
app.get('/api/projects', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT pr.*, p.name as phase_name, p.color as phase_color
       FROM projects pr
       LEFT JOIN phases p ON pr.phase_id = p.id
       ORDER BY pr.category, pr.name`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/projects/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { is_completed, notes } = req.body;
    const result = await db.query(
      `UPDATE projects SET
        is_completed = COALESCE($1, is_completed),
        notes = COALESCE($2, notes),
        updated_at = NOW()
       WHERE id = $3 RETURNING *`,
      [is_completed, notes, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// BOOKS
// ============================================
app.get('/api/books', async (req, res) => {
  try {
    const { phase_id } = req.query;
    let query = `
      SELECT b.*, p.name as phase_name, p.color as phase_color
      FROM books b
      LEFT JOIN phases p ON b.phase_id = p.id
    `;
    const params = [];
    if (phase_id) {
      query += ' WHERE b.phase_id = $1';
      params.push(phase_id);
    }
    query += ' ORDER BY b.title';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/books/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const result = await db.query(
      `UPDATE books SET
        status = COALESCE($1, status),
        notes = COALESCE($2, notes),
        updated_at = NOW()
       WHERE id = $3 RETURNING *`,
      [status, notes, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// JOURNAL
// ============================================
app.get('/api/journal', async (req, res) => {
  try {
    const { limit } = req.query;
    let query = `
      SELECT j.*, p.name as phase_name
      FROM journal_entries j
      LEFT JOIN phases p ON j.phase_id = p.id
      ORDER BY j.created_at DESC
    `;
    if (limit) {
      query += ' LIMIT $1';
      const result = await db.query(query, [parseInt(limit)]);
      return res.json(result.rows);
    }
    const result = await db.query(query);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/journal', async (req, res) => {
  try {
    const { content, mood, phase_id } = req.body;
    const result = await db.query(
      `INSERT INTO journal_entries (content, mood, phase_id) VALUES ($1, $2, $3) RETURNING *`,
      [content, mood, phase_id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// DASHBOARD (aggregated data)
// ============================================
app.get('/api/dashboard', async (req, res) => {
  try {
    // Today's total minutes
    const todayResult = await db.query(
      `SELECT COALESCE(SUM(duration_minutes), 0) as total_minutes
       FROM time_logs WHERE DATE(logged_at) = CURRENT_DATE`
    );
    const todayMinutes = parseInt(todayResult.rows[0].total_minutes);

    // Today's schedule
    const todaySchedule = await db.query(
      `SELECT * FROM schedule 
       WHERE DATE(start_time) = CURRENT_DATE 
       ORDER BY start_time`
    );

    // Upcoming schedule (next 7 days)
    const upcoming = await db.query(
      `SELECT * FROM schedule 
       WHERE start_time >= CURRENT_DATE 
       AND start_time < CURRENT_DATE + INTERVAL '7 days'
       ORDER BY start_time
       LIMIT 20`
    );

    // Streak calculation
    const streakResult = await db.query(
      `WITH days AS (
        SELECT DISTINCT DATE(logged_at) as study_date
        FROM time_logs
        ORDER BY study_date DESC
      )
      SELECT study_date FROM days LIMIT 60`
    );

    let streak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    for (let i = 0; i < streakResult.rows.length; i++) {
      const d = new Date(streakResult.rows[i].study_date);
      const expected = new Date(today);
      expected.setDate(expected.getDate() - i);
      if (d.getTime() === expected.getTime()) {
        streak++;
      } else {
        break;
      }
    }

    // Phase progress
    const phaseProgress = await db.query(
      `SELECT p.id, p.name, p.weight, p.color,
        COUNT(a.id) FILTER (WHERE a.status = 'completed') as completed_activities,
        COUNT(a.id) as total_activities
       FROM phases p
       LEFT JOIN activities a ON p.id = a.phase_id
       GROUP BY p.id, p.name, p.weight, p.color, p.display_order
       ORDER BY p.display_order`
    );

    // Weekly totals (last 7 days)
    const weeklyTotals = await db.query(
      `SELECT DATE(logged_at) as date, SUM(duration_minutes) as minutes
       FROM time_logs
       WHERE logged_at >= CURRENT_DATE - INTERVAL '7 days'
       GROUP BY DATE(logged_at)
       ORDER BY date`
    );

    // Total hours this week
    const weekStart = await db.query(
      `SELECT COALESCE(SUM(duration_minutes), 0) as total
       FROM time_logs
       WHERE logged_at >= DATE_TRUNC('week', CURRENT_DATE)`
    );

    res.json({
      today_minutes: todayMinutes,
      today_hours: (todayMinutes / 60).toFixed(1),
      today_schedule: todaySchedule.rows,
      upcoming: upcoming.rows,
      streak,
      phase_progress: phaseProgress.rows,
      weekly_totals: weeklyTotals.rows,
      week_total_minutes: parseInt(weekStart.rows[0].total),
      week_total_hours: (parseInt(weekStart.rows[0].total) / 60).toFixed(1)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// WEEKLY REPORT
// ============================================
app.get('/api/weekly-report', async (req, res) => {
  try {
    const weekStart = req.query.week_start 
      ? req.query.week_start 
      : new Date(new Date().setDate(new Date().getDate() - new Date().getDay())).toISOString().split('T')[0];

    const totalMinutes = await db.query(
      `SELECT COALESCE(SUM(duration_minutes), 0) as total
       FROM time_logs WHERE DATE(logged_at) >= $1 AND DATE(logged_at) < $1 + INTERVAL '7 days'`,
      [weekStart]
    );

    const phaseBreakdown = await db.query(
      `SELECT p.name, p.color, SUM(tl.duration_minutes) as minutes
       FROM time_logs tl
       JOIN phases p ON tl.phase_id = p.id
       WHERE DATE(tl.logged_at) >= $1 AND DATE(tl.logged_at) < $1 + INTERVAL '7 days'
       GROUP BY p.name, p.color
       ORDER BY minutes DESC`,
      [weekStart]
    );

    const dailyBreakdown = await db.query(
      `SELECT DATE(logged_at) as date, SUM(duration_minutes) as minutes
       FROM time_logs
       WHERE DATE(logged_at) >= $1 AND DATE(logged_at) < $1 + INTERVAL '7 days'
       GROUP BY DATE(logged_at)
       ORDER BY date`,
      [weekStart]
    );

    // Best and worst day
    let bestDay = null, worstDay = null;
    if (dailyBreakdown.rows.length > 0) {
      const sorted = [...dailyBreakdown.rows].sort((a, b) => b.minutes - a.minutes);
      bestDay = { date: sorted[0].date, minutes: parseInt(sorted[0].minutes) };
      worstDay = { date: sorted[sorted.length - 1].date, minutes: parseInt(sorted[sorted.length - 1].minutes) };
    }

    res.json({
      week_start: weekStart,
      total_minutes: parseInt(totalMinutes.rows[0].total),
      total_hours: (parseInt(totalMinutes.rows[0].total) / 60).toFixed(1),
      phase_breakdown: phaseBreakdown.rows,
      daily_breakdown: dailyBreakdown.rows,
      best_day: bestDay,
      worst_day: worstDay
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// STREAKS
// ============================================
app.get('/api/streaks', async (req, res) => {
  try {
    const days = await db.query(
      `SELECT DISTINCT DATE(logged_at) as study_date
       FROM time_logs
       ORDER BY study_date DESC`
    );

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let currentStreak = 0;
    for (let i = 0; i < days.rows.length; i++) {
      const d = new Date(days.rows[i].study_date);
      const expected = new Date(today);
      expected.setDate(expected.getDate() - i);
      if (d.getTime() === expected.getTime()) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Get last 30 days for heatmap
    const last30Days = await db.query(
      `SELECT DATE(generate_series) as date,
              COALESCE(SUM(tl.duration_minutes), 0) as minutes
       FROM generate_series(
         CURRENT_DATE - INTERVAL '29 days',
         CURRENT_DATE,
         '1 day'
       )
       LEFT JOIN time_logs tl ON DATE(tl.logged_at) = DATE(generate_series)
       GROUP BY DATE(generate_series)
       ORDER BY date`
    );

    res.json({
      current_streak: currentStreak,
      heatmap_data: last30Days.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// SEED DATABASE (run schema + seed)
// ============================================
app.post('/api/seed', async (req, res) => {
  try {
    const fs = require('fs');
    const path = require('path');
    
    const schemaSQL = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await db.query(schemaSQL);
    
    const seedSQL = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
    await db.query(seedSQL);
    
    res.json({ success: true, message: 'Database seeded successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/api/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected', time: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ status: 'error', db: 'disconnected', error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Quant Tracker API running on port ${PORT}`);
  console.log(`Dashboard: http://localhost:${PORT}/api/health`);
});