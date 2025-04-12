require "thor"

module PullRequestTemplates
  class Cli < Thor
    # Set exit_on_failure to ensure Thor exits with non-zero status on errors
    def self.exit_on_failure? = true

    desc "pr-url", "Generate a pull request URL based on changes"
    def pr_url
      # Check if templates are configured
      if Dir.exist?(".github/PULL_REQUEST_TEMPLATE")
        # Check if we're on the default branch
        current_branch = `git rev-parse --abbrev-ref HEAD`.strip

        if current_branch == "main"
          raise Thor::Error, "Cannot generate PR URL while on default branch"
        end
      else
        raise Thor::Error, "No templates found"
      end
    end
  end
end
