const express = require('express');
const cors = require('cors');
const db = require('./db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

const defaultAllowedOrigins = [
  'https://pratham-jain-3903.github.io',
  'http://localhost:3000',
  'http://localhost:5500',
  'http://127.0.0.1:5500'
];
const allowedOrigins = (process.env.CORS_ORIGINS || defaultAllowedOrigins.join(','))
  .split(',')
  .map(origin => origin.trim())
  .filter(Boolean);

app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  }
}));
app.use(express.json());

function requireAdminToken(req, res, next) {
  const adminToken = process.env.ADMIN_TOKEN;
  const authHeader = req.get('authorization') || '';
  const providedToken = req.get('x-admin-token') || authHeader.replace(/^Bearer\s+/i, '');

  if (!adminToken) {
    return res.status(403).json({ error: 'ADMIN_TOKEN is not configured on the server' });
  }
  if (providedToken !== adminToken) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

function difficultyToMastery(difficulty) {
  const parsed = parseInt(difficulty, 10);
  if (parsed <= 1) return 85;
  if (parsed === 2) return 75;
  if (parsed === 3) return 65;
  if (parsed === 4) return 50;
  return 40;
}

function nextReviewInterval(score) {
  if (score >= 85) return 14;
  if (score >= 70) return 7;
  if (score >= 55) return 3;
  return 1;
}

async function refreshSkillMastery(skillTags = []) {
  const uniqueTags = [...new Set(skillTags.filter(Boolean))];
  for (const tag of uniqueTags) {
    await db.query(
      `INSERT INTO skill_mastery (skill_id, skill_name, score, evidence_count, last_assessed_at, next_review_at, confidence, notes)
       SELECT
         $1,
         INITCAP(REPLACE($1, '_', ' ')),
         COALESCE(ROUND(AVG(NULLIF(mastery_score,0)))::INTEGER, 0),
         COUNT(*) FILTER (WHERE evidence_url IS NOT NULL),
         MAX(COALESCE(last_reviewed_at, completed_at)),
         MIN(next_review_at),
         LEAST(100, COUNT(*) FILTER (WHERE status='completed') * 10),
         'Auto-updated from completed activity evidence.'
       FROM activities
       WHERE skill_tags @> ARRAY[$1]::TEXT[]
       ON CONFLICT (skill_id) DO UPDATE SET
         score=EXCLUDED.score,
         evidence_count=EXCLUDED.evidence_count,
         last_assessed_at=EXCLUDED.last_assessed_at,
         next_review_at=EXCLUDED.next_review_at,
         confidence=EXCLUDED.confidence,
         notes=EXCLUDED.notes,
         updated_at=NOW()`,
      [tag]
    );
  }
}

// ============================================
// PHASES
// ============================================
app.get('/api/phases', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM phases ORDER BY display_order');
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/phases/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, duration_weeks, hours_per_week, weight, description, color } = req.body;
    const result = await db.query(
      `UPDATE phases SET name=COALESCE($1,name), duration_weeks=COALESCE($2,duration_weeks),
        hours_per_week=COALESCE($3,hours_per_week), weight=COALESCE($4,weight),
        description=COALESCE($5,description), color=COALESCE($6,color)
       WHERE id=$7 RETURNING *`,
      [name, duration_weeks, hours_per_week, weight, description, color, id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Reset all activities in a phase to pending
app.post('/api/phases/:id/reset', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `UPDATE activities SET status='pending', completed_at=NULL
       WHERE phase_id=$1 RETURNING *`, [id]
    );
    res.json({ success: true, reset_count: result.rowCount });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// ACTIVITIES
// ============================================
app.get('/api/activities', async (req, res) => {
  try {
    const { phase_id, category } = req.query;
    let query = 'SELECT a.*, p.name as phase_name, p.color as phase_color FROM activities a JOIN phases p ON a.phase_id = p.id';
    const params = []; const conditions = [];
    if (phase_id) { conditions.push(`a.phase_id=$${params.length + 1}`); params.push(phase_id); }
    if (category) { conditions.push(`a.category=$${params.length + 1}`); params.push(category); }
    if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY a.display_order, a.created_at';
    res.json((await db.query(query, params)).rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/activities/:id', async (req, res) => {
  try {
    const { id } = req.params; const {
      status, notes, skill_tags, mastery_score, evidence_url, assessment_type,
      pass_criteria, why_this_task, next_review_at, role_track
    } = req.body;
    const completed_at = status === 'completed' ? new Date() : null;
    const result = await db.query(
      `UPDATE activities SET status=COALESCE($1,status), notes=COALESCE($2,notes),
        completed_at=CASE WHEN $1='completed' THEN $3 WHEN $1='pending' THEN NULL ELSE completed_at END,
        skill_tags=COALESCE($4,skill_tags), mastery_score=COALESCE($5,mastery_score),
        evidence_url=COALESCE($6,evidence_url), assessment_type=COALESCE($7,assessment_type),
        pass_criteria=COALESCE($8,pass_criteria), why_this_task=COALESCE($9,why_this_task),
        next_review_at=COALESCE($10,next_review_at), role_track=COALESCE($11,role_track)
       WHERE id=$12 RETURNING *`,
      [status, notes, completed_at, skill_tags, mastery_score, evidence_url, assessment_type, pass_criteria, why_this_task, next_review_at, role_track, id]
    );
    if (result.rows[0]?.skill_tags) await refreshSkillMastery(result.rows[0].skill_tags);
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/skill-mastery', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT sm.*,
        COUNT(a.id) FILTER (WHERE a.status='completed') as completed_activities,
        COUNT(a.id) as total_activities
      FROM skill_mastery sm
      LEFT JOIN activities a ON a.skill_tags @> ARRAY[sm.skill_id]::TEXT[]
      GROUP BY sm.skill_id
      ORDER BY sm.score ASC, sm.next_review_at NULLS LAST, sm.skill_name
    `);
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/review-queue', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT a.id, a.name, a.category, a.skill_tags, a.mastery_score, a.last_reviewed_at, a.next_review_at,
             a.pass_criteria, a.why_this_task, p.name as phase_name, p.color as phase_color
      FROM activities a
      JOIN phases p ON p.id=a.phase_id
      WHERE a.status='completed'
        AND (a.next_review_at IS NULL OR a.next_review_at <= NOW() + INTERVAL '2 days' OR a.mastery_score < 70)
      ORDER BY a.next_review_at NULLS FIRST, a.mastery_score ASC, a.completed_at DESC
      LIMIT 20
    `);
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/activities/:id/review', async (req, res) => {
  try {
    const { mastery_score, notes, evidence_url } = req.body;
    const score = Math.max(0, Math.min(100, parseInt(mastery_score || 60, 10)));
    const nextReview = nextReviewInterval(score);
    const result = await db.query(
      `UPDATE activities SET mastery_score=$2, notes=COALESCE($3,notes),
        evidence_url=COALESCE($4,evidence_url), last_reviewed_at=NOW(), next_review_at=NOW()+($5 || ' days')::INTERVAL
       WHERE id=$1 RETURNING *`,
      [req.params.id, score, notes || null, evidence_url || null, nextReview]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    await refreshSkillMastery(result.rows[0].skill_tags || []);
    res.json({ success: true, activity: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// ACTIVITY REFLECTIONS (Recall Gate)
// ============================================
app.post('/api/activities/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { content, key_takeaways, difficulty_rating, time_spent_minutes, mastery_score, evidence_url } = req.body;
    const activity = await db.query('SELECT phase_id, name, skill_tags FROM activities WHERE id=$1', [id]);
    if (!activity.rows.length) return res.status(404).json({ error: 'Not found' });
    const score = Math.max(0, Math.min(100, parseInt(mastery_score || difficultyToMastery(difficulty_rating || 3), 10)));
    const nextReview = nextReviewInterval(score);
    await db.query(
      `INSERT INTO activity_reflections (activity_id, phase_id, content, key_takeaways, difficulty_rating, time_spent_minutes)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [id, activity.rows[0].phase_id, content || 'Completed', key_takeaways || [], difficulty_rating || 3, time_spent_minutes || 0]
    );
    const result = await db.query(
      `UPDATE activities SET status='completed', completed_at=NOW(),
        mastery_score=$2, evidence_url=COALESCE($3,evidence_url), last_reviewed_at=NOW(), next_review_at=NOW()+($4 || ' days')::INTERVAL
       WHERE id=$1 RETURNING *`,
      [id, score, evidence_url || null, nextReview]
    );
    await refreshSkillMastery(activity.rows[0].skill_tags || []);
    res.json({ success: true, activity: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/activities/:id/reopen', async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE activities SET status='pending', completed_at=NULL WHERE id=$1 RETURNING *`, [req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true, activity: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Edit a reflection
app.put('/api/reflections/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { content, key_takeaways, difficulty_rating } = req.body;
    const result = await db.query(
      `UPDATE activity_reflections SET content=COALESCE($1,content),
        key_takeaways=COALESCE($2,key_takeaways),
        difficulty_rating=COALESCE($3,difficulty_rating)
       WHERE id=$4 RETURNING *`,
      [content, key_takeaways, difficulty_rating, id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// DAG: PREREQUISITES
// ============================================
app.get('/api/dag/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const prereqs = await db.query(
      `SELECT a.id, a.name, a.status, a.estimated_minutes, a.difficulty, p.name as phase_name, p.color as phase_color
       FROM activity_prerequisites ap JOIN activities a ON a.id=ap.prerequisite_id
       JOIN phases p ON p.id=a.phase_id WHERE ap.activity_id=$1 ORDER BY a.display_order`, [id]
    );
    const dependents = await db.query(
      `SELECT a.id, a.name, a.status, a.estimated_minutes, a.difficulty, p.name as phase_name, p.color as phase_color
       FROM activity_prerequisites ap JOIN activities a ON a.id=ap.activity_id
       JOIN phases p ON p.id=a.phase_id WHERE ap.prerequisite_id=$1 ORDER BY a.display_order`, [id]
    );
    res.json({ prerequisites: prereqs.rows, dependents: dependents.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// ACTIVITY TIME TRACKING
// ============================================
app.get('/api/activity-time/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const activity = await db.query('SELECT * FROM activities WHERE id=$1', [id]);
    if (!activity.rows.length) return res.status(404).json({ error: 'Not found' });
    const logs = await db.query(
      `SELECT DATE(logged_at) as date, SUM(duration_minutes) as total_minutes, COUNT(*) as sessions
       FROM time_logs WHERE activity_id=$1 GROUP BY DATE(logged_at) ORDER BY date`, [id]
    );
    const totalTracked = logs.rows.reduce((sum, l) => sum + parseInt(l.total_minutes), 0);
    const budget = activity.rows[0].estimated_minutes || 0;
    res.json({
      activity: activity.rows[0], total_tracked_minutes: totalTracked, budget_minutes: budget,
      percent_complete: budget > 0 ? Math.round((totalTracked / budget) * 100) : 0, daily_breakdown: logs.rows
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// TODAY'S PLATE (DAG-based daily plan)
// ============================================
app.get('/api/daily-plan', async (req, res) => {
  try {
    const dateStr = req.query.date || new Date().toISOString().split('T')[0];
    const todaySchedule = await db.query(`SELECT * FROM schedule WHERE DATE(start_time)=$1 ORDER BY start_time`, [dateStr]);
    const freeBlocks = [];
    const dayStart = 9 * 60, dayEnd = 23 * 60;
    const schedMinutes = todaySchedule.rows.map(s => ({
      start: new Date(s.start_time).getHours() * 60 + new Date(s.start_time).getMinutes(),
      end: new Date(s.end_time).getHours() * 60 + new Date(s.end_time).getMinutes()
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
      FROM activities a JOIN phases p ON a.phase_id=p.id
      WHERE a.status='pending' AND NOT EXISTS (
        SELECT 1 FROM activity_prerequisites ap JOIN activities pa ON pa.id=ap.prerequisite_id
        WHERE ap.activity_id=a.id AND pa.status != 'completed'
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
            skill_tags: activity.skill_tags || [], assessment_type: activity.assessment_type,
            pass_criteria: activity.pass_criteria, why_this_task: activity.why_this_task,
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
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// PROJECTED TIMELINE
// ============================================
app.get('/api/projected-timeline', async (req, res) => {
  try {
    const phases = await db.query('SELECT * FROM phases ORDER BY display_order');
    const avgHours = await db.query(`SELECT COALESCE(SUM(duration_minutes),0)/14.0 as avg_daily FROM time_logs WHERE logged_at>=NOW()-INTERVAL '14 days'`);
    const avgWeeklyHours = (parseFloat(avgHours.rows[0]?.avg_daily || 0) * 7) / 60;
    const projections = [];
    for (const phase of phases.rows) {
      const stats = await db.query(`SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE status='completed') as done, COALESCE(SUM(estimated_minutes) FILTER (WHERE status!='completed'),0) as remaining FROM activities WHERE phase_id=$1`, [phase.id]);
      const total = parseInt(stats.rows[0].total), done = parseInt(stats.rows[0].done), remainingMin = parseInt(stats.rows[0].remaining);
      const pct = total > 0 ? Math.round((done / total) * 100) : 0;
      const phaseHrs = phase.hours_per_week || 10;
      const effHrs = Math.max(avgWeeklyHours, 1);
      projections.push({
        phase_id: phase.id, phase_name: phase.name, color: phase.color,
        total_activities: total, completed_activities: done, percent_complete: pct,
        remaining_hours: Math.round(remainingMin / 60 * 10) / 10,
        planned_duration_weeks: phase.duration_weeks || 'Ongoing',
        projected_weeks_remaining: Math.round(remainingMin / 60 / effHrs * 10) / 10,
        pace: avgWeeklyHours >= phaseHrs ? 'on_track' : avgWeeklyHours > 0 ? 'behind' : 'not_started'
      });
    }
    const totalRemaining = projections.reduce((s, p) => s + (p.remaining_hours || 0) * 60, 0);
    res.json({
      projections, avg_weekly_hours: Math.round(avgWeeklyHours * 10) / 10,
      overall_remaining_hours: Math.round(totalRemaining / 60 * 10) / 10,
      summary: avgWeeklyHours > 0 ? `At ${Math.round(avgWeeklyHours * 10) / 10} hrs/week, ~${Math.round(totalRemaining / 60 / avgWeeklyHours)} weeks remaining.` : 'Start logging time to see projections!'
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// SCHEDULE (with soft delete for undo)
// ============================================
app.get('/api/schedule', async (req, res) => {
  try {
    const { start, end } = req.query;
    let query = `SELECT s.*, p.name as phase_name, p.color as phase_color FROM schedule s LEFT JOIN phases p ON s.phase_id=p.id WHERE (s.deleted_at IS NULL OR s.deleted_at IS NOT NULL)`;
    const params = []; const conditions = [];
    if (start) { conditions.push(`s.start_time>=$${params.length + 1}`); params.push(start); }
    if (end) { conditions.push(`s.end_time<=$${params.length + 1}`); params.push(end); }
    if (conditions.length) query = `SELECT s.*, p.name as phase_name, p.color as phase_color FROM schedule s LEFT JOIN phases p ON s.phase_id=p.id WHERE s.deleted_at IS NULL AND ` + conditions.join(' AND ');
    else query = `SELECT s.*, p.name as phase_name, p.color as phase_color FROM schedule s LEFT JOIN phases p ON s.phase_id=p.id WHERE s.deleted_at IS NULL`;
    query += ' ORDER BY s.start_time';
    res.json((await db.query(query, params)).rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/schedule', async (req, res) => {
  try {
    const { title, description, phase_id, category, subject, start_time, end_time, color } = req.body;
    const result = await db.query(
      `INSERT INTO schedule (title,description,phase_id,category,subject,start_time,end_time,color) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
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

// Soft delete — keeps record for 7-day undo
app.delete('/api/schedule/:id', async (req, res) => {
  try {
    await db.query('UPDATE schedule SET deleted_at=NOW(), title=CONCAT(title, \' [deleted]\') WHERE id=$1 AND deleted_at IS NULL', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Restore a soft-deleted schedule item
app.post('/api/schedule/:id/restore', async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE schedule SET deleted_at=NULL, title=REPLACE(title,' [deleted]','')
       WHERE id=$1 RETURNING *`, [req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true, schedule: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Recently deleted schedule items (7-day restore window)
app.get('/api/schedule/deleted', async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, title, start_time, end_time, color, deleted_at
       FROM schedule WHERE deleted_at IS NOT NULL AND deleted_at>=NOW()-INTERVAL '7 days'
       ORDER BY deleted_at DESC LIMIT 10`
    );
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// TIME LOGS (with delete support)
// ============================================
app.post('/api/time-logs', async (req, res) => {
  try {
    const { activity_id, phase_id, duration_minutes, notes, source } = req.body;
    let resolvedPhaseId = phase_id;

    if (!resolvedPhaseId && activity_id) {
      const activity = await db.query('SELECT phase_id FROM activities WHERE id=$1', [activity_id]);
      if (!activity.rows.length) return res.status(404).json({ error: 'Activity not found' });
      resolvedPhaseId = activity.rows[0].phase_id;
    }

    const result = await db.query(
      `INSERT INTO time_logs (activity_id,phase_id,duration_minutes,notes,source) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [activity_id, resolvedPhaseId, duration_minutes, notes, source || 'manual']
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/time-logs', async (req, res) => {
  try {
    const { date, phase_id, activity_id } = req.query;
    let query = `SELECT tl.*, p.name as phase_name, p.color as phase_color FROM time_logs tl LEFT JOIN phases p ON tl.phase_id=p.id`;
    const params = []; const conditions = [];
    if (date) { conditions.push(`DATE(tl.logged_at)=$${params.length + 1}`); params.push(date); }
    if (phase_id) { conditions.push(`tl.phase_id=$${params.length + 1}`); params.push(phase_id); }
    if (activity_id) { conditions.push(`tl.activity_id=$${params.length + 1}`); params.push(activity_id); }
    if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY tl.logged_at DESC';
    res.json((await db.query(query, params)).rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Delete a time log (undo)
app.delete('/api/time-logs/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM time_logs WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// PROJECTS
// ============================================
app.get('/api/projects', async (req, res) => {
  try {
    res.json((await db.query(`SELECT pr.*, p.name as phase_name, p.color as phase_color FROM projects pr LEFT JOIN phases p ON pr.phase_id=p.id ORDER BY pr.category, pr.name`)).rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/projects/:id', async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE projects SET is_completed=COALESCE($1,is_completed), notes=COALESCE($2,notes),
        evidence_url=COALESCE($3,evidence_url), validation_notes=COALESCE($4,validation_notes),
        result_summary=COALESCE($5,result_summary), interview_story=COALESCE($6,interview_story),
        updated_at=NOW() WHERE id=$7 RETURNING *`,
      [req.body.is_completed, req.body.notes, req.body.evidence_url, req.body.validation_notes, req.body.result_summary, req.body.interview_story, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/projects/:id/reopen', async (req, res) => {
  try {
    const result = await db.query(`UPDATE projects SET is_completed=false, updated_at=NOW() WHERE id=$1 RETURNING *`, [req.params.id]);
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true, project: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// BOOKS
// ============================================
app.get('/api/books', async (req, res) => {
  try {
    const { phase_id } = req.query;
    let query = `SELECT b.*, p.name as phase_name FROM books b LEFT JOIN phases p ON b.phase_id=p.id`;
    if (phase_id) query += ' WHERE b.phase_id=$1';
    query += ' ORDER BY b.title';
    res.json((await db.query(query, phase_id ? [phase_id] : [])).rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/books/:id', async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE books SET status=COALESCE($1,status), notes=COALESCE($2,notes), updated_at=NOW() WHERE id=$3 RETURNING *`,
      [req.body.status, req.body.notes, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/books/:id/reopen', async (req, res) => {
  try {
    const result = await db.query(`UPDATE books SET status='not_started', updated_at=NOW() WHERE id=$1 RETURNING *`, [req.params.id]);
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json({ success: true, book: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// JOURNAL (with delete support)
// ============================================
app.get('/api/journal', async (req, res) => {
  try {
    const { limit } = req.query;
    let query = `SELECT j.*, p.name as phase_name FROM journal_entries j LEFT JOIN phases p ON j.phase_id=p.id ORDER BY j.created_at DESC`;
    if (limit) query += ' LIMIT $1';
    res.json((await db.query(query, limit ? [parseInt(limit)] : [])).rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/journal', async (req, res) => {
  try {
    const result = await db.query(`INSERT INTO journal_entries (content,mood,phase_id) VALUES ($1,$2,$3) RETURNING *`, [req.body.content, req.body.mood, req.body.phase_id]);
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Edit journal entry
app.put('/api/journal/:id', async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE journal_entries SET content=COALESCE($1,content), mood=COALESCE($2,mood) WHERE id=$3 RETURNING *`,
      [req.body.content, req.body.mood, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Delete journal entry (undo)
app.delete('/api/journal/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM journal_entries WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// DASHBOARD (aggregated)
// ============================================
app.get('/api/dashboard', async (req, res) => {
  try {
    const weeklyTargetHours = parseFloat(process.env.WEEKLY_TARGET_HOURS || '10');
    const todayResult = await db.query(`SELECT COALESCE(SUM(duration_minutes),0) as total FROM time_logs WHERE DATE(logged_at)=CURRENT_DATE`);
    const todaySchedule = await db.query(`SELECT * FROM schedule WHERE DATE(start_time)=CURRENT_DATE AND deleted_at IS NULL ORDER BY start_time`);
    const upcoming = await db.query(`SELECT * FROM schedule WHERE start_time>=CURRENT_DATE AND start_time<CURRENT_DATE+INTERVAL '7 days' AND deleted_at IS NULL ORDER BY start_time LIMIT 20`);
    const phaseProgress = await db.query(`SELECT p.id,p.name,p.weight,p.color,COUNT(a.id) FILTER (WHERE a.status='completed') as completed_activities,COUNT(a.id) as total_activities FROM phases p LEFT JOIN activities a ON p.id=a.phase_id GROUP BY p.id,p.name,p.weight,p.color,p.display_order ORDER BY p.display_order`);
    const weeklyTotals = await db.query(`SELECT DATE(logged_at) as date,SUM(duration_minutes) as minutes FROM time_logs WHERE logged_at>=CURRENT_DATE-INTERVAL '7 days' GROUP BY DATE(logged_at) ORDER BY date`);
    const weekTotal = await db.query(`SELECT COALESCE(SUM(duration_minutes),0) as total FROM time_logs WHERE logged_at>=DATE_TRUNC('week',CURRENT_DATE)`);
    const nextTask = await db.query(`
      SELECT a.id, a.name, a.category, a.estimated_minutes, a.difficulty, a.skill_tags, a.assessment_type, a.pass_criteria, a.why_this_task,
             p.name as phase_name, p.color as phase_color
      FROM activities a JOIN phases p ON a.phase_id=p.id
      WHERE a.status='pending' AND NOT EXISTS (
        SELECT 1 FROM activity_prerequisites ap JOIN activities pa ON pa.id=ap.prerequisite_id
        WHERE ap.activity_id=a.id AND pa.status != 'completed'
      )
      ORDER BY p.display_order, a.display_order, a.difficulty
      LIMIT 1
    `);
    const reviewDebt = await db.query(`
      SELECT COUNT(*) as due_count
      FROM activities
      WHERE status='completed'
        AND (next_review_at IS NULL OR next_review_at <= NOW() OR mastery_score < 70)
    `);
    const weakestSkills = await db.query(`SELECT * FROM skill_mastery ORDER BY score ASC, confidence ASC, skill_name LIMIT 4`);
    const artifacts = await db.query(`
      SELECT
        COUNT(*) FILTER (WHERE evidence_url IS NOT NULL) as evidence_count,
        COUNT(*) FILTER (WHERE assessment_type='project' AND evidence_url IS NOT NULL) as project_artifact_count
      FROM activities
    `);
    const weekMinutes = parseInt(weekTotal.rows[0].total);
    const weekHours = weekMinutes / 60;
    res.json({
      today_minutes: parseInt(todayResult.rows[0].total), today_hours: (parseInt(todayResult.rows[0].total) / 60).toFixed(1),
      today_schedule: todaySchedule.rows, upcoming: upcoming.rows, streak: 0,
      phase_progress: phaseProgress.rows, weekly_totals: weeklyTotals.rows,
      week_total_minutes: weekMinutes, week_total_hours: weekHours.toFixed(1),
      weekly_target_hours: weeklyTargetHours,
      weekly_execution_ratio: weeklyTargetHours > 0 ? Math.round((weekHours / weeklyTargetHours) * 100) : 0,
      weekly_gap_hours: Math.max(0, weeklyTargetHours - weekHours).toFixed(1),
      next_task: nextTask.rows[0] || null,
      review_debt: parseInt(reviewDebt.rows[0].due_count),
      weakest_skills: weakestSkills.rows,
      evidence_count: parseInt(artifacts.rows[0].evidence_count),
      project_artifact_count: parseInt(artifacts.rows[0].project_artifact_count)
    });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// RECENTLY-COMPLETED
// ============================================
app.get('/api/recently-completed', async (req, res) => {
  try {
    const [acts, projs, booksList] = await Promise.all([
      db.query(
        `SELECT 'activity' as kind, a.id, a.name as title, a.completed_at as done_at,
                p.name as phase_name, p.color as phase_color
         FROM activities a JOIN phases p ON p.id=a.phase_id
         WHERE a.status='completed' AND a.completed_at>=NOW()-INTERVAL '7 days'
         ORDER BY a.completed_at DESC LIMIT 10`
      ),
      db.query(
        `SELECT 'project' as kind, pr.id, pr.name as title, pr.updated_at as done_at,
                NULL as phase_name, '#4f46e5' as phase_color
         FROM projects pr
         WHERE pr.is_completed=true AND pr.updated_at>=NOW()-INTERVAL '7 days'
         ORDER BY pr.updated_at DESC LIMIT 10`
      ),
      db.query(
        `SELECT 'book' as kind, b.id, b.title, b.updated_at as done_at,
                p.name as phase_name, p.color as phase_color
         FROM books b LEFT JOIN phases p ON p.id=b.phase_id
         WHERE b.status='completed' AND b.updated_at>=NOW()-INTERVAL '7 days'
         ORDER BY b.updated_at DESC LIMIT 10`
      )
    ]);
    const combined = [...acts.rows, ...projs.rows, ...booksList.rows]
      .sort((a, b) => new Date(b.done_at) - new Date(a.done_at)).slice(0, 10);
    res.json(combined);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// STREAKS
// ============================================
app.get('/api/streaks', async (req, res) => {
  try {
    const last30Days = await db.query(`SELECT DATE(generate_series) as date,COALESCE(SUM(tl.duration_minutes),0) as minutes FROM generate_series(CURRENT_DATE-INTERVAL '29 days',CURRENT_DATE,'1 day') LEFT JOIN time_logs tl ON DATE(tl.logged_at)=DATE(generate_series) GROUP BY DATE(generate_series) ORDER BY date`);
    res.json({ current_streak: 0, heatmap_data: last30Days.rows });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// ============================================
// SEED / MIGRATE / HEALTH
// ============================================
app.post('/api/seed', requireAdminToken, async (req, res) => {
  try {
    const fs = require('fs'), path = require('path');
    await db.query(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8'));
    await db.query(fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8'));
    await db.query(fs.readFileSync(path.join(__dirname, 'migration-v2.sql'), 'utf8'));
    await db.query(fs.readFileSync(path.join(__dirname, 'migration-v3.sql'), 'utf8'));
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/migrate-v2', requireAdminToken, async (req, res) => {
  try {
    const fs = require('fs'), path = require('path');
    await db.query(fs.readFileSync(path.join(__dirname, 'migration-v2.sql'), 'utf8'));
    res.json({ success: true, message: 'Migration v2 applied' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/migrate-v3', requireAdminToken, async (req, res) => {
  try {
    const fs = require('fs'), path = require('path');
    await db.query(fs.readFileSync(path.join(__dirname, 'migration-v3.sql'), 'utf8'));
    res.json({ success: true, message: 'Migration v3 applied' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected', time: new Date().toISOString() });
  } catch (err) { res.status(500).json({ status: 'error', error: err.message }); }
});

app.listen(PORT, () => console.log(`Quant Tracker API running on port ${PORT}`));
