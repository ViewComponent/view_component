# Repository instructions

- After changing dependencies in `Gemfile`, regenerate the appraisal Gemfiles with `bundle exec appraisal generate`, then update every appraisal lockfile with `bundle exec appraisal-run gemfiles/*.gemfile -- bundle lock`.
