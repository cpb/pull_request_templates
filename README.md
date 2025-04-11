# PullRequestTemplates

A tool that reduces PR description toil and provides the right context for changes.

PullRequestTemplates helps teams by:
- Matching code changes to the right template automatically
- Generating template-specific GitHub URLs for new PRs
- Installing git hooks to override default PR URL generation
- Validating that templates have clear, non-overlapping file patterns
- Checking PRs use the correct template based on changed files
- Suggesting better template options when needed

Works seamlessly both in local development and GitHub Actions workflows.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add pull_request_templates
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install pull_request_templates
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cpb/pull_request_templates. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cpb/pull_request_templates/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PullRequestTemplates project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cpb/pull_request_templates/blob/main/CODE_OF_CONDUCT.md).
