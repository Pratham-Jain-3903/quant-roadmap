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
    const result = await db.query('SELECT * FROM phases ORDER BY display_order');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/phases/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, duration_weeks, hours_per_week, weight, description, color } = req.body;
    const result = await db.query(
      `UPDATE phases SET name = COALESCE($1,name), duration_weeks = COALESCE($2,duration_weeks),
        hours_per_week = COALESCE($3,hours_per_week), weight = COALESCE($4,weight),
        description = COALESCE($5,description), color = COALESCE($6,color)
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
    if (phase_id) { conditions.push(`a.phase_id = $${params.length + 1}`); params.push(phase_id); }
    if (category) { conditions.push(`a.category = $${params.length + 1}`); params.push(category); }
    if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY a.display_order, a.created_at';
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
      `UPDATE activities SET status = COALESCE($1,status), notes = COALESCE($2,notes), completed_at = $3 WHERE id = $4 RETURNING *`,
      [status, notes, completed_at, id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// ACTIVITY REFLECTIONS (Recall Gate)
// ============================================
app.post('/api/activities/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { content, key_takeaways, difficulty_rating, time_spent_minutes } = req.body;
    const activity = await db.query('SELECT phase_id, name FROM activities WHERE id = $1', [id]);
    if (!activity.rows.length) return res.status(404).json({ error: 'Not found' });
    await db.query(
      `INSERT INTO activity_reflections (activity_id, phase_id, content, key_takeaways, difficulty_rating, time_spent_minutes)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [id, activity.rows[0].phase_id, content || 'Completed', key_takeaways || [], difficulty_rating || 3, time_spent_minutes || 0]
    );
    const result = await db.query(`UPDATE activities SET status = 'completed', completed_at = NOW() WHERE id = $1 RETURNING *`, [id]);
    res.json({ success: true, activity: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// DAG: PREREQUISITES
// ============================================
app.get('/api/dag/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const prereqs = await db.query(
      `SELECT a.id, a.name, a.status, a.estimated_minutes, a.difficulty, p.name as phase_name, p.color as phase_color
       FROM activity_prerequisites ap JOIN activities a ON a.id = ap.prerequisite_id
       JOIN phases p ON p.id = a.phase_id WHERE ap.activity_id = $1 ORDER BY a.display_order`, [id]
    );
    const dependents = await db.query(
      `SELECT a.id, a.name, a.status, a.estimated_minutes, a.difficulty, p.name as phase_name, p.color as phase_color
       FROM activity_prerequisites ap JOIN activities a ON a.id = ap.activity_id
       JOIN phases p ON p.id = a.phase_id WHERE ap.prerequisite_id = $1 ORDER BY a.display_order`, [id]
    );
    res.json({ prerequisites: prereqs.rows, dependents: dependents.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// ACTIVITY TIME TRACKING
// ============================================
app.get('/api/activity-time/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const activity = await db.query('SELECT * FROM activities WHERE id = $1', [id]);
    if (!activity.rows.length) return res.status(404).json({ error: 'Not found' });
    const logs = await db.query(
      `SELECT DATE(logged_at) as date, SUM(duration_minutes) as total_minutes, COUNT(*) as sessions
       FROM time_logs WHERE activity_id = $1 GROUP BY DATE(logged_at) ORDER BY date`, [id]
    );
    const totalTracked = logs.rows.reduce((sum, l) => sum + parseInt(l.total_minutes), 0);
    const budget = activity.rows[0].estimated_minutes || 0;
    res.json({
      activity: activity.rows[0], total_tracked_minutes: totalTracked, budget_minutes: budget,
      percent_complete: budget > 0 ? Math.round((totalTracked / budget) * 100) : 0, daily_breakdown: logs.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// TODAY'S PLATE (DAG-based daily plan)
// ============================================
app.get('/api/daily-plan', async (req, res) => {
  try {
    const dateStr = req.query.date || new Date().toISOString().split('T')[0];
    const todaySchedule = await db.query(`SELECT * FROM schedule WHERE DATE(start_time) = $1 ORDER BY start_time`, [dateStr]);
    const freeBlocks = [];
    const dayStart = 9 * 60;
    const dayEnd = 23 * 60;
    const schedMinutes = todaySchedule.rows.map(s => ({
      start: new Date(s.start_time).getHours() * 60 + new Date(s.start_time).getMinutes(),
      end: new Date(s.end_time).getHours() * 60 + new Date(s.end_time).getMinutes(),
      title: s.title, color: s.color
    }));
    schedMinutes.sort((a, b) => a.start - b.start);
    let cursor = dayStart;
    for (const block of schedMinutes) {
      if (block.start > cursor) freeBlocks.push({ start: cursor, end: block.start });
      cursor = block.end;
    }
    if (cursor < dayEnd) freeBlocks.push({ start: cursor, end: dayEnd });

    const unlocked = await db.query(`
      SELECT a.*, p.name as phase_name, p.color as phase_color, p.display_order as phase_order
      FROM activities a JOIN phases p ON a.phase_id = p.id
      WHERE a.status = 'pending' AND NOT EXISTS (
        SELECT 1 FROM activity_prerequisites ap JOIN activities pa ON pa.id = ap.prerequisite_id
        WHERE ap.activity_id = a.id AND pa.status != 'completed'
      )
      ORDER BY p.display_order, a.display_order, a.difficulty
    `);

    const plan = [];
    let remainingBlocks = [...freeBlocks];
    for (const activity of unlocked.rows) {
      const estMinutes = activity.estimated_minutes || 60;
      for (let b = 0; b < remainingBlocks.length; b++) {
        const block = remainingBlocks[b];
        if (block.end - block.start >= estMinutes) {
          plan.push({
            activity_id: activity.id, activity_name: activity.name, phase_name: activity.phase_name,
            phase_color: activity.phase_color, category: activity.category, estimated_minutes: activity.estimated_minutes,
            difficulty: activity.difficulty, resource_url: activity.resource_url, resource_name: activity.resource_name,
            start_time: Math.floor(block.start / 60) + ':' + String(block.start % 60).padStart(2, '0'),
            end_time: Math.floor((block.start + estMinutes) / 60) + ':' + String((block.start + estMinutes) % 60).padStart(2, '0'),
            duration: estMinutes
          });
          remainingBlocks[b] = { start: block.start + estMinutes, end: block.end };
          break;
        }
      }
    }

    res.json({
      date: dateStr,
      today_schedule: todaySchedule.rows.map(s => ({ title: s.title, category: s.category, subject: s.subject, start_time: s.start_time, end_time: s.end_time, color: s.color })),
      free_blocks: freeBlocks.map(b => ({ start: Math.floor(b.start / 60) + ':' + String(b.start % 60).padStart(2, '0'), end: Math.floor(b.end / 60) + ':' + String(b.end % 60).padStart(2, '0'), duration_minutes: b.end - b.start })),
      plan, unlocked_count: unlocked.rows.length, plan_count: plan.length
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// PROJECTED TIMELINE
// ============================================
app.get('/api/projected-timeline', async (req, res) => {
  try {
    const phases = await db.query('SELECT * FROM phases ORDER BY display_order');
    const avgHours = await db.query(
      `SELECT COALESCE(SUM(duration_minutes), 0) / 14.0 as avg_daily FROM time_logs WHERE logged_at >= NOW() - INTERVAL '14 days'`
    );
    const avgWeeklyHours = (parseFloat(avgHours.rows[0]?.avg_daily || 0) * 7) / 60;
    const projections = [];

    for (const phase of phases.rows) {
      const stats = await db.query(
        `SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE status = 'completed') as done,
                COALESCE(SUM(estimated_minutes) FILTER (WHERE status != 'completed'), 0) as remaining
         FROM activities WHERE phase_id = $1`, [phase.id]
      );
      const total = parseInt(stats.rows[0].total);
      const done = parseInt(stats.rows[0].done);
      const remainingMin = parseInt(stats.rows[0].remaining);
      const pct = total > 0 ? Math.round((done / total) * 100) : 0;
      const phaseWeeklyHours = phase.hours_per_week || 10;
      const effectiveHours = Math.max(avgWeeklyHours, 1);

      projections.push({
        phase_id: phase.id, phase_name: phase.name, color: phase.color,
        total_activities: total, completed_activities: done, percent_complete: pct,
        remaining_hours: Math.round(remainingMin / 60 * 10) / 10,
        planned_duration_weeks: phase.duration_weeks || 'Ongoing',
        projected_weeks_remaining: Math.round(remainingMin / 60 / effectiveHours * 10) / 10,
        pace: avgWeeklyHours >= phaseWeeklyHours ? 'on_track' : avgWeeklyHours > 0 ? 'behind' : 'not_started',
        recommended_hours_per_week: Math.max(phaseWeeklyHours, Math.ceil(remainingMin / 60 / 4))
      });
    }

    const totalRemaining = projections.reduce((s, p) => s + (p.remaining_hours || 0) * 60, 0);
    res.json({
      projections, avg_weekly_hours: Math.round(avgWeeklyHours * 10) / 10,
      overall_remaining_hours: Math.round(totalRemaining / 60 * 10) / 10,
      summary: avgWeeklyHours > 0
        ? `At ${Math.round(avgWeeklyHours * 10) / 10} hrs/week, ~${Math.round(totalRemaining / 60 / avgWeeklyHours)} weeks remaining.`
        : 'Start logging time to see projections!'
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// SCHEDULE
// ============================================
app.get('/api/schedule', async (req, res) => {
  try {
    const { start, end } = req.query;
    let query = `SELECT s.*, p.name as phase_name, p.color as phase_color FROM schedule s LEFT JOIN phases p ON s.phase_id = p.id`;
    const params = [];
    const conditions = [];
    if (start) { conditions.push(`s.start_time >= $${params.length + 1}`); params.push(start); }
    if (end) { conditions.push(`s.end_time <= $${params.length + 1}`); params.push(end); }
    if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY s.start_time';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/schedule', async (req, res) => {
  try {
    const { title, description, phase_id, category, subject, start_time, end_time, color } = req.body;
    const result = await db.query(
      `INSERT INTO schedule (title, description, phase_id, category, subject, start_time, end_time, color)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [title, description, phase_id, category || 'study', subject, start_time, end_time, color || '#4a90d9']
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/schedule/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, phase_id, category, start_time, end_time, color } = req.body;
    const result = await db.query(
      `UPDATE schedule SET title=COALESCE($1,title), description=COALESCE($2,description),
        phase_id=COALESCE($3,phase_id), category=COALESCE($4,category),
        start_time=COALESCE($5,start_time), end_time=COALESCE($6,end_time),
        color=COALESCE($7,color), updated_at=NOW() WHERE id=$8 RETURNING *`,
      [title, description, phase_id, category, start_time, end_time, color, id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/schedule/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM schedule WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// TIME LOGS
// ============================================
app.post('/api/time-logs', async (req, res) => {
  try {
    const { activity_id, phase_id, duration_minutes, notes, source } = req.body;
    const result = await db.query(
      `INSERT INTO time_logs (activity_id, phase_id, duration_minutes, notes, source) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [activity_id, phase_id, duration_minutes, notes, source || 'manual']
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/time-logs', async (req, res) => {
  try {
    const { date, phase_id, activity_id } = req.query;
    let query = `SELECT tl.*, p.name as phase_name, p.color as phase_color FROM time_logs tl JOIN phases p ON tl.phase_id = p.id`;
    const params = [];
    const conditions = [];
    if (date) { conditions.push(`DATE(tl.logged_at)=$${params.length + 1}`); params.push(date); }
    if (phase_id) { conditions.push(`tl.phase_id=$${params.length + 1}`); params.push(phase_id); }
    if (activity_id) { conditions.push(`tl.activity_id=$${params.length + 1}`); params.push(activity_id); }
    if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY tl.logged_at DESC';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// PROJECTS / BOOKS / JOURNAL
// ============================================
app.get('/api/projects', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT pr.*, p.name as phase_name, p.color as phase_color FROM projects pr LEFT JOIN phases p ON pr.phase_id = p.id ORDER BY pr.category, pr.name`
    );
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/projects/:id', async (req, res) => {
  try {
    const { is_completed, notes } = req.body;
    const result = await db.query(
      `UPDATE projects SET is_completed=COALESCE($1,is_completed), notes=COALESCE($2,notes), updated_at=NOW() WHERE id=$3 RETURNING *`,
      [is_completed, notes, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/books', async (req, res) => {
  try {
    const { phase_id } = req.query;
    let query = `SELECT b.*, p.name as phase_name FROM books b LEFT JOIN phases p ON b.phase_id = p.id`;
    if (phase_id) query += ' WHERE b.phase_id=$1';
    query += ' ORDER BY b.title';
    const result = await db.query(query, phase_id ? [phase_id] : []);
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/books/:id', async (req, res) => {
  try {
    const { status, notes } = req.body;
    const result = await db.query(
      `UPDATE books SET status=COALESCE($1,status), notes=COALESCE($2,notes), updated_at=NOW() WHERE id=$3 RETURNING *`,
      [status, notes, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/journal', async (req, res) => {
  try {
    const { limit } = req.query;
    let query = `SELECT j.*, p.name as phase_name FROM journal_entries j LEFT JOIN phases p ON j.phase_id = p.id ORDER BY j.created_at DESC`;
    if (limit) query += ' LIMIT $1';
    const result = await db.query(query, limit ? [parseInt(limit)] : []);
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/journal', async (req, res) => {
  try {
    const { content, mood, phase_id } = req.body;
    const result = await db.query(`INSERT INTO journal_entries (content, mood, phase_id) VALUES ($1,$2,$3) RETURNING *`, [content, mood, phase_id]);
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// DASHBOARD (aggregated)
// ============================================
app.get('/api/dashboard', async (req, res) => {
  try {
    const todayResult = await db.query(`SELECT COALESCE(SUM(duration_minutes),0) as total FROM time_logs WHERE DATE(logged_at)=CURRENT_DATE`);
    const todaySchedule = await db.query(`SELECT * FROM schedule WHERE DATE(start_time)=CURRENT_DATE ORDER BY start_time`);
    const upcoming = await db.query(`SELECT * FROM schedule WHERE start_time>=CURRENT_DATE AND start_time<CURRENT_DATE+INTERVAL '7 days' ORDER BY start_time LIMIT 20`);
    const phaseProgress = await db.query(
      `SELECT p.id, p.name, p.weight, p.color, COUNT(a.id) FILTER (WHERE a.status='completed') as done, COUNT(a.id) as total
       FROM phases p LEFT JOIN activities a ON p.id=a.phase_id GROUP BY p.id,p.name,p.weight,p.color,p.display_order ORDER BY p.display_order`
    );
    const weeklyTotals = await db.query(
      `SELECT DATE(logged_at) as date, SUM(duration_minutes) as minutes FROM time_logs WHERE logged_at>=CURRENT_DATE-INTERVAL '7 days' GROUP BY DATE(logged_at) ORDER BY date`
    );
    const weekTotal = await db.query(`SELECT COALESCE(SUM(duration_minutes),0) as total FROM time_logs WHERE logged_at>=DATE_TRUNC('week',CURRENT_DATE)`);
    res.json({
      today_minutes: parseInt(todayResult.rows[0].total),
      today_hours: (parseInt(todayResult.rows[0].total)/60).toFixed(1),
      today_schedule: todaySchedule.rows, upcoming: upcoming.rows, streak: 0,
      phase_progress: phaseProgress.rows, weekly_totals: weeklyTotals.rows,
      week_total_minutes: parseInt(weekTotal.rows[0].total),
      week_total_hours: (parseInt(weekTotal.rows[0].total)/60).toFixed(1)
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// SEED / MIGRATE / HEALTH
// ============================================
app.post('/api/seed', async (req, res) => {
  try {
    const fs = require('fs'); const path = require('path');
    await db.query(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8'));
    await db.query(fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8'));
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/migrate-v2', async (req, res) => {
  try {
    const fs = require('fs'); const path = require('path');
    await db.query(fs.readFileSync(path.join(__dirname, 'migration-v2.sql'), 'utf8'));
    res.json({ success: true, message: 'Migration v2 applied' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected', time: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ status: 'error', error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Quant Tracker API running on port ${PORT}`);
});