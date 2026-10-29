Simple Spec is a lightweight, harness-agnostic workflow for developing software from explicit, reviewable specifications.

The four phases are *Explore, **Propose, **Implement, and **Archive*. The user invokes each phase explicitly. For a requested phase, read and follow its instruction file:

* .simple-spec/skills/explore.md
* .simple-spec/skills/propose.md
* .simple-spec/skills/implement.md
* .simple-spec/skills/archive.md

Before accessing any specification, changelog, or change-workspace file, read `.simple-spec/config.yaml` and resolve its paths. `.simple-spec/` is at the project root; permanent specifications, the changelog, and change workspaces belong under the configured `specs.directory`. Active workspaces belong under  `changes/WIP/`; archived workspaces retained by the  `full` history mode belong under `changes/archived/`. After a successful Archive in `full` mode, move the workspace to `archived/` without changing its folder name. In `changelog` mode, remove the temporary workspace according to the configured policy. For legacy workspaces directly under `changes/`, move them to the matching state directory only when their state is clear; ask the user what to do if it is not. Never classify or move a workspace by guessing. Respect configured specification filenames and ordered templates; do not assume the default `specs/` location or default headings.

Require human approval at phase transitions as described by the relevant skill. Never claim successful verification without evidence. These instructions apply when an agent or harness reads this file; do not assume every harness loads it automatically.
