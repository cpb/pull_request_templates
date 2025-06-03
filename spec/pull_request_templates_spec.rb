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

      it "outputs a message about no templates and exits successfully" do
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

        # Add a mapping file with MECE path patterns using globs
        write_file ".github/PULL_REQUEST_TEMPLATE/.mapping.yml", <<~YML
          templates:
            - file: feature.md
              pattern: "**/feature*.txt"
            - file: bug_fix.md
              pattern: "**/fix*.txt"
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

      it "selects template based on file patterns" do
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

      it "guides user to add fallback template" do
        # Run the command
        run_command "pull_request_templates pr-url"
        # Check it has a non-zero exit status
        expect(last_command_started).to have_exit_status(1)
        # Verify it cannot chose a single template and provides guidance
        expect(last_command_started).to have_output(<<~EXPECTED.chomp)
          Unable to pick one template from ["bug_fix.md", "feature.md"] for the changes to 2 files:
          * feature.txt
          * fix.txt

          To resolve this, add a fallback template to your .mapping.yml:
          - file: default.md
            pattern: "**"
            fallback: true

          Run this command to create the fallback template:
          echo 'templates:
            - file: default.md
              pattern: "**"
              fallback: true
          ' >> .github/PULL_REQUEST_TEMPLATE/.mapping.yml
        EXPECTED
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

    context "with fallback template" do
      include_context "git repository setup"
      include_context "git remote setup"
      include_context "initial commit"
      include_context "template directory"

      before do
        # Add multiple templates
        write_file ".github/PULL_REQUEST_TEMPLATE/first.md", <<~MD
          # First Template
          First template content
        MD

        write_file ".github/PULL_REQUEST_TEMPLATE/second.md", <<~MD
          # Second Template
          Second template content
        MD

        write_file ".github/PULL_REQUEST_TEMPLATE/default.md", <<~MD
          # Default Template
          Default template content
        MD

        # Add mapping file with default template
        write_file ".github/PULL_REQUEST_TEMPLATE/.mapping.yml", <<~YML
          templates:
            - pattern:
              - "*.txt"
              file: first.md
            - file: second.md
              pattern:
                - "*.md"
            - file: default.md
              pattern: "**"
              fallback: true
        YML

        # Add files to git
        run_command_and_stop "git add .github"
        run_command_and_stop "git commit -m 'Add PR templates'"

        # Create a feature branch with changes
        run_command_and_stop "git checkout -b feature-branch"

        # Make changes that match multiple templates
        write_file "feature.txt", "This is a feature"
        write_file "docs.md", "This is documentation"
        run_command_and_stop "git add feature.txt docs.md"
        run_command_and_stop "git commit -m 'Add feature and docs'"
      end

      it "handles multiple matching templates" do
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
  end
end
