require "thor"
require "yaml"
require "pathname"

module PullRequestTemplates
  class Cli < Thor
    # Set exit_on_failure to ensure Thor exits with non-zero status on errors
    def self.exit_on_failure? = true

    desc "pr-url", "Generate a pull request URL based on changes"
    def pr_url
      # Find all available templates
      templates = get_available_templates

      if templates.empty?
        raise Thor::Error, "No templates found"
      end

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

      # Select appropriate template
      template = select_template(templates, changes)

      # Generate the pull request URL
      url = generate_pr_url(current_branch, template)
      say url
    end

    private

    def get_available_templates
      template_dir = ".github/PULL_REQUEST_TEMPLATE"
      Dir.glob("#{template_dir}/*.md").map { |path| File.basename(path) }
    end

    def get_changes
      # Get changes between current branch and main branch
      # Returns an array of changed file paths or an empty array if no changes
      changes = `git diff --name-only main...HEAD`.strip
      changes.split("\n").reject(&:empty?)
    end

    def select_template(templates, changes)
      mapping_file = ".github/PULL_REQUEST_TEMPLATE/.mapping.yml"
      candidates = []
      if File.exist?(mapping_file)
        mapping = YAML.load_file(mapping_file)
        matches = Hash.new { |h, k| h[k] = [] }
        changes.each do |file|
          mapping.each do |template, patterns|
            Array(patterns).each do |pattern|
              matches[template] << file if File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
            end
          end
        end
        selected = matches.select { |_, files| files.sort == changes.sort }
        candidates = selected.keys if selected.any?
      end
      candidates = templates if candidates.empty?
      if candidates.length == 1
        return candidates.first
      end
      raise AmbiguousTemplateSelection, <<~MESSAGE
        Unable to pick one template from #{candidates} for the changes to #{changes.count} files:
        * #{changes.join("\n* ")}
      MESSAGE
    end

    def generate_pr_url(branch, template)
      # Get the repository URL from git config
      remote_url = `git config --get remote.origin.url`.strip

      # Extract repository path from SSH URL format (git@github.com:user/repo.git)
      repo_path = remote_url.sub(/^git@github\.com:/, "").sub(/\.git$/, "")

      # Generate GitHub pull request URL with template parameter
      "https://github.com/#{repo_path}/compare/#{branch}?expand=1&quick_pull=1&template=#{template}"
    end
  end
end
