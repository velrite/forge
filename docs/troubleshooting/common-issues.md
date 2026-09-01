# Forge Troubleshooting Log

Real issues hit during the build, root cause, and the actual fix.
Kept as a reference, not a hypothetical FAQ.

## "Connection to Cloud Shell was lost" / commands seem to vanish
Cause: Cloud Shell session reset. Exported variables, active gcloud
account, and sometimes kubectl context are lost - files in $HOME
persist, active session state does not.
Fix: re-run the Session Startup Checklist in runbook.md.

## Interactive prompt eats the rest of a pasted block
Cause: a command (gpg keyring overwrite, corepack download confirm,
yarn version prompt) opened a y/N prompt mid-paste; remaining pasted
lines got consumed as answers to it instead of running as commands.
Fix: never paste a block that can trigger a prompt. Set
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 permanently; check for stray
partial-command files afterward (`ls` for anything with spaces in an
odd filename).

## Terminal/tab closes entirely mid-script
Cause: a bare `exit 1` inside a safety check, pasted directly into an
interactive shell (not a script file) - exit kills the whole session.
Fix: always wrap safety-check blocks in `( ... )` subshells. exit
inside parens only exits that block.

## kubectl pointed at the wrong cluster entirely
Cause: gcloud project context and kubectl cluster context are two
separate pieces of state. Verifying one does not verify the other.
Fix: always check both explicitly before any cluster-mutating command
(see runbook.md's safety guard pattern). See ADR-009 for the full
incident.

## Yarn: "This package doesn't seem to be present in your lockfile"
Two distinct causes hit during this build:
1. First install ever, with only create-app's lockfile "seed" (not a
   real resolved lockfile) - --immutable is wrong for a first install.
2. Even after removing --immutable: Yarn auto-re-enables immutable
   mode whenever a CI env var is present (Cloud Build sets CI=true by
   default), regardless of the flag passed. Fix: explicitly set
   YARN_ENABLE_IMMUTABLE_INSTALLS=false as a build-step env var.

## npm package shows as "quarantined" during yarn install
Cause: npm's automated post-publish malware-scan quarantine window on
a very recently published package, pulled in via a floating @latest
version of a scaffolding tool.
Fix: do NOT bypass the quarantine. Verify the package via `npm view
<pkg>` (live registry, not search-engine cache) before deciding
anything. Pin scaffolding tools to specific, already-vetted versions
instead of @latest going forward (ADR-008).

## docker build fails: "--mount option requires BuildKit"
Cause: Dockerfile uses BuildKit-only cache-mount syntax; Cloud Build's
docker step doesn't enable BuildKit by default.
Fix: set env DOCKER_BUILDKIT=1 on that specific build step.

## docker push fails: "cannot update tag latest. Tag immutability"
Cause: Artifact Registry has immutable_tags enabled (ADR-004, a real
security control) - pushing to a floating :latest tag a second time
will always fail once the tag already exists.
Fix: tag every build uniquely (timestamp or commit SHA), never
:latest. Deploy via `kubectl set image` referencing the exact tag, not
a rollout restart against a static tag reference. See ADR-011.

## curl to Backstage's /api/catalog/* returns AuthenticationError
Not a bug. Backstage's backend requires a service-to-service token
for API calls by default, even with guest UI auth configured. Use the
browser (Web Preview) for UI-facing verification instead of scripting
around backend auth for one-off checks.
