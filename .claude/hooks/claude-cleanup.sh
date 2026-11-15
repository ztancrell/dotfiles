#!/bin/sh
# Claude Code cleanup, run by hooks (SessionStart, SubagentStop) in ~/.claude/settings.json.
# Removes what Claude Code and its agents leave behind once it has been idle for HOURS:
#   1. session folders under /tmp/claude-$UID (scratchpads, task outputs);
#   2. build caches (any folder holding a CACHEDIR.TAG, e.g. cargo's target/) inside agent
#      worktrees of the current project (.claude/worktrees/*). Source files, branches and
#      uncommitted work are never touched; a cache is rebuilt by the next build.
# DRY=1 prints what would be removed and removes nothing.
#
# `claude-cleanup.sh brief` (SubagentStart hook) removes nothing: it gives every subagent the
# clean-up rule, whichever skill or plugin (VibeWise, superpowers, a workflow) wrote its brief.
#
# Out of scope on purpose: plugin and skill state (.vibe-wise/, memory, GBrain, ~/.claude/plugins)
# and transcripts. Only the two places above are ever removed.
if [ "$1" = brief ]; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"Clean-up rule (user, all projects): write build and check outputs under the project build folder (for example rust/target/), never under /tmp (a RAM disk) or a shared scratchpad; delete bulky per-run outputs once their summary is recorded; do not delete plugin or skill state such as .vibe-wise/ or memory files. Claude session folders in /tmp and build caches of idle agent worktrees are removed automatically after 24 idle hours. Load rule (user, all projects): start any run that uses all cores for more than about 10 minutes as ~/.claude/bin/heavy-run <expected minutes> <command> (one heavy run at a time on the machine, heaviest first); give smaller runs $(~/.claude/bin/heavy-run --jobs) parallel jobs."}}'
  exit 0
fi
HOURS=${CLAUDE_CLEANUP_HOURS:-24}
mins=$((HOURS * 60))
run() { if [ -n "$DRY" ]; then echo "would remove: $*"; else rm -rf -- "$@"; fi; }

tmp="/tmp/claude-$(id -u)"
if [ -d "$tmp" ]; then
  # One unit per session folder (<project>/<session>): removed whole, and only when nothing in
  # it changed within the window. ctime, not mtime: copied or unpacked files (a Wine prefix,
  # an archive) keep old mtimes while the session using them is still live.
  for unit in "$tmp"/*/*; do
    [ -e "$unit" ] || [ -L "$unit" ] || continue
    [ -n "$(find "$unit" -xdev -cmin -"$mins" -print -quit 2>/dev/null)" ] && continue
    run "$unit"
  done
  [ -n "$DRY" ] || find "$tmp" -xdev -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null
fi

trees="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/worktrees"
if [ -d "$trees" ]; then
  # ponytail: depth 4 covers <worktree>/<a>/<b>/target; deepen if a project nests caches further
  find "$trees" -xdev -mindepth 2 -maxdepth 5 -name CACHEDIR.TAG -type f 2>/dev/null |
    while IFS= read -r tag; do
      cache=${tag%/CACHEDIR.TAG}
      # in use if anything near the top of the cache changed within the window
      [ -n "$(find "$cache" -maxdepth 2 -cmin -"$mins" -print -quit 2>/dev/null)" ] && continue
      run "$cache"
    done
fi
exit 0
