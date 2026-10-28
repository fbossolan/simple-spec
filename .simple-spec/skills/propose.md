# Propose

## Purpose

Turn exploration findings into a reviewable functional and technical proposal and an ordered implementation checklist.

## Invocation conditions

Use only when the user explicitly invokes **Propose** or approves moving from Explore to Propose. Do not start Implement automatically. If the exploration phase is completed, you can guide the user to start the proposal phase of the workflow.

## Required inputs

- The selected change's `notes.md`.
- `.simple-spec/config.yaml`.
- Relevant project code and documentation.
- Existing permanent functional and technical specifications, when available.

If required files cannot be accessed, explain the limitation rather than inventing their contents.

## Configuration requirements

1. Read `.simple-spec/config.yaml` at the project root before reading or writing any specification or change-workspace files.
2. Interpret `specs.directory` relative to the project root. Reject absolute paths, `..` traversal, or paths (including symlink resolution) that escape the project root. Stop if configuration is missing, invalid, or unsafe; do not guess a default.
3. Resolve permanent documents using `specs.functional.file` and `specs.technical.file` relative to the configured specification directory. Reject absolute paths, `..` traversal, or symlinks that resolve outside that directory. The changelog is `changelog.md`; active workspaces are under `changes/WIP/`, and retained archived workspaces are under `changes/archived/`. Never treat archived workspaces as active. For a legacy workspace directly under `changes/`, ask the user if its state is unclear; move a confirmed active workspace to WIP or a confirmed archived workspace to `archived/` only if it should be retained, preserving its folder name. Never hardcode `specs/` or default permanent filenames.
4. Treat each configured `template.sections` list as an ordered, customizable reference: honor its current section order, titles, descriptions, and required flags where relevant. IDs are stable configuration identifiers, not replacements for section content. Do not assume default section names or require every permanent-spec section in each proposal.
5. Write `proposal.md`, `tasks.md`, questions, and user-facing summaries in the configured `language`. If it is missing or unusable, ask rather than guessing.
6. Interpret the YAML directly as workflow input; do not add executable configuration parsing.

## Files

### May read

- `AGENTS.md`, `.simple-spec/config.yaml`, the selected `notes.md`, relevant project code and documentation.
- The configured permanent functional and technical specifications.

### May create or modify

- `proposal.md` and `tasks.md` in the selected change workspace.

Do not implement application code, modify permanent specifications, or modify unrelated files. A change workspace has these three required files: `notes.md`, `proposal.md`, and `tasks.md`. Do not add other change files by default.

## Workflow

1. Identify the active change workspace from the user's instruction or Explore context. Select only a workspace under `changes/WIP/`; never select one under `changes/archived/` as active. Reuse the selected workspace; do not create a duplicate. If the workspace identity, state, or feature is ambiguous, ask the user what to do instead of guessing. For a legacy workspace directly under `changes/`, move it to `changes/WIP/` only after confirming it is active; if it is archived, do not use it for Propose and move it to `changes/archived/` only if the user confirms it should be retained.
2. Read the selected workspace's `notes.md`, configuration, relevant project context, and permanent specifications at their configured paths. Use that `notes.md` as the source for the feature proposal and task plan; do not substitute notes from another workspace.
3. Compare the findings with existing behavior and specifications. Identify conflicts, ambiguities, missing requirements, scope boundaries, and implementation constraints. Preserve the distinction between confirmed requirements, suggestions, assumptions, and unresolved decisions.
4. Ask the user to resolve important uncertainties before finalizing. Do not convert an assumption into an approved requirement. Non-blocking assumptions may remain only when labeled and explicitly called out for review.
5. Create or update `proposal.md` in the configured language. Include these conceptual sections, adapting headings to that language:
   - Summary.
   - Goals and scope.
   - Functional specification.
   - Technical specification.
   - Error handling and edge cases.
   - Testing and verification strategy.
   - Risks, constraints, assumptions, and unresolved decisions.
6. Keep functional and technical content clearly separated. Use the configured permanent templates as references where applicable, respecting customized sections and structure; include only sections relevant to this change. Do not invent content to fill a section.
7. Create or update `tasks.md` as an ordered Markdown checklist. Each task must be actionable, have a clear outcome and verifiable completion criteria, be small enough to implement and verify, respect dependencies, and link to a proposal requirement or section when practical. Include testing or other verification work where appropriate. Do not mark tasks complete during Propose.
8. Present the proposal, task list, assumptions, and unresolved decisions for review. Request explicit user approval of the proposal and task plan before Implement. Stop at this phase.

## Rules and constraints

- Propose does not implement code, modify permanent specifications, or start Implement automatically.
- Preserve confirmed requirements and existing user work. Do not quietly broaden scope or resolve important decisions on the user's behalf.
- Do not use the proposal as evidence that a behavior has already been implemented.
- Keep the proposal limited to this change and avoid generic tasks such as “make everything work.”

## Completion criteria

`proposal.md` explains what should change and why, the functional and technical decisions, scope, risks, and how success will be verified. `tasks.md` is an ordered, actionable checklist with completion criteria. The user has been shown both and asked for explicit approval before implementation.

## User-facing output

In the configured language, identify the change workspace; summarize the proposal, task plan, assumptions, and unresolved decisions; and ask for explicit approval. State any limitations. Do not claim that implementation or verification has occurred.

## Clarification and approval

Ask the user what to do whenever workspace identity or state, requirements, scope, or another material decision is unclear; never guess. Do not begin Implement until the user explicitly approves the proposal and task plan. An earlier approval to Explore is not approval to implement.
