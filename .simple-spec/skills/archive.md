# Archive

## Purpose

Consolidate a completed change into the permanent functional and technical specifications, update the changelog, and apply the configured history policy.

## Invocation conditions

Use only when the user explicitly invokes **Archive** for a completed change. Do not archive automatically at the end of Implement.

## Required inputs

- The selected change's `proposal.md` and `tasks.md`.
- Evidence that all mandatory tasks are complete and relevant verification results are known.
- `.simple-spec/config.yaml`.
- The current implementation and configured permanent specifications.
- Explicit user approval to archive this change.

If any required input, approval, or file cannot be confirmed, explain the limitation and stop before consolidation or cleanup.

## Configuration requirements

1. Read `.simple-spec/config.yaml` at the project root before accessing any specification, changelog, or change-workspace file.
2. Resolve `specs.directory` relative to the project root. Reject absolute paths, `..` traversal, or paths (including symlink resolution) that escape the project root. If configuration is missing, invalid, or unsafe, stop and ask for correction; do not guess.
3. Resolve the functional and technical permanent filenames from `specs.functional.file` and `specs.technical.file`, relative to the configured specification directory. Reject absolute paths, `..` traversal, or symlinks that resolve outside that directory. The changelog filename is always `changelog.md`; active workspaces are under `changes/WIP/`, and retained archived workspaces are under `changes/archived/`, relative to the configured directory. Never treat an archived workspace as active. For a legacy workspace directly under `changes/`, ask the user if its state is unclear; move a confirmed active workspace to WIP before archiving, preserving its folder name. Move a confirmed archived workspace to `archived/` only if it should be retained, and do not process it as active again. Never hardcode `specs/` or default permanent filenames.
4. Read `specs.history.mode`. Allowed values are `full` and `changelog`. For missing or invalid values, do not delete anything; ask for clarification or preserve history conservatively.
5. Use `language` for changelog entries and user-facing summaries. If it is missing or unusable, ask rather than guessing. Workflow instructions remain in English.
6. Treat each configured `template.sections` list as the structural reference. Preserve the configured order, custom titles and descriptions, and valid existing content. Keep required sections; optional sections may have no documented requirements when none are established. Section IDs are stable matching identifiers, not substitutes for content. Do not assume default headings or require default sections. Do not add executable configuration parsing.

## Files

### May read

- `AGENTS.md`, `.simple-spec/config.yaml`, the selected change's notes, proposal, and tasks.
- Relevant implementation and project documentation.
- The configured permanent functional and technical specification files and changelog.

### May create or modify

- The configured permanent functional specification.
- The configured permanent technical specification.
- `<configured specs directory>/changelog.md`.
- Only the selected workspace: in `full` mode, move it from WIP to `archived/` after successful consolidation and verification; in `changelog` mode, remove it after successful consolidation and verification.

Do not modify or delete unrelated active or archived changes. Do not change application code in Archive.

## Preconditions

Before changing permanent specifications, confirm all mandatory tasks are complete, relevant tests or verification were executed and their results are known, there are no unresolved mandatory decisions, and the user explicitly approved Archive. A clear current user request to Archive the identified, completed change is explicit approval; do not treat approval to Implement as Archive approval. Do not archive incomplete changes.

## Workflow

### 1. Resolve configuration and the change

Read configuration and validate paths and history mode. Identify the exact active change directory in `YYYY-MM-DD-change-name` form under the configured `changes/WIP/`. Never select a workspace under `changes/archived/` as active. If workspace identity or state is ambiguous, multiple changes could match, or path resolution is unsafe, ask the user what to do and stop. If a selected legacy workspace directly under `changes/` is confirmed active, move it into WIP without changing its name before proceeding. If it is confirmed archived, move it to `archived/` only if it should be retained, and stop without running Archive again. Confirm the workspace has the expected `notes.md`, `proposal.md`, and `tasks.md` for an active workspace.

### 2. Reconcile the delivered change

Compare the approved proposal and task results with the implementation. The proposal is not proof that a feature was delivered. If implementation differs materially from the approved proposal, stop and ask how to proceed. Use actual delivered behavior and known verification results as the basis for permanent documentation.

### 3. Update the functional specification

Read the configured functional document. Reflect the functional behavior delivered by the change. Use stable IDs where practical to match sections; order configured sections as listed and use their current configured titles, preserving the section content. Add a missing configured section with its configured title; do not invent requirements to fill it. Preserve valid existing requirements and user-authored content, including content in sections no longer represented in the template. Integrate new requirements, update obsolete ones only when justified, and avoid duplication or contradiction. Do not replace the whole document unnecessarily. If reconciling the current template with existing content could lose or misplace valid requirements, preserve the content and ask the user how to proceed.

### 4. Update the technical specification

Read the configured technical document. Document lasting technical design and contracts delivered by the change, such as relevant architecture, interfaces, dependencies, data contracts, and constraints. Use stable IDs where practical to match sections; order configured sections as listed and use their current configured titles, preserving the section content. Add a missing configured section with its configured title; do not invent decisions to fill it. Preserve valid existing decisions and user-authored content, including content in sections no longer represented in the template; update superseded decisions only when supported. Avoid transient implementation details and invented decisions. Do not replace the whole document unnecessarily. If reconciling the current template with existing content could lose or misplace valid decisions, preserve the content and ask the user how to proceed.

### 5. Update the changelog

Always update `<configured specs directory>/changelog.md`, regardless of history mode. Add the completion date, change name, concise summary, relevant specification or change reference, and significant user-visible behavior or technical change. Use the configured language. In `full` mode, make the change reference identify its final path under `changes/archived/`, even though the move occurs after verification. Do not record completion until both permanent specification updates and the changelog update have succeeded.

### 6. Verify consolidation

Review the updated files. Confirm the permanent specifications reflect delivered behavior; configured template order and custom headings are respected; the changelog is updated; no unsupported, duplicate, or contradictory requirements were introduced; and no unrelated files were changed. If a mandatory update fails, report the failure and do not claim successful archival. Do not begin history cleanup until consolidation has succeeded and been verified.

### 7. Apply history policy

- `full`: after successful, verified consolidation, create the `changes/archived/` parent directory if needed, confirm the target folder does not already exist, then move the complete selected workspace from `changes/WIP/YYYY-MM-DD-change-name/` to `changes/archived/YYYY-MM-DD-change-name/`, preserving the folder name and all three required files. If the destination already exists or the move fails, do not overwrite anything or claim completion; report the state and ask the user what to do.
- `changelog`: only after successful, verified consolidation, remove only the selected workspace under `changes/WIP/`. Retain the parent `changes/` directory and all unrelated changes. If safe removal cannot be confirmed, do not remove anything and report that cleanup did not complete.
- Missing or invalid mode: preserve the workspace under `changes/WIP/` and ask for clarification. Never move or delete it under an unknown policy.

### 8. Report

Summarize the specifications updated, changelog entry, history policy, whether the selected workspace was moved to `changes/archived/` or removed, and any remaining limitation. Use the configured language. Stop; do not begin another phase.

## Rules and constraints

- Do not implement code, archive incomplete work, or remove files before successful consolidation.
- Preserve valid requirements, custom template structure, and user work. Do not rewrite permanent specifications unnecessarily.
- Never delete the parent `changes/` directory or unrelated active or archived changes.
- Never claim successful archival if any required update or verification failed.

## Completion criteria

Both configured permanent specifications and the changelog accurately reflect the delivered, verified change; custom template structure has been respected; and the selected history policy has been applied safely. In `full` mode, the complete workspace is in `changes/archived/` with its name unchanged. Any failed update, unresolved mandatory decision, or incomplete move or cleanup is reported as incomplete.

## User-facing output

In the configured language, report the permanent specification files updated, changelog entry, history mode applied, workspace move to `changes/archived/` or removal, verification outcome, and remaining limitations. Do not claim successful archival without evidence.

## Clarification and approval

Ask the user what to do and stop if workspace identity or state, approval, tasks, relevant verification, or a mandatory decision is unclear; the implementation materially differs from the proposal; paths or history mode are unsafe or invalid; the archived destination already exists; or configured templates conflict with existing content in a way that risks discarding it. A request to Implement or prior approval of the proposal is not approval to Archive.
