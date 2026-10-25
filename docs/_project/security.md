---
title: Security
description: How to report a security vulnerability in Ransack, and how maintainers handle a report from triage to disclosure.
nav_order: 5
---

## Reporting a vulnerability

Report security problems privately. **Don't open a public issue, pull request
or discussion,** and don't mention the problem anywhere public until a fixed
version has been released.

Use **one** of these channels:

* **GitHub private vulnerability reporting.** On the repository's Security tab, click
  [Report a vulnerability](https://github.com/activerecord-hackery/ransack/security/advisories/new).
  Only the maintainers can see the report, and you can follow and discuss it there.
* **Tidelift.** Use the [Tidelift security contact](https://tidelift.com/security).
  Tidelift forwards the report to the maintainers and helps coordinate the fix and
  disclosure.

Please report through one channel only. If you file the same report in both, we
get duplicates that have to be merged later.

A good report includes:

* the Ransack, Rails and Ruby versions you tested
* the code or request that triggers the problem, ideally as a minimal app or a
  failing spec
* what an attacker gains, and what they need: an account, a particular configuration,
  or an action by the victim
* a fix, if you have one

We aim to acknowledge a report within a few days. We'll keep you informed until
the fix is released, and we credit you in the published advisory unless you'd rather
not be named.

## Supported versions

Security fixes are released for the latest `major.minor` release line. When a fix
applies cleanly, maintainers may also backport it to earlier lines. For example,
GHSA-j3f8-w227-4hh8 shipped as 4.4.3, 5.0.2 and 6.0.0.

## Handling a report

*For the maintainers of Ransack.*

Every step until the release happens in private. Until the advisory is published,
don't push the fix to `activerecord-hackery/ransack`, open a public pull request,
or describe the problem in a public commit, issue or release note.

### 1. Triage

1. **Find every copy of the report.** A report can arrive as a GitHub advisory in
   the *Triage* state or as an email from Tidelift, and the same bug is sometimes
   reported more than once. List the open advisories before you do anything else:

   ```bash
   gh api repos/activerecord-hackery/ransack/security-advisories \
     --jq '.[] | [.ghsa_id, .state, .created_at, .summary] | @tsv'
   ```

2. **Reproduce it locally** on `main` and on each supported release line, as a
   failing spec on a local branch. Don't push it anywhere.

3. **Decide.** If the report is not a vulnerability, close the advisory with an
   explanation, or reply to Tidelift. If Tidelift is coordinating, tell them whether
   you accept the report.

### 2. One advisory per fix

Bugs with the same root cause and the same fix get **one** advisory, and therefore
one CVE.

* Accept the earliest report. Accepting moves it from *Triage* to *Draft*.
* Add everyone who reported the bug as a *Reporter* credit.
* Close the other reports as duplicates, with a comment that names the advisory you
  kept.

Then complete the draft:

| Field | Value |
| --- | --- |
| Title | What breaks and how, in one line |
| Description | Sections for **Impact**, **Patches**, **Workarounds** and **References** |
| Affected versions | One range per release line, e.g. `< 1.4.2` and `>= 2.0.0, < 2.0.3` |
| Patched versions | The release that fixes each range |
| Severity | The CVSS 3.1 vector, which sets the score |
| Weaknesses | The CWE(s) |

Request a CVE from the draft (*Request CVE*). GitHub reviews the request when you
publish the advisory.

### 3. Fix it in the temporary private fork

Each draft advisory can have one **temporary private fork**, a private copy of
the repository that only the advisory's collaborators can see. To create it, click
*Start a temporary private fork* at the bottom of the advisory. A reporter may
already have created one and opened a pull request, so check first.

```bash
gh api repos/activerecord-hackery/ransack/security-advisories/GHSA-xxxx-xxxx-xxxx \
  --jq '.private_fork.full_name'
```

Push the fix to a branch of the fork, and open a pull request against the fork's
`main`. Note the fork's limits:

* **Only one pull request into `main` can be merged.** If two are open, merging is
  blocked. When a reporter has already opened one, review it, push changes to it,
  or close it before you open your own.
* **CI doesn't run** in the fork. Before merging, run the whole suite locally against
  every database (SQLite, PostgreSQL, MySQL) and every supported Rails version. See
  the [Contributing Guide](https://github.com/activerecord-hackery/ransack/blob/main/CONTRIBUTING.md).
* **`main`'s required status checks can't pass,** because CI doesn't run. Merging
  needs an admin to tick *Merge and bypass branch protections*, so get the review
  you would normally require first.
* **Ignore *Compare & pull request*** when GitHub offers it for a backport branch.
  That pull request would target the fork's `main` and block the merge.

The pull request puts the fix on `main` for the next minor release. **Patch
releases never come from `main`,** because `main` usually holds unreleased features
and compatibility changes. For every release line you're fixing, the current one
included, cherry-pick the fix with `git cherry-pick -x` onto that line's stable
branch. If the current line has no stable branch yet, start one from its latest
tag, e.g. `git switch -c 6-0-stable v6.0.0`. Run that line's suite against each
Rails version it supports. Push each backport to the fork for review as a
`backport-x-y-stable` branch, without opening a pull request. Step 4 releases them
from the stable branches.

### 4. Release and disclose

Agree on a release date with the reporters, and with Tidelift if it's coordinating.
On that day, follow these steps in order:

1. **Merge the fix.** On the advisory, tick *Merge and bypass branch protections*
   and click *Merge pull request*. The fork's pull request lands on `main`.
2. **Release each line.** Follow [Versions and releases](../_project/release_process.md):
   For each line, push the backport and a `Version x.y.z` commit to its
   `x-y-stable` branch, then create a GitHub Release targeting that branch.
   *Set as the latest release* is checked only for the current line's release.

   Start each release's notes with "Security release.", followed by a one-paragraph
   description of the problem, the GHSA identifier and the other versions that
   contain the fix.
3. **Check the gems are live** on [RubyGems](https://rubygems.org/gems/ransack/versions).
4. **Publish the advisory.** It becomes public, the CVE is assigned, and Dependabot
   starts alerting affected apps.
5. **Close the loop.** Tell the reporters and Tidelift that the advisory is public.
