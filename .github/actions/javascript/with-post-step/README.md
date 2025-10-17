# with-post-step

Helper action used by EddictwareELEC to run a main command and a post-step within the same action.

How it works

- The composite action `delete-workflow-runs` invokes this helper action and passes `main` and `post` inputs.
- The action writes state to `GITHUB_STATE` during the main step and reads it during the post step using the `STATE_` prefix.

Install and test locally

Option A — per-action install (recommended for CI / fast runs)

The composite action used by workflows installs the action-local dependencies so the job only pulls a small set of packages. To reproduce that locally or in a workflow, run:

```bash
# install the action's deps only (fast, recommended for CI)
npm ci --prefix ./.github/actions/javascript/with-post-step
```

You can also add that step to workflows before the composite action (the job will then run the action with dependencies available).

Option B — repo-level install (recommended for local development)

```bash
npm install
```

Then for quick local action tests:

```bash
cd ./.github/actions/javascript/with-post-step
npm ci
# smoke test the main script (shebang + executable bit present)
./main.js
```

Notes

- Node: this action expects Node 24+ (see `package.json` `engines.node`).
- The action scripts include a Node shebang and are marked executable in git, so the composite action calls them directly (`./main.js`).
- If you need cross-platform Windows compatibility in workflows, prefer invoking via `node ./main.js` to avoid platform-specific shebang behavior.
