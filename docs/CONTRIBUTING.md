---
layout: default
title: Contributing
---

# Contributing

_This project is intended to be a safe, welcoming space for collaboration. By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md)._

Hi there! We're thrilled that you'd like to contribute to this project. Your help is essential for keeping it great.

If you have any substantial changes that you would like to make, please [open an issue](http://github.com/github/view_component/issues/new) first to discuss them with us.

GitHub engineers tend to focus on areas of the project that are useful to GitHub, but we're happy to pair with members of the community to enable work on other parts. Just let us know in an issue.

Contributions to this project are [released](https://help.github.com/articles/github-terms-of-service/#6-contributions-under-repository-license) to the public under the [project's open source license](https://github.com/github/view_component/blob/main/LICENSE.txt).

## Reporting bugs

When opening an issue to describe a bug, it's helpful to provide steps to reproduce it, either with failing tests in a pull request, or by sharing a repository that demonstrates the issue.

### Creating a Rails application to demonstrate a ViewComponent bug

1. Run `rails new --minimal view_component-bug-replica` in the console.
2. Run `bundle add view_component` in the console. If testing against a previous version of ViewComponent, update the `Gemfile` to that version and run `bundle install`.
3. Run `rails generate controller Home index`.
4. Add `root to: 'home#index'`.
5. Add as little code as possible that's necessary to reproduce the issue. If possible, use the original code that caused the issue in your application.
6. Publish the repository and add a link to the bug report issue.

### GitHub Codespaces

This repository includes configuration for GitHub Codespaces, making it easy to set up a cloud-based development environment. Follow [GitHub's guide](https://docs.github.com/en/codespaces/developing-in-codespaces/creating-a-codespace#creating-a-codespace) to get started.

The codespace environment includes a minimal Rails app with ViewComponent installed in the `replicate-bug` directory. To run the application:

1. Start the Rails server from the codespace's terminal with `rails s`.
2. Expose the port when prompted by the Visual Studio Code Web Editor.
3. Add the external URL to the config block in `config/application.rb` as prompted by the error.

## Submitting a pull request

1. [Fork](https://github.com/github/view_component/fork) and clone the repository.
1. Configure and install the dependencies: `bundle exec appraisal install`.
1. Make sure the tests pass on your machine: `bundle exec appraisal rake` (see below for specific cases).
1. Create a new branch: `git checkout -b my-branch-name`.
1. Make your change, add tests, and make sure the tests still pass.
1. Add an entry to the top of `docs/CHANGELOG.md` for your changes, no matter how small they're. We want to recognize your contribution!
2. If it's your first time contributing, add yourself to `docs/index.md`.
3. Push to your fork and [submit a pull request](https://github.com/github/view_component/compare).
4. Pat yourself on the back and wait for your pull request to be reviewed and merged.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Write tests.
- Keep your change as focused as possible. If there are multiple changes you would like to make that aren't dependent upon each other, consider submitting them as separate pull requests.
- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

### Running a subset of tests

Supply a file glob to the test command:

```command
TEST="test/view_component/YOUR_COMPONENT_test.rb" bundle exec appraisal rake
```

### Running tests for a specific version of Rails

Specify one of the supported versions, listed in [Appraisal](https://github.com/github/view_component/blob/main/Appraisals):

```command
bundle exec appraisal rails-5.2 rake
```

## Documentation

### Previewing changes locally

1. Navigate to `/docs`.
1. Configure and install the dependencies: `bundle`.
1. Run Jekyll: `bundle exec jekyll serve`.
1. Open the docs site at `http://127.0.0.1:4000/`.
1. If making changes to the API, run `bundle exec rake docs:build` to generate `docs/api.md` from YARD comments.

### Style guidelines

- Keep it short.
- Avoid unclear antecedents. Use `the method name is too long` instead of `it's too long`.
- Avoid `you`, `we`, `your`, `our`.
- Write in the [active voice](https://writing.wisc.edu/handbook/style/ccs_activevoice/), avoiding the passive voice.
- Refer to methods as `#instance_method` and `.class_method`.
- Use the simplest examples possible.

Don't be afraid to ask for help! We recognize that English isn't the first language of many folks who contribute to ViewComponent.

To run the Vale prose linter locally, `brew install vale` and `vale docs/`.

## Releasing

If you are the current maintainer of this gem:

1. Run `./script/release` and follow the instructions.

## Governance

ViewComponent is built by over a hundred members of the community. Project membership has three levels:

### Triage

ViewComponent triagers are able to manage issues and pull request by assigning owners and labels, closing issues and marking duplicates.

After helping with the project by participating in issues, pull requests, and/or discussions, members of the community are welcome to request triage access by opening a pull request to update this list:

The triagers team is @andrewmcodes, @bbugh, @boardfish, @cesariouy, @dark-panda, @dylnclrk, @g13ydson, @horacio, @jcoyne, @johannesengl, @kaspermeyer, @mellowfish, @metade, @nashby, @rainerborene, @rdavid1099, @spdawson, @yhirano55, and @vinistock.

Committers and maintainers may also nominate triagers by opening a pull request to update this list.

### Commit

ViewComponent committers have `write` access, enabling them to push directly to the repository (and thus not needing to contribute via forks) and approve/merge pull requests. Committers often have implicit ownership over a particular area of the project, such as previews, generators, or translations.

Triagers are invited to become committers by having an existing committer or maintainer open a pull request on the repository to update this list of committers:

The committers team is @elia, @jonspalmer, @juanmanuelramallo, @rmacklin, @spone, @dylanatsmith, and @boardfish.

### Maintain

ViewComponent maintainers have `admin` access, enabling them to manage repository settings including access levels. They also have ownership of `view_component` on RubyGems and are required to have 2FA enabled for their GitHub and RubyGems accounts.

Maintainership is open by invitation only at this time.

The maintainers team is @camertron, @blakewilliams, @joelhawksley, @jonrohan, and @manuelpuyol.
