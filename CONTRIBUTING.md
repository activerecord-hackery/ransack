# Contributing to Ransack

Please take a moment to review this document to make contributing easy and
effective for everyone involved!

Ransack is an open source project and we encourage contributions.

## Filing an issue

Good issue reports are extremely helpful!  Please only open an issue if a bug
is caused by Ransack, is new (has not already been reported), and can be
reproduced from the information you provide.

Please do not use the issue tracker personal support requests. Stack Overflow
is a better place for that where a wider community can help you.

Steps:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   `master` branch in the repository.

3. **Isolate and report the problem** &mdash; ideally create a reduced test
   case.

When filing an issue, please provide these details:

* A comprehensive list of steps to reproduce the issue :smiley: or even better, a failing spec!
* The versions of Ruby, Rails, Ransack and your operating system and database.
* Any relevant stack traces ("Full trace" preferred).

Any issue that is open for 14 days without actionable information or activity
will be marked as "stalled" and then closed. Stalled issues can be re-opened
if actionable information to reproduce the issue is provided.

## Pull requests

We gladly accept pull requests to fix bugs and, in some circumstances, add new
features to Ransack. If you'd like to contribute and wonder what would be
helpful, simply run a search for "FIXME" and "TODO" on the codebase :smiley:

If you're new to contributing to open source, welcome! It can seem scary, so
here is a [great blog post to help you get started]
(http://robots.thoughtbot.com/8-new-steps-for-fixing-other-peoples-code),
step by step.

Before issuing a pull request, please make sure that all specs are passing,
that any new features have test coverage, and that anything that breaks
backward compatibility has a very good reason for doing so.

Here's a quick guide:

1. Fork the repo.

2. Create a thoughtfully-named branch for your changes (`git checkout -b my-new-feature`).

3. Install the development dependencies by running `bundle install`.

4. Begin by running the tests. We only take pull requests with passing tests,
   and it's great to know that you have a clean slate:

        $ bundle exec rake spec

   The test suite runs by default with SQLite3. To run the test suite with PostgreSQL or MySQL, use:

        $ DB=postgresql bundle exec rake spec (`DB=pg` & `DB=postgres` work too)
        $ DB=mysql bundle exec rake spec

5. Hack away! Please use Ruby features that are compatible down to Ruby 1.9.
   Since version 1.5, Ransack no longer maintains Ruby 1.8 compatibility.

6. Add tests for your changes. Only refactoring and documentation changes
   require no new tests. If you are adding functionality or fixing a bug, we
   need a test!

7. Make the tests pass.

8. Update the Change Log. If you are adding new functionality, document it in
   the README.

9. Commit your changes (`git commit -am 'Add feature/fix bug/improve docs'`).

10. If necessary, rebase your commits into logical chunks, without errors. To
   interactively rebase and cherry-pick from, say, the last 10 commits:
   `git rebase -i HEAD~10`, then `git push -f`.

11. Push the branch up to your fork on Github
   (`git push origin my-new-feature`) and from Github submit a pull request to
   Ransack's `master` branch.

12. If your pull request only contains documentation changes, please remember
   to add `[skip ci]` to the beginning of your commit message so the Travis
   test suite doesn't :runner: needlessly.

At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within three business days (and, typically, one business
day). We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Include tests that fail without your code, and pass with it.
* Update the README, the change log, the wiki documentation... anything that is
  affected by your contribution.
* Use idiomatic Ruby and follow the syntax conventions below.

Syntax:

* Indent with two spaces, no tabs.
* 80 characters per line.
* No trailing whitespace. Blank lines should not have any space.
* Prefer `&&`/`||` over `and`/`or`.
* `MyClass.my_method(my_arg)` not `my_method( my_arg )` or `my_method my_arg`.
* `a = b` and not `a=b`.
* `a_method { |block| ... }` and not `a_method { | block | ... }` or
`a_method{|block| ...}`.
* Prefer simplicity, readability, and maintainability over terseness.
* Follow the conventions you see used in the code already.

And in case we didn't emphasize it enough: We love tests!
