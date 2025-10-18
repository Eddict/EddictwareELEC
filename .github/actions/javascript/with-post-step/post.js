#!/usr/bin/env node
/*
	Post step: if the main step saved a run id to GITHUB_STATE (STATE_RUN_ID), delete that
	workflow run using the GitHub REST API. Requires the runner to have GITHUB_TOKEN with
	actions: write or equivalent permissions. This runs in the action 'post' phase and will
	attempt a delete when STATE_INPOST and STATE_RUN_ID are present.
*/
import * as github from "@actions/github";
import { writeFileSync } from 'fs';
import { join } from 'path';

// The main step writes STATE_<KEY> entries into GITHUB_STATE. Prefer STATE_ variables,
// but fall back to runner env vars when necessary (GITHUB_RUN_ID).
const inpost = process.env.STATE_INPOST || process.env.INPOST || false;
// Accept either uppercase or lowercase keys and fall back to runner env var GITHUB_RUN_ID.
const runId = (process.env.STATE_RUN_ID || process.env.STATE_run_id || process.env.GITHUB_RUN_ID || process.env.RUN_ID || '').toString();

console.log(`INPOST: ${inpost}`);
console.log(`RUN_ID: ${runId}`);

if (inpost && runId) {
	// Accept either GITHUB_TOKEN or GH_TOKEN (workflow may set GH_TOKEN in env)
	// const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
	const token = process.env.GITHUB_TOKEN;
	if (!token) {
		console.error("GITHUB_TOKEN not available; cannot delete workflow run.");
		process.exitCode = 1;
	} else {
		try {
			const repo = process.env.GITHUB_REPOSITORY || "";
			const [owner, repoName] = repo.split("/");
			if (!owner || !repoName) throw new Error("GITHUB_REPOSITORY is not set or invalid");
			const octokit = github.getOctokit(token);
			console.log(`Deleting workflow run ${runId} in ${owner}/${repoName}...`);
			// deleteWorkflowRun requires owner, repo, run_id (number)
			await octokit.rest.actions.deleteWorkflowRun({ owner, repo: repoName, run_id: Number(runId) });
			console.log("Workflow run deleted successfully.");
			// write an env-style output file the composite action can read
			try {
				const workspace = process.env.GITHUB_WORKSPACE || process.cwd();
				const outPath = join(workspace, '.github/actions/javascript/with-post-step/action_output.env');
				writeFileSync(outPath, `run_deleted=true\nrun_id=${runId}\n`, { encoding: 'utf8' });
			} catch (err) {
				console.error('Failed to write action output file:', err);
			}
		} catch (err) {
			console.error("Failed to delete workflow run:", err);
			process.exitCode = 1;
		}
	}
} else {
	console.log("No run id or INPOST flag; skipping workflow run deletion.");
	// still write output file so the composite action knows nothing was deleted
	try {
			const workspace = process.env.GITHUB_WORKSPACE || process.cwd();
			const outPath = join(workspace, '.github/actions/javascript/with-post-step/action_output.env');
		writeFileSync(outPath, `run_deleted=false\nrun_id=\n`, { encoding: 'utf8' });
	} catch (err) {
		console.error('Failed to write action output file:', err);
	}
}
