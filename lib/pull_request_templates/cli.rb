require "thor"

module PullRequestTemplates
  class Cli < Thor
    desc "pr-url", "Generate a pull request URL based on changes"
    def pr_url
      # Command scaffolding without implementation
      say "PR URL command called"
    end
  end
end
