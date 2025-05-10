# frozen_string_literal: true

require_relative "pull_request_templates/version"
require_relative "pull_request_templates/cli"

module PullRequestTemplates
  Error = Class.new(StandardError)
  AmbiguousTemplateSelection = Class.new(Error)
end
