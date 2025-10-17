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

function run(cmd) {
  const subprocess = spawn(cmd, { stdio: "inherit", shell: true });
  subprocess.on("exit", (exitCode) => {
    process.exitCode = exitCode;
  });
}

const key = process.env.INPUT_KEY.toUpperCase();

if ( process.env[`STATE_${key}`] !== undefined ) { // Are we in the 'post' step?
  // console.log("INPUT_POST: " + process.env.INPUT_POST);
  // console.log("INPOST: " + process.env.STATE_INPOST);
  run(process.env.INPUT_POST);
} else { // Otherwise, this is the main step
  // appendFileSync(process.env.GITHUB_STATE, `${key}=true${EOL}`);
  // {{github.workflow_ref}}
  // ${{github.run_id}}
  // {{github.run_attempt}}
  console.log(`key: ${key}`);
  appendFileSync(process.env.GITHUB_STATE, `${key}=true${EOL}`);
  run(process.env.INPUT_MAIN);
}
