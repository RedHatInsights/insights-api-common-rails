# ManageIQ::API::Common

[![Build Status](https://travis-ci.org/ManageIQ/manageiq-api-common.svg)](https://travis-ci.org/ManageIQ/manageiq-api-common)
[![Maintainability](https://api.codeclimate.com/v1/badges/790ea6c77d82da6be68a/maintainability)](https://codeclimate.com/github/ManageIQ/manageiq-api-common/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/790ea6c77d82da6be68a/test_coverage)](https://codeclimate.com/github/ManageIQ/manageiq-api-common/test_coverage)
[![Security](https://hakiri.io/github/ManageIQ/manageiq-api-common/master.svg)](https://hakiri.io/github/ManageIQ/manageiq-api-common/master)

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/shared/micro/utilities`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'manageiq-api-common'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install manageiq-api-common

## Usage

#### ManageIQ::Api::Common::Filter

After implementing filtering in your application, this is the way to filter via parameters on index functions:

| Query Parameter | Ruby Client Parameter <br> **GraphQL filter: Parameter** |
| --------------- | -------------------------------------------------------- |
|"?filter[name]=reviews"|`{:filter => { :name => "reviews" }}`<br> **`filter: { name: "reviews" }`**|
|"?filter[name][eq]=reviews"|`{:filter => { :name => { :eq => "reviews" } }}` <br> **`filter: { name: { eq: "reviews" } }`**|
|"?filter[name][starts_with]=a"|`{:filter => { :name => { :starts_with => "a" } }}` <br> **`filter: { name: { starts_with: "a" } }`**|
|"?filter[name][ends_with]=manager"|`{:filter => { :name => { :ends_with => "manager" } }}` <br> **`filter: { name: { ends_with: "manager" } }`**|
|"?filter[name][contains]=openshift"|`{:filter => { :name => { :contains => "openshift" } }}` <br> **`filter: { name: { contains: "openshift" } }`**|
|"?filter[id]=5"|`{:filter => { :id => "5" }}` <br> **`filter: { id: "5" }`**|
|"?filter[id][eq]=5"|`{:filter => { :id => { :eq => "5" }}}` <br> **`filter: { id: { eq: "5" } }`**|
|"?filter[id][gt]=180"|`{:filter => { :id => { :gt => "180" }}}` <br> **`filter: { id: { gt: "180" } }`**|
|"?filter[id][gte]=190"|`{:filter => { :id => { :gte => "190" }}}` <br> **`filter: { id: { gte: "190" } }`**|
|"?filter[id][lt]=5"|`{:filter => { :id => { :lt => "5" }}} ` <br> **`filter: { id: { lt: "5" } }`**|
|"?filter[id][lte]=5"|`{:filter => { :id => { :lte => "5" }}}` <br> **`filter: { id: { lte: "5" } }`**|
|"?filter[id][]=5&filter[id][]=10&filter[id][]=15&filter[id][]=20"|`{:filter => { :id => ["5", "10", "15", "20"]}}` <br> **`filter: { id: ["5", "10", "15", "20"] }`**|
|"?filter[id][eq][]=5&filter[id][eq][]=10&filter[id][eq][]=15&filter[id][eq][]=20"|`{:filter => { :id => { :eq => ["5", "10", "15", "20"]}}}` <br> **`filter: { id: { eq: ["5", "10", "15", "20"] }`**|

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/shared-micro-utilities. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
