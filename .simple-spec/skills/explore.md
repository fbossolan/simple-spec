# Explore

## Purpose

Clarify what the user wants to build before proposing a solution. Act as an inquisitive senior engineer: use the project's existing functional and technical specifications to understand context, constraints, and fit. Do not invent requirements.

## Invocation conditions

Run only when the user explicitly asks to explore an idea. State clearly that the user is in the Explore phase. Do not move to Propose automatically.

## Required inputs

- The user's idea or problem to explore.
- Project-root access to `.simple-spec/config.yaml` and relevant project context.

If required files or configuration are unavailable, explain the limitation rather than guessing.

## Configuration requirements

1. Read `.simple-spec/config.yaml` before accessing specification or change-workspace files.
2. Resolve `specs.directory` relative to the project root. Stop if it is missing, invalid, absolute, traverses with `..`, or resolves outside the project root.
3. Resolve the functional and technical specifications from `specs.functional.file` and `specs.technical.file`, relative to the configured specification directory. Reject paths that escape that directory. Active changes live under `changes/WIP/`; archived changes retained by the `full` history mode live under `changes/archived/`. Never treat archived workspaces as active. For a legacy workspace directly under `changes/`, determine its state only from unambiguous context; ask the user if unclear. Move a confirmed active workspace to `changes/WIP/`, or a confirmed archived workspace that should be retained to `changes/archived/`, without changing its name. Do not hardcode `specs/` or default filenames.
4. Use the configured `language` for notes, questions, and user-facing summaries. Workflow instructions remain in English. If the language is missing or unclear, ask.
5. Treat YAML as workflow input; do not add executable configuration parsing.

## Files

### May read

- `AGENTS.md`, `.simple-spec/config.yaml`, relevant project documentation and code.
- The configured permanent functional and technical specifications.
- `notes.md` in the selected existing active workspace under `changes/WIP/`.

### May create or modify

- Only `notes.md` in the selected active change workspace: `<configured specs directory>/changes/WIP/YYYY-MM-DD-<spec-name>/notes.md`.

Do not create `proposal.md` or `tasks.md`, modify permanent specifications, or add other change files.

## Workflow

1. Read project guidance, configuration, relevant code and documentation, and the configured functional and technical specifications. Use the specifications' current structure and content as context; do not assume default headings or treat existing specs as proof of new requirements.
2. Identify the spec the user wants to develop. For a continuing change, reuse its active workspace under `changes/WIP/`. Never select a workspace under `changes/archived/` as active. If the workspace identity or state is unclear, ask the user what to do. For a legacy workspace directly under `changes/`, move it to `changes/WIP/` only after confirming that it is active, or to `changes/archived/` only after confirming it is archived and should be retained; preserve its folder name.
3. For a new change, propose a concise kebab-case folder name based on the spec being discussed. Tell the user the proposed name and that notes will be kept in `notes.md` under the change folder. Ask whether they want to change the name; use their chosen name before creating the folder. Use the actual creation date in `changes/WIP/YYYY-MM-DD-<spec-name>`. Do not create duplicate workspaces for the same active change.
4. Create the WIP workspace and `notes.md`. In the configured language, explicitly tell the user they are in the Explore phase and that the notes are in the resolved `<configured path>/notes.md`. Record the original idea, confirmed requirements and decisions, alternatives, assumptions, technical observations, questions and answers, and unresolved decisions. Keep these categories distinct.
5. Ask focused questions incrementally to clarify what to build. Use the project context to probe behavior, users, scope, constraints, dependencies, and success criteria. Update `notes.md` as the user answers. Do not silently turn assumptions or suggestions into confirmed requirements.
6. Continue until all material questions are answered or the user explicitly defers them. Record any deferred decision and whether it blocks a proposal. Do not present an unanswered material question as resolved.
7. When exploration is ready to hand off, state that the notes are in the exact `notes.md` path. Summarize confirmed decisions, assumptions, and any deferred items. Ask whether the user wants to move to Propose, where the agent will create `proposal.md` and the separate implementation checklist in `tasks.md`. Stop and wait for explicit approval.

## Rules and constraints

- Explore does not implement code, create `proposal.md` or `tasks.md`, or modify permanent specifications.
- Preserve existing notes and user work. Do not overwrite or discard prior decisions silently.
- Keep questions concise and focused on details that affect behavior, scope, or technical direction.
- Do not claim that notes were created or updated unless that work succeeded.

## Completion criteria

The selected workspace contains useful, current `notes.md`; no material clarification question remains unanswered unless the user explicitly deferred it; and the user has been told where the notes are and asked whether to proceed to Propose.

## User-facing output

Use the configured language. Be direct: identify the Explore phase, the proposed or selected workspace name, the exact `notes.md` path, key findings, and any deferred decisions. At handoff, explain that Propose will create `proposal.md` and `tasks.md`, then ask for approval.

## Clarification and approval

Ask the user what to do whenever the feature, workspace identity or state, or another required decision is ambiguous; never guess. Ask whether the user wants to rename a newly proposed folder before creating it. Ask focused product and technical questions until material uncertainties are answered or explicitly deferred. Require explicit approval before moving to Propose; an Explore request is not approval for the next phase.
