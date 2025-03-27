---
layout: default
title: Contributing
nav_order: 9
---

# Contributing

_ViewComponent is intended to be a safe, welcoming space for collaboration. By participating you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md)._

Hi there! We're thrilled that you'd like to contribute to ViewComponent. Your help is essential for keeping it great.

If you have any substantial changes that you would like to make, please [open an issue](http://github.com/viewcomponent/view_component/issues/new) first to discuss them with us.

Maintainers tend to focus on areas of the project that are useful to them and their employers, but we're happy to pair with members of the community to enable work on other parts.

Contributions to this project are [released](https://help.github.com/articles/github-terms-of-service/#6-contributions-under-repository-license) to the public under the [MIT license](https://github.com/viewcomponent/view_component/blob/main/LICENSE.txt).

## Reporting bugs

When opening an issue to describe a bug, it's helpful to provide steps to reproduce it, either with failing tests in a pull request, or by sharing a repository that demonstrates the issue.

### Creating a Rails application to demonstrate a ViewComponent bug

1. Run `rails new --minimal view_component-bug-replica` in the console.
2. Run `bundle add view_component` in the console. If testing against a previous version of ViewComponent, update the `Gemfile` to that version and run `bundle install`.
3. Run `rails generate controller Home index`.
4. Add `root to: 'home#index'`.
5. Add as little code as possible that's necessary to reproduce the issue. If possible, use the original code that caused the issue in the application.
6. Publish the repository and add a link to the bug report issue.

### GitHub Codespaces

This repository includes configuration for GitHub Codespaces, making it easy to set up a cloud-based development environment. Follow [GitHub's guide](https://docs.github.com/en/codespaces/developing-in-codespaces/creating-a-codespace#creating-a-codespace) to get started.

The codespace environment includes a minimal Rails app with ViewComponent installed in the `replicate-bug` directory. To run the application:

1. Start the Rails server from the codespace's terminal with `rails s`.
2. Expose the port when prompted by the Visual Studio Code Web Editor.
3. Add the external URL to the config block in `config/application.rb` as prompted by the error.

## Submitting a pull request

1. [Fork](https://github.com/viewcomponent/view_component/fork) and clone the repository.
1. Configure and install the dependencies: `bundle exec appraisal install`.
2. Make sure the tests pass: `bundle exec appraisal rake` (see below for specific cases).
3. Create a new branch: `git checkout -b my-branch-name`.
4. Add tests, make the change, and make sure the tests still pass.
5. Add an entry to the top of `docs/CHANGELOG.md` for the changes, no matter how small.
6. If it's your first time contributing, add yourself to `docs/index.md`.
7. Push to the fork and [submit a pull request](https://github.com/viewcomponent/view_component/compare).
8. Wait for the pull request to be reviewed and merged.

### Running a subset of tests

Use [`m`](https://rubygems.org/gems/m):

```command
bundle exec m test/view_component/YOUR_COMPONENT_test.rb:line_number
```

### Running tests for a specific version of Rails

Specify one of the supported versions listed in [Appraisals](https://github.com/viewcomponent/view_component/blob/main/Appraisals):

```command
bundle exec appraisal rails-5.2 rake
```

## Documentation

### Previewing changes locally

1. Navigate to `/docs`.
1. Configure and install the dependencies: `bundle`.
1. Run Jekyll: `bundle exec jekyll serve`.
1. Open the docs site at `http://127.0.0.1:4000/`.

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

`./script/release`

## Governance

ViewComponent is built by over a hundred members of the community. Project membership has several levels:

### Triage

ViewComponent triagers are able to manage issues and pull request by assigning owners and labels, closing issues and marking duplicates.

After helping with the project by participating in issues, pull requests, and/or discussions, members of the community are welcome to request triage access by opening a pull request to update this list:

The triagers team is @reeganviljoen.

### Commit

ViewComponent committers have `write` access, enabling them to push directly to the repository and merge pull requests, thus removing the need to contribute via a fork.

Triagers are welcome to request commit access by opening a pull request to update this list:

There are currently no committers.

### Maintain

ViewComponent maintainers have `admin` access, enabling them to manage repository settings including access levels. They also have ownership of `view_component` on RubyGems. Maintainers are required to have 2FA enabled for their GitHub and RubyGems accounts.

Committers are welcome to request maintainership access by opening a pull request to update this list:

The maintainers team is @boardfish, @spone, @camertron, @blakewilliams, and @joelhawksley.
