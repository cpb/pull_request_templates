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

        # Find the appropriate template
        template = select_template(changes)

        # Generate the pull request URL
        url = generate_pr_url(current_branch, template)
        say url
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

    def select_template(changes)
      # For simplicity, just use the feature template for now
      # In a more advanced implementation, we could analyze the changes
      # and select the most appropriate template
      "feature.md"
    end

    def generate_pr_url(branch, template)
      # Get the repository URL from git config
      remote_url = `git config --get remote.origin.url`.strip

      # Clean up the URL to get the GitHub repository path
      # Handle both HTTPS and SSH formats
      repo_path = if remote_url.include?("github.com")
        if remote_url.start_with?("git@")
          # SSH format: git@github.com:user/repo.git
          remote_url.sub(/^git@github\.com:/, "").sub(/\.git$/, "")
        else
          # HTTPS format: https://github.com/user/repo.git
          remote_url.sub(/^https:\/\/github\.com\//, "").sub(/\.git$/, "")
        end
      else
        # Default to the remote URL without .git
        remote_url.sub(/\.git$/, "")
      end

      # Generate GitHub pull request URL with template parameter
      "https://github.com/#{repo_path}/pull/new/#{branch}?template=#{template}"
    end
  end
end
