source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

# Declare your gem's dependencies in topological_inventory.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gem 'rbac-api-client', :git => "https://github.com/RedHatInsights/insights-rbac-api-client-ruby", :branch => "master"

gemspec
