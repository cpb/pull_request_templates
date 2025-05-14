# frozen_string_literal: true

require_relative "pull_request_templates/version"
require_relative "pull_request_templates/cli"

require "thor/error"

module PullRequestTemplates
  Error = Class.new(StandardError)
  CliError = Class.new(Thor::Error)
  AmbiguousTemplateSelection = Class.new(CliError)
end
