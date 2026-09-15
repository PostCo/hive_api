# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec standard]
task release: %i[spec standard]

desc "Run read-only contract smoke checks against Hive staging"
task "contract:smoke" do
  ruby "script/contract_smoke.rb"
end
