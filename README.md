# UVM Verification for LC3 Processor

ECE 748 Project 3: collaborative development of an LC3 verification environment using UVM and UVMF.

## Getting Started After Receiving an Invitation

1. Accept the repository collaboration invitation in your GitHub email or notifications. Make sure you are signed in to the account that was invited.
2. Install [Git](https://git-scm.com/downloads). You may use Git Bash or the terminal in VS Code.
3. Configure your Git identity once on your computer. Replace the example values with your own:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Use an email associated with your GitHub account, or your GitHub-provided no-reply email.

4. Clone the shared repository and enter its directory:

```bash
git clone https://github.com/frankeric654/UVM-Verification-for-LC3-Processor.git
cd UVM-Verification-for-LC3-Processor
```

Everyone works in this shared repository. A fork is not required for invited collaborators. When Git requests authentication for a push, sign in using the credential manager/browser prompt. GitHub account passwords cannot be used for HTTPS Git authentication; a personal access token is another supported option.

## Team Workflow

We use one shared repository, with a separate working branch for each stage. The main branch is the shared integration version. Push your work to your stage branch, open a pull request targeting main, and ask a teammate to review it before merging. Do not push development changes directly to main.

This is a team agreement; branch protection has not been configured by this document.

## Stage Assignments

| Stage | Owner | Working branch |
| --- | --- | --- |
| Control | Ivan | stage/control |
| Fetch | Ziyao | stage/fetch |
| Execute | Howard | stage/execute |
| Writeback | Cheng-Wei | stage/writeback |
| MemAccess | Shane | stage/memaccess |
| Decode | TBD — use the best design from Project 2 | stage/decode |

Cheng-Wei is responsible for creating the GitHub repository and sharing access information with the team.

Each stage owner should coordinate the stage interfaces, environment, predictor, and scoreboard. Agree on signal names, widths, clock/reset behavior, and sampling timing before integrating.

Ownership of LC3 integration, imem/dmem, the top-level bench, and regression is TBD and should be assigned by the team.

## Schedule

- **November 13, 2026:** Individual stage environments are due.
- **Follow-up meeting:** November 8, 2026 or later; exact date TBD.
- **Meeting agenda:** Discuss coverage targets and integration of all stage environments into the LC3 testbench.

## Create Your Working Branch

Start from the latest main branch. For example, the Fetch owner runs:

```bash
git switch main
git pull --ff-only origin main
git switch -c stage/fetch
```

Replace `stage/fetch` with your assigned branch name. Run `git switch -c` only when creating a new local branch. To return to an existing local branch, use:

```bash
git switch stage/fetch
```

Keep main as the shared integration branch. Make development changes on your own branch and submit a pull request when they are ready.

## Save and Upload Your Work

After editing your files, review the changes:

```bash
git status
git diff
```

Stage only the files you intend to share. Replace the example paths below with real paths:

```bash
git add path/to/changed_file.sv path/to/another_file.sv
git diff --cached
git commit -m "Add fetch environment and scoreboard"
git push -u origin stage/fetch
```

The first push uses `-u` to connect your local branch to its remote branch. For later updates on that branch:

```bash
git add path/to/changed_file.sv
git commit -m "Update fetch predictor"
git push
```

A commit saves a version locally. A push uploads those commits to GitHub so teammates can see them. Replace the branch name, file paths, and commit message with values appropriate to your work.

## Submit a Pull Request

1. Open the repository on GitHub.
2. Click **Compare & pull request**, or go to **Pull requests > New pull request**.
3. Select **base: main** and **compare: your working branch**.
4. Describe what changed, what you tested, and any remaining issues or dependencies. If simulation has not been run, say so.
5. Request a review from a teammate.
6. Address review comments by committing and pushing to the same branch; the pull request updates automatically.
7. After review and relevant checks pass, merge the pull request into main.

Use this description template:

```text
Changes:
- 

Validation:
- 

Remaining issues or dependencies:
- 
```

Team convention: use reviewed pull requests for main. This README does not itself enforce branch protection.

## Bring Teammates' Updates Into Your Branch

Commit your work first, then run the following while on your working branch:

```bash
git fetch origin
git merge origin/main
```

If the merge succeeds, run the relevant checks and upload the updated branch:

```bash
git push
```

If Git reports conflicts:

1. Run `git status` to identify conflicting files.
2. Discuss overlapping changes with the relevant teammate.
3. Edit each file to keep the correct combined result and remove conflict markers (`<<<<<<<`, `=======`, and `>>>>>>>`).
4. Stage the resolved files, complete the merge, and push:

```bash
git add path/to/resolved_file.sv
git commit
git push
```

To cancel an in-progress merge, use `git merge --abort`. Do not force-push shared branches to bypass a conflict or rejected push.

## Collaboration Rules

- Focus on your assigned stage; coordinate before editing shared integration files or another stage.
- Check UVMF generator output paths before generating files so you do not overwrite teammates' packages.
- Upload source code, generator inputs, scripts, and documentation needed to reproduce the project.
- Keep generated simulation libraries, temporary files, credentials, and machine-specific files out of commits. Maintain a shared `.gitignore`.
- Coordinate shared simulator setup, compile order, and regression commands with the integration owner.
- The project requires LC3-level simulation; individual-stage simulation is not required. Document test results and unresolved issues in pull requests.
- Keep commits small and use descriptive commit messages.
- Public visitors can read or clone this repository. Only the owner and authorized collaborators can directly push changes.

## Quick Workflow

```text
Accept invitation
  -> Clone the repository
  -> Create your branch from main
  -> Edit and validate
  -> Commit and push
  -> Open a pull request
  -> Teammate review
  -> Merge into main
  -> Sync your working branch
```


