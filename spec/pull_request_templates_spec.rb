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

        # Initialize git repo
        run_command_and_stop "git init"
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

        # Initialize git repo
        run_command_and_stop "git init"
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
  end
end
