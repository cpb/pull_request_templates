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

    def select_template(template_files, changes)
      mapping_file = ".github/PULL_REQUEST_TEMPLATE/config.yml"
      if File.exist?(mapping_file)
        templates = YAML.load_file(mapping_file).fetch("templates")
        templates.each do |template|
          changes.each do |file|
            patterns = template.fetch("pattern")
            Array(patterns).each do |pattern|
              return template.fetch("file") if File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::Constants::FNM_DOTMATCH)
            end
          end
        end
        # No matching template found
        say_error "No template matches the changed files. Add a catch-all pattern (e.g. '**/*') to your config.yml to always use a template."
        nil
      else
        # Multiple templates but no config
        if template_files.length > 1
          say_error "Multiple templates found but no config.yml to select between them. Add a config.yml file to specify which template to use for which files."
        end
        template_files.first
      end
    end

    def generate_pr_url(branch, template)
      # Get the repository URL from git config
      remote_url = `git config --get remote.origin.url`.strip

      # Extract repository path from SSH URL format (git@github.com:user/repo.git)
      repo_path = remote_url.sub(/^git@github\.com:/, "").sub(/\.git$/, "").sub(/^https:\/\/github\.com\//, "")

      # Generate GitHub pull request URL with optional template parameter
      url = "https://github.com/#{repo_path}/compare/#{branch}?expand=1&quick_pull=1"
      url += "&template=#{template}" if template
      url
    end
  end
end
