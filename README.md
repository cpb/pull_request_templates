# PullRequestTemplates

`pull_request_templates` keeps you in flow by eliminating the toil in providing the right context for changes in pull request descriptions.

PullRequestTemplates helps teams by:
- [x] Matching code changes to the right template automatically
- [x] Generating template-specific GitHub URLs for new PRs
- [ ] Installing git hooks to override default PR URL generation
- [ ] Validating that templates have clear, non-overlapping file patterns
- [ ] Checking PRs use the correct template based on changed files
- [ ] Suggesting better template options when needed

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

## Configuration

To support multiple templates and automatically select the right one based on changed files, add a `config.yml` file to your template directory:

```yaml
# .github/PULL_REQUEST_TEMPLATE/config.yml
templates:
  - file: feature.md
    pattern: "**/feature*.txt"
  - file: bug_fix.md
    pattern: "**/fix*.txt"
```

- `pull_request_templates` will select the first template whose patterns match any changed files.

## Usage

> **Note:** This is pre-release software. `config.yml` format expected to change frequently

### Setting Up Templates

Place your PR templates in the `.github/PULL_REQUEST_TEMPLATE/` directory. For example:

```
.github/
└── PULL_REQUEST_TEMPLATE/
    ├── feature.md
    ├── bug_fix.md
    └── config.yml
```

The `config.yml` file should define which templates apply to which files:

```yaml
# .github/PULL_REQUEST_TEMPLATE/config.yml
templates:
  - file: feature.md
    pattern: "**/feature*.txt"
  - file: bug_fix.md
    pattern: "**/fix*.txt"
```

### Creating a Pull Request

When you're ready to create a pull request:

```bash
pull_request_templates pr-url
```

This command:
- Selects an appropriate template based on your changes
- Generates a GitHub PR URL with the template parameter
- Outputs the URL to your terminal

Open the URL in your browser to create a pull request with the template pre-applied.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cpb/pull_request_templates. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cpb/pull_request_templates/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PullRequestTemplates project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cpb/pull_request_templates/blob/main/CODE_OF_CONDUCT.md).
