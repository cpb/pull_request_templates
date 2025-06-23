require "thor"
require "yaml"
require "pathname"
require "tempfile"

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
      mapping_file = "#{template_dir}/config.yml"
      
      templates = []
      
      # Add file-based templates
      Dir.glob("#{template_dir}/*.md").each do |path|
        templates << { type: :file, name: File.basename(path), path: path }
      end
      
      # Add inline templates from config.yml
      if File.exist?(mapping_file)
        config = YAML.load_file(mapping_file)
        config_templates = config.fetch("templates", [])
        
        config_templates.each do |template_config|
          if template_config.key?("name") && template_config.key?("body")
            # Generate a filename from the name for inline templates
            filename = template_config["name"].downcase.gsub(/\s+/, "_") + ".md"
            templates << { 
              type: :inline, 
              name: filename, 
              config: template_config,
              pattern: template_config["pattern"]
            }
          elsif template_config.key?("file")
            # This is a file-based template reference
            templates << { 
              type: :file, 
              name: template_config["file"], 
              path: "#{template_dir}/#{template_config['file']}",
              pattern: template_config["pattern"]
            }
          end
        end
      end
      
      templates
    end

    def get_changes
      # Get changes between current branch and main branch
      # Returns an array of changed file paths or an empty array if no changes
      changes = `git diff --name-only main...HEAD`.strip
      changes.split("\n").reject(&:empty?)
    end

    def select_template(templates, changes)
      # First, try to find templates with patterns that match the changes
      templates_with_patterns = templates.select { |t| t[:pattern] }
      
      if templates_with_patterns.any?
        templates_with_patterns.each do |template|
          changes.each do |file|
            patterns = Array(template[:pattern])
            patterns.each do |pattern|
              if File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::Constants::FNM_DOTMATCH)
                return get_template_filename(template)
              end
            end
          end
        end
        
        # No matching template found
        say_error "No template matches the changed files. Add a catch-all pattern (e.g. '**/*') to your config.yml to always use a template."
        return nil
      else
        # No config.yml or no patterns defined
        if templates.length > 1
          say_error "Multiple templates found but no config.yml to select between them. Add a config.yml file to specify which template to use for which files."
        end
        get_template_filename(templates.first)
      end
    end

    def get_template_filename(template)
      case template[:type]
      when :file
        template[:name]
      when :inline
        # For inline templates, we need to create a temporary file
        create_inline_template_file(template)
      end
    end

    def create_inline_template_file(template)
      # Create a temporary file for the inline template
      temp_file = Tempfile.new([template[:name], '.md'])
      temp_file.write(template[:config]["body"])
      temp_file.close
      
      # Store the temp file path so it can be cleaned up later
      @temp_files ||= []
      @temp_files << temp_file.path
      
      template[:name]
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
