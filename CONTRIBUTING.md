# Contributing to Ransack

Please take a moment to review this document in order to make the contribution
process easy and effective for everyone involved!

Ransack is an open source project and we encourage contributions.

## Filing an issue

A bug is a _demonstrable problem_ that is caused by the code in the repository.
Good bug reports are extremely helpful! Please do not use the issue tracker for personal support requests.

Guidelines for bug reports:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   `master` branch in the repository.

3. **Isolate and report the problem** &mdash; ideally create a reduced test
   case.

When filing an issue, please provide these details:

* A comprehensive list of steps to reproduce the issue, or - far better - **a failing spec**.
* The version (and branch) of Ransack *and* the versions of Rails, Ruby, and your operating system.
* Any relevant stack traces ("Full trace" preferred).

Any issue that is open for 14 days without actionable information or activity
will be marked as "stalled" and then closed. Stalled issues can be re-opened
if the information requested is provided.

## Pull requests

We gladly accept pull requests to fix bugs and, in some circumstances, add new
features to Ransack.

If you're new to contributing to open source, welcome! It can seem scary, so
here is a [great blog post to help you get started]
(http://robots.thoughtbot.com/8-new-steps-for-fixing-other-peoples-code),
step by step.

Before issuing a pull request, please make sure that all specs are passing,
that any new features have test coverage, and that anything that breaks
backward compatibility has a very good reason for doing so.

Here's a quick guide:

1. Fork the repo, clone it, create a thoughtfully-named branch for your changes,
   and install the development dependencies by running `bundle install`.

2. Begin by running the tests. We only take pull requests with passing tests,
   and it's great to know that you have a clean slate:

        $ bundle exec rake spec

3. Hack away! Please use Ruby features that are compatible down to Ruby 1.9.
   Since version 1.5, Ransack no longer maintains Ruby 1.8 compatibility.

4. Add tests for your changes. Only refactoring and documentation changes
   require no new tests. If you are adding functionality or fixing a bug, we
   need a test!

5. Make the tests pass.

6. Update the Change Log. If you are adding new functionality, document it in
   the README.

7. Do not change the version number; we will do that on our end.

8. If necessary, rebase your commits into logical chunks, without errors.

9. Push the branch up to your fork on Github and submit a pull request. If the
   changes will apply cleanly to the latest stable branches and master branch,
   you will only need to submit one pull request.

10. If your pull request only contains documentation changes, please remember to
   add `[skip ci]` to your commit message so the Travis test suite doesn't run
   needlessly.

At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within three business days (and, typically, one business
day). We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Use idiomatic Ruby and follow the syntax conventions below.
* Include tests that fail without your code, and pass with it.
* Update the README, the change log, the wiki documentation... anything that is
  affected by your contribution.

Syntax:

* Two spaces, no tabs.
* 80 characters per line.
* No trailing whitespace. Blank lines should not have any space.
* Prefer `&&`/`||` over `and`/`or`.
* `MyClass.my_method(my_arg)` not `my_method( my_arg )` or my_method my_arg.
* `a = b` and not `a=b`.
* `a_method { |block| ... }` and not `a_method { | block | ... }` or
`a_method{|block| ...}`.
* Prefer simplicity, readability, and maintainability over terseness.
* Follow the conventions you see used in the code already.

And in case we didn't emphasize it enough: we love tests!
