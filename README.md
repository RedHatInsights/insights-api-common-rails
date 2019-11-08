# Insights::API::Common

[![Build Status](https://travis-ci.org/RedHatInsights/insights-api-common-rails.svg)](https://travis-ci.org/RedHatInsights/insights-api-common-rails)
[![Maintainability](https://api.codeclimate.com/v1/badges/790ea6c77d82da6be68a/maintainability)](https://codeclimate.com/github/RedHatInsights/insights-api-common-rails/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/790ea6c77d82da6be68a/test_coverage)](https://codeclimate.com/github/RedHatInsights/insights-api-common-rails/test_coverage)
[![Security](https://hakiri.io/github/RedHatInsights/insights-api-common-rails/master.svg)](https://hakiri.io/github/RedHatInsights/insights-api-common-rails/master)

Header, Encryption, RBAC, Serialization, Pagination and other common behavior for Insights microservices built with Rails

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'insights-api-common'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install insights-api-common

## Usage

#### Insights::Api::Common::Filter

| Supported Comparators     | Comparator    |
| ---------------------     | ----------    |
| Integer                   | eq            |
|                           | gt            |
|                           | gte           |
|                           | lt            |
|                           | lte           |
|                           | nil           |
|                           | not_nil       |
| String                    | eq            |
|                           | contains      |
|                           | starts_with   |
|                           | ends_with     |
|                           | nil           |
|                           | not_nil       |
| String (case insensitive) | eq_i          |
|                           | contains_i    |
|                           | starts_with_i |
|                           | ends_with_i   |

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

#### Sorting Results

Sorting query results is controlled via the _sort_by_ query parameter. The _sort_by_ parameter is available for both REST API and GraphQL requests.

The syntax for the _sort_by_ parameter supports:

- a single string representing the attribute name to sort by which may be followed by :asc or :desc
  - **attribute**   (_default order is ascending_)
  - **attribute:asc** (_ascending order_)
  - **attribute:desc** (_descending order_)
- an array of strings of the above syntax

##### Sort_by Examples:

- GET /api/v1.0/sources?sort_by=name
- GET /api/v1.0/vms?sort_by[]=power_state\&sort_by[]=memory:desc

| Query Parameter | Ruby Client Parameter | GraphQL Parameter |
| --------------- | --------------------- | ----------------- |
| "?sort_by=name" | { :sort_by => "name" } | sort_by: "name" |
| "?sort_by[]=power_state\&sort_by[]=memory:desc" | { :sort_by => ["power_state", "memory:desc"] } |  sort_by: ["power_state, "memory:desc"] |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RedHatInsights/insights-api-common-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).
