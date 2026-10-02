# Security

## Supported versions

DBB-HACK ships from `main`. There's no stable/LTS branch yet — use the latest commit.

## Reporting a vulnerability

**Don't open a public Issue.** Use GitHub's private vulnerability report (*Security* tab → *Report a vulnerability*) or email **seguridad@dontbuybuild.cl**.

Include: what you found, how to reproduce it, what it exposes.

| Timeframe | What happens |
|---|---|
| 5 business days | Acknowledgement |
| 15 business days | Severity assessment + decision |
| Depends on severity | Fix + disclosure to affected users |

## Scope note

DBB-HACK is an offensive tool that runs real exploitation **only against an isolated local lab** it mounts itself — it never touches production or third-party systems. A vulnerability report about DBB-HACK's own code (e.g. a way to escape the lab sandbox, or a false "secure" result) is in scope. Misuse of the tool against systems the user doesn't own is not a DBB-HACK security bug — see `CODE_OF_CONDUCT.md`.
