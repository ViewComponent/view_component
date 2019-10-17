## Contributing

[fork]: https://github.com/github/actionview-component/fork
[pr]: https://github.com/github/actionview-component/compare
[style]: https://github.com/styleguide/ruby
[code-of-conduct]: CODE_OF_CONDUCT.md

Hi there! We're thrilled that you'd like to contribute to this project. Your help is essential for keeping it great.

Contributions to this project are [released](https://help.github.com/articles/github-terms-of-service/#6-contributions-under-repository-license) to the public under the [project's open source license](LICENSE.txt).

Please note that this project is released with a [Contributor Code of Conduct][code-of-conduct]. By participating in this project you agree to abide by its terms.

## Submitting a pull request

0. [Fork][fork] and clone the repository
0. Configure and install the dependencies: `bundle`
0. Make sure the tests pass on your machine: `rake`
0. Create a new branch: `git checkout -b my-branch-name`
0. Make your change, add tests, and make sure the tests still pass
0. Push to your fork and [submit a pull request][pr]
0. Pat your self on the back and wait for your pull request to be reviewed and merged.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Write tests.
- Keep your change as focused as possible. If there are multiple changes you would like to make that are not dependent upon each other, consider submitting them as separate pull requests.
- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

## Releasing

If you are the current maintainer of this gem:

1. Create a branch for the release: `git checkout -b release-vxx.xx.xx`
1. Bump gem version in `lib/action_view/component/version.rb`.
1. Add version heading/entries to `CHANGELOG.md`.
1. Make sure your local dependencies are up to date: `bundle`
1. Ensure that tests are green: `bundle exec rake`
1. Build a test gem `GEM_VERSION=$(git describe --tags 2>/dev/null | sed 's/-/./g' | sed 's/v//') gem build actionview-component.gemspec`
1. Test the test gem:
   1. Bump the Gemfile and Gemfile.lock versions for an app which relies on this gem
   1. Install the new gem locally
   1. Test behavior locally, branch deploy, whatever needs to happen
1. Make a PR to github/actionview-component.
1. Build a local gem: `gem build actionview-component.gemspec`
1. Merge github/actionview-component PR
1. Tag and push: `git tag vx.xx.xx; git push --tags`
1. Create a GitHub release with the pushed tag (https://github.com/github/actionview-component/releases/new) and populate it with a list of the commits from `git log --pretty=format:"- %s" --reverse refs/tags/[OLD TAG]...refs/tags/[NEW TAG]`
1. Push to rubygems.org -- `gem push actionview-component-VERSION.gem`

## Resources

- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [Using Pull Requests](https://help.github.com/articles/about-pull-requests/)
- [GitHub Help](https://help.github.com)
