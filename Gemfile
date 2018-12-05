source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }
gem "manageiq-password", :git => "https://github.com/ManageIQ/manageiq-password", :branch => "master"
#
# Pull in a development Gemfile if one exists
eval_gemfile('Gemfile.dev.rb') if File.exists?('Gemfile.dev.rb')

# Specify your gem's dependencies in shared-micro-utilities.gemspec
gemspec
