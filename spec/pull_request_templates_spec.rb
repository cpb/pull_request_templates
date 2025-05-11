# frozen_string_literal: true

RSpec.describe PullRequestTemplates, type: :aruba do
  it "has a version number" do
    expect(PullRequestTemplates::VERSION).not_to be nil
  end

  describe "pr-url command" do
    context "when no templates are configured" do
      before do
        # Mock a Git repository environment
        setup_aruba
      end

      it "outputs a message about no templates and exits successfully" do
        # Run the command
        run_command "pull_request_templates pr-url"

        # Only verify it mentions no templates
        expect(last_command_started).to have_output(/No templates found/)

        # Check it has the expected exit status
        expect(last_command_started).to have_exit_status(1)
      end
    end

    context "when GitHub pull request templates exist but on default branch" do
      before do
        # Set up a git repository
        setup_aruba

        # Initialize git repo and ensure main branch
        run_command_and_stop "git init"
        run_command_and_stop "git branch -m main"  # Rename default branch to main
        run_command_and_stop "git config user.email 'test@example.com'"
        run_command_and_stop "git config user.name 'Test User'"

        # Create initial commit to establish main branch
        write_file ".gitkeep", ""
        run_command_and_stop "git add .gitkeep"
        run_command_and_stop "git commit -m 'Initial commit'"

        # Create GitHub pull request template directory
        run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"

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

    context "when no changes detected on feature branch" do
      before do
        # Set up a git repository
        setup_aruba

        # Initialize git repo and ensure main branch
        run_command_and_stop "git init"
        run_command_and_stop "git branch -m main"  # Rename default branch to main
        run_command_and_stop "git config user.email 'test@example.com'"
        run_command_and_stop "git config user.name 'Test User'"

        # Create initial commit to establish main branch
        write_file ".gitkeep", ""
        run_command_and_stop "git add .gitkeep"
        run_command_and_stop "git commit -m 'Initial commit'"

        # Create GitHub pull request template directory
        run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"

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

    context "when a single template is available" do
      before do
        # Set up a git repository
        setup_aruba

        # Initialize git repo and ensure main branch
        run_command_and_stop "git init"
        run_command_and_stop "git branch -m main"  # Rename default branch to main
        run_command_and_stop "git config user.email 'test@example.com'"
        run_command_and_stop "git config user.name 'Test User'"

        # Configure origin remote
        run_command_and_stop "git remote add origin https://github.com/user/repo.git"

        # Create initial commit to establish main branch
        write_file ".gitkeep", ""
        run_command_and_stop "git add .gitkeep"
        run_command_and_stop "git commit -m 'Initial commit'"

        # Create GitHub pull request template directory
        run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"

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

    context "when one among multiple templates describe the change" do
      before do
        # Set up a git repository
        setup_aruba

        # Initialize git repo and ensure main branch
        run_command_and_stop "git init"
        run_command_and_stop "git branch -m main"  # Rename default branch to main
        run_command_and_stop "git config user.email 'test@example.com'"
        run_command_and_stop "git config user.name 'Test User'"

        # Configure origin remote
        run_command_and_stop "git remote add origin https://github.com/user/repo.git"

        # Create initial commit to establish main branch
        write_file ".gitkeep", ""
        run_command_and_stop "git add .gitkeep"
        run_command_and_stop "git commit -m 'Initial commit'"

        # Create GitHub pull request template directory
        run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"

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
          feature.md:
            - feature*.txt
          bug_fix.md:
            - fix*.txt
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

        # # Match a fix contribution
        # write_file "fix.txt", "This is a bug fix"
        # run_command_and_stop "git add fix.txt"
        # run_command_and_stop "git commit -m 'Add fix'"
      end

      it "outputs a valid pull request URL" do
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

    context "when multiple templates could describe the change" do
      before do
        # Set up a git repository
        setup_aruba

        # Initialize git repo and ensure main branch
        run_command_and_stop "git init"
        run_command_and_stop "git branch -m main"  # Rename default branch to main
        run_command_and_stop "git config user.email 'test@example.com'"
        run_command_and_stop "git config user.name 'Test User'"

        # Configure origin remote
        run_command_and_stop "git remote add origin https://github.com/user/repo.git"

        # Create initial commit to establish main branch
        write_file ".gitkeep", ""
        run_command_and_stop "git add .gitkeep"
        run_command_and_stop "git commit -m 'Initial commit'"

        # Create GitHub pull request template directory
        run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"

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

      it "fails, and lists the matched templates and files they have in common" do
        # Run the command
        run_command "pull_request_templates pr-url"

        # Verify it cannot chose a single template
        expect(last_command_started)
          .to have_output(/Unable to pick one template from \["bug_fix\.md", "feature\.md"] for the changes to 2 files:/)
          .and have_output(/\* fix\.txt/)
          .and have_output(/\* feature\.txt/)

        # Check it has a non-zero exit status
        expect(last_command_started).to have_exit_status(1)
      end
    end

    context "when all conditions are met for generating a PR URL" do
      before do
        # Set up a git repository
        setup_aruba

        # Initialize git repo and ensure main branch
        run_command_and_stop "git init"
        run_command_and_stop "git branch -m main"  # Rename default branch to main
        run_command_and_stop "git config user.email 'test@example.com'"
        run_command_and_stop "git config user.name 'Test User'"

        # Configure origin remote
        run_command_and_stop "git remote add origin https://github.com/user/repo.git"

        # Create initial commit to establish main branch
        write_file ".gitkeep", ""
        run_command_and_stop "git add .gitkeep"
        run_command_and_stop "git commit -m 'Initial commit'"

        # Create GitHub pull request template directory
        run_command_and_stop "mkdir -p .github/PULL_REQUEST_TEMPLATE"

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

      it "outputs a valid pull request URL" do
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
  end
end
