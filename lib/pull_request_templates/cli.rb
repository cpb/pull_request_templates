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

        # Check if there are any changes to detect
        changes = get_changes

        if changes.empty?
          raise Thor::Error, "No changes detected"
        end

        # Future implementation: generate URL based on changes
      else
        raise Thor::Error, "No templates found"
      end
    end

    private

    def get_changes
      # Get changes between current branch and main branch
      # Returns an array of changed file paths or an empty array if no changes
      changes = `git diff --name-only main...HEAD`.strip
      changes.split("\n").reject(&:empty?)
    end
  end
end
