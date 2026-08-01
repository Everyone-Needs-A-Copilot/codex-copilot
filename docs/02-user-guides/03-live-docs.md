# Live Docs

Live Docs prevents agents from coding against stale third-party APIs.

Before planning or implementing against an installed package API, use:

```bash
cc docs get <package> --topic <area> --json
```

Use this for package APIs, framework hooks, SDK methods, constructors, and configuration shapes. Standard library calls and local project helpers do not need Live Docs unless the local version is unclear.

## Required Specialist Behavior

- `$ta` checks Live Docs before architecture decisions that depend on a third-party API.
- `$me` checks Live Docs before implementation that calls a third-party API.
- `$qa` uses Live Docs when verification depends on package behavior.
- `$do` and `$sec` use Live Docs for third-party CLI, SDK, or security API assumptions when relevant.

## If `cc docs` Is Unavailable

State the limitation and verify through local package files, lockfiles, installed docs, or official documentation. Do not silently rely on remembered API shapes.

## Setup Check

Run:

```bash
cc docs sources
```

The base setup should work offline through local installed package discovery. Network fetch support is optional and depends on the installed `cc` extras.
