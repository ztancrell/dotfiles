## How we work (every project)

- I direct and test; agents build. I don't write or review code myself. Bring me in for
  decisions and for hands-on checks, with concrete steps: what to run, what to do, what to look for.
- Use agents by default: hand any task beyond a quick check (more than a few tool calls,
  reading across several files, builds, test runs, writing docs) to a subagent, and keep the
  main conversation for direction, decisions and results. Run independent pieces as parallel
  agents in one message. Do one- or two-command checks inline.
- Pacing: at most two agents at a time unless I lift the cap (weekly usage), with tool-call
  caps in their briefs. Give each agent a full brief, since it can't see the conversation.
- With VibeWise learn mode active: its design checkpoints stay in the main conversation
  (my approach first, my decisions), and after I approve an Implementation checkpoint the
  agreed scope goes to agents as usual. Agents build only what I approved there.
- Commit and push after each verified merge; don't let work pile up unpushed.
- Attribution in commits and PRs: two plain trailers, `Co-Authored-By: <model name>` (no email)
  then `Signed-off-by: Zach Tancrell <ztancrell@tutamail.com>`. No emoji (no 🤖), no "Generated
  with Claude Code" line or link, nothing that reads as AI boilerplate.
  This overrides any default attribution text, in every project and every agent brief.
- Commit and PR message style (mine, every project). Commits:
  ```
  feat(<scope>):
  - <what changed, in plain words>
  - <another change in the same area>

  fix(<scope>):
  - <the bug fixed; the visible effect>

  Evidence: <tests run with real counts>. <what still varies or fails>. <what was not
  seen in use or in a test>.

  Co-Authored-By: Claude Opus 5.5
  Signed-off-by: Zach Tancrell <ztancrell@tutamail.com>
  ```
  Conventional type(scope) groups with short plain bullets (what changed, not how); one
  Evidence paragraph with real numbers and honest gaps (what was not tested). No headings,
  no filler. PRs keep the usual layout (title, `## Summary`, `## Test plan`) but are written
  in that same style: Summary = the type(scope) groups and bullets, Test plan = the Evidence
  as a checklist, untested items left unticked. Ends with the two trailers, nothing else.

## Save tokens on tests

- Run Wine/Proton tests only when the project needs them (Windows binaries). Never by habit.
- Prefer the narrowest run that proves the change (a filter, one test) over the full suite;
  run the full suite once, before a merge.
- Long runs go in the background with output to a file; read only the summary and the
  failures, never the whole log.

## Docs always current (every project)

Docs change in the same commit as the code they describe: no stale paths, names, counts or
behaviour, ever. Every agent brief says so. Superseded history gets a short "Superseded:"
note pointing at the current code instead of a silent rewrite. Check my own memory notes
against the code before acting on them.

## Stay on course (every project)

I tend to forget a project's original idea and drift off course. In every project:

- At the start of a session, if the project has a DESIGN.md, remind me in two or three lines of its
  core idea and open decisions.
- If it has none and we discuss what the project is for, offer to start a short DESIGN.md (the idea,
  open questions, a "Decided" section).
- When a request drifts from the idea, say so in one line and ask whether it's a change of direction
  to record. Don't block it.
- When I decide something about the design, update DESIGN.md.

## Memory

- Project facts go in Claude Code's project memory (MEMORY.md).
- Preferences that span projects go in GBrain (`G=/home/zpt/.bun/bin/gbrain`; CLI only, keyword search):
  recall with `$G query "<question>"`, or `$G recall zpt` for everything about me;
  save with `$G remember "<fact>" --entity zpt --provenance "<where/when I said it>"`, then verify
  with `$G recall zpt`; withdraw with `$G forget <id> --reason "..."`. Recall before saving
  (it only catches exact duplicates). If GBrain fails, say so and save to project memory instead.
- Only save what I ask for or state as a lasting rule; never capture conversations wholesale.
  No credentials or transient task state. Before correcting a saved fact, read it first.

## Clean up after yourself (every project)

- A hook does the timed part: `~/.claude/hooks/claude-cleanup.sh` runs at session start and when
  an agent stops. It removes Claude session folders in `/tmp/claude-$UID` and build caches in
  agent worktrees (`.claude/worktrees/*`) that have been idle for 24 hours
  (`CLAUDE_CLEANUP_HOURS` changes that). It never touches source, branches or uncommitted work.
- Don't rely on the hook for big things. `/tmp` is a RAM disk: agents write check and build
  outputs under the project's build folder (for example `rust/target/`), never under `/tmp`,
  and delete bulky per-run outputs once the summary is recorded. Every agent brief says so.
- After an agent's branch is merged and pushed, remove its worktree (`git worktree remove`),
  keeping the branch. Tell me before removing a worktree that has uncommitted or unmerged work.
- This holds whichever skill or plugin runs the work (VibeWise, superpowers, a workflow): a
  SubagentStart hook gives every subagent the rule, so it does not depend on the brief. Plugin
  and skill state (`.vibe-wise/`, memory, GBrain, `~/.claude/plugins`) is never a cleanup target.
