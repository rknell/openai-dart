# Security Policy

## Supported Versions

This project is pre-1.0 and evolves quickly. Security fixes are applied to the latest commit on the default branch.

## Reporting a Vulnerability

Please do not open public issues for suspected vulnerabilities.

Instead, report privately to the maintainers with:

- A clear description of the issue
- Reproduction steps / proof of concept
- Impact assessment
- Suggested remediation (if known)

If a private security contact is not yet configured for this repository, open a minimal issue requesting a private reporting channel and avoid sharing exploit details publicly.

## Secrets and Credentials

- Never commit real API keys.
- Use `.env` locally; `.env` is gitignored.
- Use `.env.example` as a template.
- Rotate any key immediately if it is exposed.
- Pre-commit scanning with `gitleaks` is configured via `.pre-commit-config.yaml`.

## Scope Notes

This is a client SDK and does not control server-side model behavior, billing, account security, or provider infrastructure.

## Safe Defaults in This Repo

- Typed HTTP/API error handling
- Retry with bounded attempts and exponential backoff
- Integration tests skip when credentials are unavailable/invalid
- Static analysis and unit/integration tests are part of validation
