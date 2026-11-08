simple-spec is a lightweight, harness-agnostic workflow for developing software from explicit, reviewable specifications.

The four phases are **Explore**, **Propose**, **Implement**, and **Archive**. The user can invoke each phase explicitly. For a requested phase, read and follow its instruction file:

* .simple-spec/skills/EXPLORE.md -> to explore new ideas or features with the user
* .simple-spec/skills/PROPOSE.md -> to make a proposal based on the explored ideas and discuss it with the user then create a plan with clear tasks
* .simple-spec/skills/IMPLEMENT.md -> to implement the proposed plan and tasks
* .simple-spec/skills/ARCHIVE.md -> to review what was done and archive the artifacts generated in the previous steps

Before accessing any specification, changelog, or change-workspace file, read `.simple-spec/config.yaml` and resolve its paths. `.simple-spec/` is at the project root; permanent specifications, the changelog, and change workspaces belong under the configured `specs.directory`. Active workspaces belong under  `changes/WIP/`; archived workspaces retained by the  `full` history mode belong under `changes/archived/`. After a successful Archive in `full` mode, move the workspace to `archived/` without changing its folder name. In `changelog` mode, remove the temporary workspace according to the configured policy. For legacy workspaces directly under `changes/`, move them to the matching state directory only when their state is clear; ask the user what to do if it is not. Never classify or move a workspace by guessing. Respect configured specification filenames and ordered templates; do not assume the default `specs/` location or default headings.

Require user approval at phase transitions as described by the relevant skill. Never claim successful verification without evidence. These instructions apply when an agent or harness reads this file; do not assume every harness loads it automatically.
