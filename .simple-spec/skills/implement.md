# Implement

## Purpose

Implement an approved change incrementally, verify each task's completion criteria, and keep the task checklist accurate.

## Invocation conditions

Use only when the user explicitly invokes **Implement** and the current proposal and task plan have explicit user approval. Do not advance to Archive automatically. Check the tasks that need to be implemented in `tasks.md`. If none left, please inform the user. 

## Required inputs

- The selected change's approved `proposal.md` and `tasks.md`.
- `.simple-spec/config.yaml`.
- Relevant project code, documentation, and permanent specifications.
- Evidence of the user's approval of the current proposal and task plan.

If required inputs or approval cannot be confirmed, explain what is missing and pause before implementation.

## Configuration requirements

1. Read `.simple-spec/config.yaml` at the project root before reading or writing any specification, changelog, or change-workspace file.
2. Interpret `specs.directory` relative to the project root. Reject absolute paths, `..` traversal, or paths (including symlink resolution) that escape the project root. Stop if configuration is missing, invalid, or unsafe; do not guess a default.
3. Resolve permanent documents from `specs.functional.file` and `specs.technical.file`, relative to the configured specification directory. Reject absolute paths, `..` traversal, or symlinks that resolve outside that directory. Resolve active workspaces under `changes/WIP/` and retained archived workspaces under `changes/archived/`. Never treat an archived workspace as active. For a legacy workspace directly under `changes/`, ask the user if its state is unclear; move a confirmed active workspace to WIP, or a confirmed archived workspace to `archived/` only if it should be retained, preserving its folder name. Never hardcode `specs/` or default permanent filenames.
4. Use the configured `language` for generated change artifacts and user-facing summaries. If it is missing or unusable, ask rather than guessing.
5. Interpret YAML as workflow input; do not add executable configuration parsing.

## Files

### May read

- `AGENTS.md`, `.simple-spec/config.yaml`, the selected `proposal.md` and `tasks.md`.
- Relevant project code and documentation, plus configured permanent specifications.

### May create or modify

- Application files needed for approved tasks.
- The selected `tasks.md`, to record progress and verified completion.
- `proposal.md` only when a material change is explicitly approved by the user; record the agreed change while preserving prior decisions and traceability.

Preserve all existing user changes. Work only in the selected approved workspace under `changes/WIP/`; do not modify archived or unrelated change workspaces or permanent specifications in this phase.

## Workflow

1. Resolve the selected active change under `changes/WIP/` and confirm the current proposal and task plan have explicit user approval. Never implement a workspace under `changes/archived/`. For a legacy workspace directly under `changes/`, move it to WIP only after confirming it is active. If it is confirmed archived and the user wants it retained, move it to `changes/archived/` without implementing it. A clear user request to begin Implement can serve as approval only when it refers to the proposal and plan already presented; if workspace state or approval is uncertain, ask the user what to do.
2. Read the proposal, checklist, relevant code and docs, and permanent specifications at configured paths. Identify the next incomplete task and its dependencies and completion criteria.
3. Implement the smallest coherent unit within the approved scope. Preserve unrelated work and avoid unrelated refactoring.
4. Run relevant tests and verification commands for the task. Compare the actual result with its stated completion criteria and the proposal. Do not claim a command ran if it did not, hide failures, or remove tests to make the change pass.
5. Mark a task complete in `tasks.md` only after its completion criteria have been verified. Record useful verification evidence or results in the task entry/checklist. If work is incomplete or verification fails, leave it unchecked and report the state accurately.
6. Repeat for the next task only while the approved scope remains clear. If implementation reveals an important ambiguity or contradiction, pause and ask. If the proposal must change materially, obtain user approval and update `proposal.md` and `tasks.md` before continuing.
7. Summarize changed files, completed and incomplete tasks, commands actually run and their results, and remaining limitations. Ask for explicit approval before Archive. Stop at this phase.

## Rules and constraints

- Stay within the approved proposal; do not silently change requirements or architecture.
- Do not mark tasks complete merely because code was written. A task is complete only after its stated criteria are verified.
- Do not hide failing checks or claim tests passed without evidence. If a relevant check cannot be run, say why and leave affected work incomplete unless its criteria can be verified another way that the proposal permits.
- Do not remove existing tests merely to make implementation pass.
- Preserve existing user changes and avoid unrelated refactoring.

## Completion criteria

The change is ready for review when all mandatory tasks are complete and relevant tests or other verification have been executed with known results. If a task is blocked, incomplete, or a relevant check could not run, explicitly report it; do not present the change as ready for Archive.

## User-facing output

In the configured language, report changed files, task status, verification commands actually run and their actual results, and remaining limitations. Ask for explicit approval before Archive. Never report unverified success.

## Clarification and approval

Ask the user what to do whenever workspace state, approval, task dependencies, scope, or a material requirement is unclear, or implementation exposes a contradiction. Obtain explicit approval for any material proposal change and for the transition to Archive. Approval to implement does not approve archiving.
