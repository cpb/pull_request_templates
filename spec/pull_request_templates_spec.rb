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
        run_command_and_stop "pull_request_templates pr-url"

        # Only verify it mentions no templates
        expect(last_command_started).to have_output(/No templates found/)

        # Check it has the expected exit status
        expect(last_command_started).to have_exit_status(0)
      end
    end
  end
end
