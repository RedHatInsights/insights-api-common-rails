source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }
#
# Pull in a development Gemfile if one exists
eval_gemfile('Gemfile.dev.rb') if File.exists?('Gemfile.dev.rb')

# Specify your gem's dependencies in shared-micro-utilities.gemspec
gemspec

gem "manageiq-password", ">=0.1.0", :require => false, :git => "https://github.com/ManageIQ/manageiq-password.git", :branch => "master"
