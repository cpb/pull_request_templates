# frozen_string_literal: true

RSpec.describe PullRequestTemplates, type: :aruba do
  it "has a version number" do
    expect(PullRequestTemplates::VERSION).not_to be nil
  end

  # Shared context for common Git setup
  shared_context "git repository setup" do
    before do
      setup_aruba
      run_command_and_stop "git init"
      run_command_and_stop "git branch -m main"  # Rename default branch to main
      run_command_and_stop "git config user.email 'test@example.com'"
      run_command_and_stop "git config user.name 'Test User'"
    end
  end

  # Shared context for common remote setup
  shared_context "git remote setup" do
    before do
      run_command_and_stop "git remote add origin https://github.com/user/repo.git"
    end
  end

  # Shared context for common initial commit
  shared_context "initial commit" do
    before do
      write_file ".gitkeep", ""
      run_command_and_stop "git add .gitkeep"
      run_command_and_stop "git commit -m 'Initial commit'"
    end
  end

  # Shared context for common template directory
  shared_context "template directory" do
    before do
      run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"
    end
  end

  describe "pr-url command" do
    context "with minimal setup (no templates)" do
      include_context "git repository setup"
      include_context "initial commit"

      it "outputs a message about no templates and exits with error" do
        # Run the command
        run_command "pull_request_templates pr-url"

        # Only verify it mentions no templates
        expect(last_command_started).to have_output(/No templates found/)

        # Check it has the expected exit status
        expect(last_command_started).to have_exit_status(1)
      end
    end

    context "with minimal setup (on default branch)" do
      include_context "git repository setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a feature template
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request

          ## Description
          Describe the feature you're adding

          ## Checklist
          - [ ] Tests added
          - [ ] Documentation updated
        MD

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"
      end

      it "outputs a message about being on default branch and exits with error" do
        # Run the command
        run_command "pull_request_templates pr-url"

        # Verify it mentions being on default branch
        expect(last_command_started).to have_output(/Cannot generate PR URL while on default branch/)

        # Check it has a non-zero exit status
        expect(last_command_started).to have_exit_status(1)
      end
    end

    context "with minimal setup (no changes)" do
      include_context "git repository setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a feature template
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request

          ## Description
          Describe the feature you're adding

          ## Checklist
          - [ ] Tests added
          - [ ] Documentation updated
        MD

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch but don't make any changes
        run_command_and_stop "git checkout -b feature-branch"
      end

      it "outputs a message about no changes detected and exits with error" do
        # Run the command
        run_command "pull_request_templates pr-url"

        # Verify it mentions no changes detected
        expect(last_command_started).to have_output(/No changes detected/)

        # Check it has a non-zero exit status
        expect(last_command_started).to have_exit_status(1)
      end
    end

    context "with single template" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a bug_fix template (different from the hardcoded "feature.md")
        write_file ".github/PULL_REQUEST_TEMPLATE/bug_fix.md", <<~MD
          # Bug Fix

          ## Description
          Describe the bug you're fixing

          ## Steps to Reproduce
          Steps to reproduce the behavior
        MD

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b bug-fix-branch"

        # Make a change
        write_file "fix.txt", "This is a bug fix"
        run_command_and_stop "git add fix.txt"
        run_command_and_stop "git commit -m 'Add fix'"
      end

      it "selects the only available template" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with the bug_fix template
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/bug-fix-branch\?expand=1&quick_pull=1&template=bug_fix.md}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with multiple templates" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a feature template
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request

          ## Description
          Describe the feature you're adding

          ## Checklist
          - [ ] Tests added
          - [ ] Documentation updated
        MD

        # Add a bug_fix template (different from the hardcoded "feature.md")
        write_file ".github/PULL_REQUEST_TEMPLATE/bug_fix.md", <<~MD
          # Bug Fix

          ## Description
          Describe the bug you're fixing

          ## Steps to Reproduce
          Steps to reproduce the behavior
        MD

        # Add a config file with MECE path patterns using globs
        write_file ".github/PULL_REQUEST_TEMPLATE/config.yml", <<~YML
          templates:
            - file: bug_fix.md
              pattern: "**/fix*.txt"
            - file: feature.md
              pattern: "**/feature*.txt"
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b bug-fix-branch"

        # Match a feature contribution
        write_file "feature.txt", "This is a feature contribution"
        run_command_and_stop "git add feature.txt"
        run_command_and_stop "git commit -m 'Add feature'"
      end

      it "selects template based on file patterns using config.yml" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with template parameter
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/bug-fix-branch\?expand=1&quick_pull=1&template=feature.md}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with inline templates" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a config file with inline templates
        write_file ".github/PULL_REQUEST_TEMPLATE/config.yml", <<~YML
          templates:
            - name: "Bug Fix"
              pattern: "**/fix*.txt"
              body: |
                # Bug Fix

                ## Description
                Describe the bug you're fixing

                ## Steps to Reproduce
                Steps to reproduce the behavior

                ## Checklist
                - [ ] Bug is reproducible
                - [ ] Steps to reproduce are clear
                - [ ] Fix has been tested
            - name: "Feature Request"
              pattern: "**/feature*.txt"
              body: |
                # Feature Request

                ## Description
                Describe the feature you're adding

                ## Motivation
                Why is this feature needed?

                ## Checklist
                - [ ] Tests added
                - [ ] Documentation updated
                - [ ] Feature has been tested
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add inline PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Match a feature contribution
        write_file "feature.txt", "This is a feature contribution"
        run_command_and_stop "git add feature.txt"
        run_command_and_stop "git commit -m 'Add feature'"
      end

      it "selects template based on file patterns using inline templates" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with template parameter
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/feature-branch\?expand=1&quick_pull=1&template=feature_request}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with mixed inline and file-based templates" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a file-based template
        write_file ".github/PULL_REQUEST_TEMPLATE/bug_fix.md", <<~MD
          # Bug Fix

          ## Description
          Describe the bug you're fixing

          ## Steps to Reproduce
          Steps to reproduce the behavior
        MD

        # Add a config file with mixed templates
        write_file ".github/PULL_REQUEST_TEMPLATE/config.yml", <<~YML
          templates:
            - file: bug_fix.md
              pattern: "**/fix*.txt"
            - name: "Feature Request"
              pattern: "**/feature*.txt"
              body: |
                # Feature Request

                ## Description
                Describe the feature you're adding

                ## Motivation
                Why is this feature needed?

                ## Checklist
                - [ ] Tests added
                - [ ] Documentation updated
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add mixed PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Match a feature contribution
        write_file "feature.txt", "This is a feature contribution"
        run_command_and_stop "git add feature.txt"
        run_command_and_stop "git commit -m 'Add feature'"
      end

      it "selects inline template when it matches file patterns" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with template parameter
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/feature-branch\?expand=1&quick_pull=1&template=feature_request}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with ambiguous templates (no configuration)" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a feature template
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request

          ## Description
          Describe the feature you're adding

          ## Checklist
          - [ ] Tests added
          - [ ] Documentation updated
        MD

        # Add a bug_fix template (different from the hardcoded "feature.md")
        write_file ".github/PULL_REQUEST_TEMPLATE/bug_fix.md", <<~MD
          # Bug Fix

          ## Description
          Describe the bug you're fixing

          ## Steps to Reproduce
          Steps to reproduce the behavior
        MD

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b bug-fix-branch"

        # Match a feature contribution
        write_file "feature.txt", "This is a feature contribution"
        run_command_and_stop "git add feature.txt"
        run_command_and_stop "git commit -m 'Add feature'"

        # Match a fix contribution
        write_file "fix.txt", "This is a bug fix"
        run_command_and_stop "git add fix.txt"
        run_command_and_stop "git commit -m 'Add fix'"
      end

      it "generates URL without template parameter" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL without template parameter
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/bug-fix-branch\?expand=1&quick_pull=1}
        )

        # Verify stderr message about multiple templates
        expect(last_command_started).to have_output_on_stderr(
          "Multiple templates found but no config.yml to select between them. Add a config.yml file to specify which template to use for which files."
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with ambiguous templates" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add multiple templates
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request
          Feature template content
        MD

        write_file ".github/PULL_REQUEST_TEMPLATE/bug_fix.md", <<~MD
          # Bug Fix
          Bug fix template content
        MD

        # Add mapping file with overlapping patterns
        write_file ".github/PULL_REQUEST_TEMPLATE/config.yml", <<~YML
          templates:
            - file: feature.md
              pattern:
                - "**/*.rb"
                - "**/*.txt"
            - file: bug_fix.md
              pattern:
                - "**/*.rb"
                - "**/*.md"
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Make changes that match both templates
        write_file "app.rb", "This is Ruby code"
        write_file "test.txt", "This is a test"
        write_file "docs.md", "This is documentation"
        run_command_and_stop "git add app.rb test.txt docs.md"
        run_command_and_stop "git commit -m 'Add mixed changes'"
      end

      it "selects the first matching template" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with the first matching template
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/feature-branch\?expand=1&quick_pull=1&template=feature.md}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with valid setup" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add a feature template
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request

          ## Description
          Describe the feature you're adding

          ## Checklist
          - [ ] Tests added
          - [ ] Documentation updated
        MD

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Make a change
        write_file "feature.txt", "This is a new feature"
        run_command_and_stop "git add feature.txt"
        run_command_and_stop "git commit -m 'Add feature'"
      end

      it "generates correct PR URL" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with template parameter
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/feature-branch\?expand=1&quick_pull=1&template=feature.md}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with catch-all pattern and dot files" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add templates
        write_file ".github/PULL_REQUEST_TEMPLATE/default.md", <<~MD
          # Default Template
          Default template content
        MD

        write_file ".github/PULL_REQUEST_TEMPLATE/other.md", <<~MD
          # Other Template
          Other template content
        MD

        # Add config file with catch-all template
        write_file ".github/PULL_REQUEST_TEMPLATE/config.yml", <<~YML
          templates:
            - file: other.md
              pattern: "**/*.dat"
            - file: default.md
              pattern: "**/*"
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Make changes that include dot files and nested paths
        write_file ".github/PULL_REQUEST_TEMPLATE/first.md", "New template"
        write_file ".github/pull_request_template.md", "Another template"
        write_file "README.md", "Updated README"
        write_file "feature.txt", "New feature"
        run_command_and_stop "git add .github README.md feature.txt"
        run_command_and_stop "git commit -m 'Add templates and files'"
      end

      it "matches dot files and nested paths" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL with the default template
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/feature-branch\?expand=1&quick_pull=1&template=default.md}
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end

    context "with no matching templates" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add templates with specific patterns
        write_file ".github/PULL_REQUEST_TEMPLATE/feature.md", <<~MD
          # Feature Request
          Feature template content
        MD

        write_file ".github/PULL_REQUEST_TEMPLATE/bug_fix.md", <<~MD
          # Bug Fix
          Bug fix template content
        MD

        # Add config file with specific patterns
        write_file ".github/PULL_REQUEST_TEMPLATE/config.yml", <<~YML
          templates:
            - file: feature.md
              pattern: "**/*.rb"
            - file: bug_fix.md
              pattern: "**/*.md"
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Make changes that don't match any template patterns
        write_file "config.json", "{}"
        write_file "data.txt", "Some data"
        run_command_and_stop "git add config.json data.txt"
        run_command_and_stop "git commit -m 'Add config and data'"
      end

      it "generates URL without template parameter" do
        # Run the command
        run_command_and_stop "pull_request_templates pr-url"

        # Verify it outputs a valid GitHub PR URL without template parameter
        expect(last_command_started).to have_output(
          %r{https://github.com/user/repo/compare/feature-branch\?expand=1&quick_pull=1}
        )

        # Verify stderr message about no matching templates
        expect(last_command_started).to have_output_on_stderr(
          "No template matches the changed files. Add a catch-all pattern (e.g. '**/*') to your config.yml to always use a template."
        )

        # Check it has a successful exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end
  end
end
