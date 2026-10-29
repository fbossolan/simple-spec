```text
         _                 __
   _____(_)___ ___  ____  / /__        _________  ___  _____
  / ___/ / __ `__ \/ __ \/ / _ \______/ ___/ __ \/ _ \/ ___/
 (__  ) / / / / / / /_/ / /  __/_____(__  ) /_/ /  __/ /__
/____/_/_/ /_/ /_/ .___/_/\___/     /____/ .___/\___/\___/
                /_/                     /_/
```

# Simple Spec

Simple Spec is a lightweight, harness-agnostic workflow for spec-driven development. It keeps work explicit and reviewable without requiring a large or token-heavy process. Just as importantly, it gives you room to explore and brainstorm an idea with an AI agent, then collaborate with it to shape and deliver the feature.

## Set up on a new machine

Download or clone this repository and keep it available: the initializer reads its templates from the repository directory. From the repository root, make the script executable and add a `simple-spec` alias to your Zsh configuration:

```sh
chmod +x simple-spec-init.sh && printf '\nalias simple-spec="%s/simple-spec-init.sh"\n' "$PWD" >> ~/.zshrc && source ~/.zshrc
```

In the project where you want to use Simple Spec, run `simple-spec`. The initializer prompts for the specification folder and for approval before creating files. It adds `.simple-spec/` (configuration and phase instructions), an `AGENTS.md` guidance block, and starter specification and change-workspace files. Existing files are kept. Review `.simple-spec/config.yaml` to configure the language, specification filenames and templates, history mode, and specification directory.

## Work through the four phases

Invoke phases explicitly with your agent; it will follow the corresponding instructions in `.simple-spec/skills/` and use the project configuration.

1. **Explore** — Start with a prompt such as: “Let’s explore the development of a new feature that …” Brainstorm the problem and clarify requirements, constraints, alternatives, and open questions. The agent records the discussion in `notes.md` in a dated work-in-progress workspace. No code is changed.
2. **Propose** — Once you approve moving forward, ask the agent to **Propose**. It turns the notes into a reviewable `proposal.md` and an ordered `tasks.md` implementation checklist. Review and approve both before implementation.
3. **Implement** — Ask the agent to **Implement** after approving the proposal and task plan. It works through the checklist incrementally, verifies work, and records task progress.
4. **Archive** — When implementation is complete and verified, explicitly ask the agent to **Archive**. It updates the permanent functional and technical specifications and changelog, then retains or removes the temporary workspace according to the configured history mode.

Each phase has a human review/approval handoff. The permanent specifications describe the product; the workspace notes, proposal, and checklist capture the thinking and plan for one change.
