#!/usr/bin/env node
// Status line: model | effort | project (branch) | context bar | 5h (if any) / 7d usage.
// Claude Code pipes a JSON payload on stdin and shows whatever this prints.
const { execFileSync } = require('child_process');
const path = require('path');

const DIM = '\x1b[38;5;245m', RESET = '\x1b[0m', SEP = ` ${DIM}|${RESET} `;
const color = (pct) => pct >= 90 ? '\x1b[31m' : pct >= 75 ? '\x1b[38;5;208m' : pct >= 50 ? '\x1b[33m' : '\x1b[32m';

let input = '';
process.stdin.on('data', (c) => input += c);
process.stdin.on('end', () => {
  let d = {};
  try { d = JSON.parse(input); } catch (e) {}
  const parts = [d.model?.display_name || 'Claude'];

  const effort = d.effort?.level;
  if (effort) parts.push(`${DIM}${effort}${RESET}`);

  const dir = d.workspace?.current_dir || process.cwd();
  let project = path.basename(dir);
  try {
    const b = execFileSync('git', ['branch', '--show-current'],
      { cwd: dir, encoding: 'utf8', timeout: 200, stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    if (b) project += ` ${DIM}(${b})${RESET}`;
  } catch (e) {}
  parts.push(project);

  const used = d.context_window?.used_percentage;
  if (typeof used === 'number') {
    const p = Math.max(0, Math.min(100, Math.round(used)));
    const n = Math.floor(p / 10);
    parts.push(`${color(p)}${'█'.repeat(n)}${'░'.repeat(10 - n)} ${p}%${RESET}`);
  }

  const reset = (t, opts) => {
    const s = typeof t === 'string' ? Date.parse(t) / 1000 : t;
    return s > 0 ? ' ↺' + new Date(s * 1000).toLocaleString([], { hour: 'numeric', minute: '2-digit', ...opts }) : '';
  };
  // Verified Ultra accounts have no 5-hour limit; other plans do. Shown only when reported.
  const five = d.rate_limits?.five_hour, week = d.rate_limits?.seven_day;
  if (typeof five?.used_percentage === 'number') {
    const p = Math.ceil(five.used_percentage);
    parts.push(`${color(p)}5h:${p}%${reset(five.resets_at)}${RESET}`);
  }
  if (typeof week?.used_percentage === 'number') {
    const p = Math.ceil(week.used_percentage);
    parts.push(`${color(p)}7d:${p}%${reset(week.resets_at, { weekday: 'short' })}${RESET}`);
  }

  process.stdout.write(parts.join(SEP));
});
