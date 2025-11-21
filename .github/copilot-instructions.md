<!-- Brief, focused guidance for AI coding agents working on EddictwareELEC -->
# Copilot instructions — EddictwareELEC

This file gives focused, actionable guidance for AI coding agents (Copilot-style assistants) so they can be productive in this repository immediately.

1. Big picture
   - EddictwareELEC is a fork/variant of LibreELEC that builds a minimal Linux image (Kodi-focused) with Entware pre-installed. The build system is shell-based (scripts/*) and mirrors LibreELEC.tv structure.
   - Key build entrypoints: `Makefile` (targets: `all|release|image|noobs|clean|distclean`) and `scripts/image` which orchestrates multi-stage builds and calls `scripts/mkimage`.
   - Packages live under `packages/` and follow the LibreELEC `package.mk` conventions (see `packages/readme.md`). Projects and device overlays are in `projects/`.

2. Where to look first (files that explain conventions/workflow)
   - `README.md` — project purpose, Entware note and Docker build recommendation.
   - `Makefile` — top-level task names that map to scripts in `scripts/`.
   - `scripts/image` — full image creation flow, environment variables, and release packaging (important for modifications to image composition).
   - `config/options` and `config/path` — build-time variables, toolchain selection, concurrency and cc/ccache rules. Respect these (the build aborts if run as root or with spaces in path).
   - `packages/readme.md` — package.mk format, late-binding variables, toolchain detection and PKG_BUILD_FLAGS. Use this to author or modify packages.

3. Important patterns and conventions (do not break these)
   - Do not run builds as root; build scripts explicitly exit if EUID==0 (see `config/options`).
   - Avoid spaces in paths — many scripts will fail when PWD contains spaces.
   - Late-binding: many variables (PKG_BUILD, toolchain flags, TARGET_* variables) are only set during `scripts/build`/`config/options`; reference them inside `configure_package()` or stage-specific functions (e.g. `pre_make_target`). See `packages/readme.md` "Late Binding variable assignment".
   - Toolchain auto-detection: meson/CMake/configure/Makefile presence controls PKG_TOOLCHAIN unless explicitly set in `package.mk`.
   - Package functions: prefer using pre_/post_ hooks rather than completely replacing core functions to remain compatible with upstream LibreELEC updates.

4. Build / debug / test commands (concrete examples)
   - Build default image locally (recommended inside LibreELEC Docker):
     - From repo root: `make` (maps to `Makefile` -> `./scripts/image`).
     - For a release image: `make release` or `./scripts/image release`.
   - Create only image: `make image` or `./scripts/image mkimage`.
   - Clean build artifacts: `make clean` or `./scripts/makefile_helper --clean`; full distclean: `make distclean`.
   - Package validation: `tools/pkgcheck` (see `packages/readme.md`) to detect late-binding and other package issues.
   - Common helper scripts: `scripts/get`, `scripts/get_git`, `scripts/build`, `scripts/mkimage` — inspect before automating changes to the build flow.

5. Cross-component communication & integration points
   - Packages communicate via install dirs and package stamps. When a package needs files from another package, use the target package's install directory (not its build dir).
   - The build orchestrator sets many TARGET_*/HOST_* variables after `setup_toolchain` — do not assume these exist globally in package top-level code.
   - RELEASE packaging is done in `scripts/image` and `scripts/mkimage` — changes that affect release layout should update those scripts.

6. Coding agent behavior rules (how to make safe, repo-aligned edits)
   - Small, isolated changes: prefer modifying a package's `package.mk` or adding `pre_/post_` hooks instead of rewriting core scripts.
   - Preserve shell style and exit-on-error semantics; be conservative with `set -e` and error messages.
   - When adding or modifying build steps, update `packages/readme.md` or related docs with the minimal example demonstrating the change.
   - Respect copyright and SPDX headers in new/modified scripts (repo uses GPL-2.0(-or-later) headers in many scripts).

7. Examples from this repo
   - To add Entware setup at image build time, look at how `projects/Generic/filesystem` or `projects/*/filesystem` overlays are copied in `scripts/image` and how systemd services are enabled.
   - `config/options` enforces non-root, no-space, and concurrency defaults — any CI or helper must follow these constraints.

8. When to ask for human review
   - Anything that changes release artifact naming, packaging layout, or toolchain choices.
   - Changes that add root-required steps or alter the expectation that builds run as an unprivileged user.

If anything above is unclear or you'd like more examples (e.g., a sample `package.mk` change or a small CI workflow snippet), tell me which area to expand and I'll iterate.
