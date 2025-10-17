#!/usr/bin/env node
// 1. In your action code (pre or main), append key/value lines to the file at process.env.GITHUB_STATE. Use UTF-8 and OS newline. Example (JavaScript):
//   import * as fs from 'fs'
//   import * as os from 'os'
//   // This example uses JavaScript to write to the GITHUB_STATE file. The resulting environment variable is named STATE_processID with the value of 12345:
//   fs.appendFileSync(process.env.GITHUB_STATE, `processID=12345${os.EOL}`, { encoding: 'utf8' })
// 2. In your post: action code, read the saved value from the environment using the STATE_ prefix. Example (JavaScript):
//   console.log("The running PID from the main action is: " + process.env.STATE_processID);
// 3. Remember:
//   1. GITHUB_STATE is only available within an action (not arbitrary workflow steps).
//   2. Only the action where the value was written can access that saved STATE_ value.
//   3. Use environment files (GITHUB_ENV, GITHUB_OUTPUT, GITHUB_STATE, GITHUB_PATH, GITHUB_STEP_SUMMARY) per the workflow-commands docs when communicating between steps/actions.GITHUB_STATE is only available within an action (not arbitrary workflow steps).
// If you also need to disable or re-enable workflow command processing within a run, use the ::stop-commands:: marker pattern (see workflow commands docs).


// https://github.com/pyTooling/Actions/blob/dev/with-post-step/main.js
// const { spawn } = require("child_process");
// const { appendFileSync } = require("fs");
// const { EOL } = require("os");
import { spawn } from "child_process";
import { appendFileSync } from "fs";
import { EOL } from "os";
import { fileURLToPath } from "url";
import { resolve } from "path";
// import * as core from "@actions/core";
import * as github from "@actions/github";

function run(cmd) {
  const subprocess = spawn(cmd, { stdio: "inherit", shell: true });
  subprocess.on("exit", (exitCode) => {
    process.exitCode = exitCode;
  });
}

const key = process.env.INPUT_KEY.toUpperCase();

if ( process.env[`STATE_${key}`] !== undefined ) { // Are we in the 'post' step?
  run(process.env.INPUT_POST);
} else { // Otherwise, this is the main step
  // {{github.workflow_ref}}
  // ${{github.run_id}}
  // {{github.run_attempt}}
  console.log(`key: ${key}`);
  appendFileSync(process.env.GITHUB_STATE, `${key}=true${EOL}`);
  const run_id=github.run_id;
  appendFileSync(process.env.GITHUB_STATE, `run_id=${run_id}${EOL}`);
  // Guard: if INPUT_MAIN resolves to this action's main file, spawning it will recurse forever.
  // Detect common misconfiguration where the composite action passes the action's own main as the
  // input `main` value and abort with a clear error to avoid infinite loops seen in CI logs.
  try {
    const currentFile = fileURLToPath(import.meta.url);
    const inputMain = process.env.INPUT_MAIN || "";
    // Resolve the input path relative to the current working directory (the workflow workspace).
    const resolvedInputMain = inputMain ? resolve(process.cwd(), inputMain) : "";
    if (resolvedInputMain && resolvedInputMain === currentFile) {
      console.error(
        `Refusing to spawn INPUT_MAIN which resolves to the action main file (${currentFile}). This would cause recursion. Please set the composite action 'main' input to a different script or command.`
      );
      process.exitCode = 1;
      process.exit(1);
    }
  } catch (err) {
    // If resolution fails for any reason, fall back to attempting to run the input. We still
    // keep this non-destructive and let the spawn handler surface errors.
  }

  run(process.env.INPUT_MAIN);
}
