class Application < ApplicationRecord
  include TenancyConcern
  belongs_to :source
  belongs_to :application_type

  validates :availability_status, :inclusion => {:in => %w[available unavailable]}, :allow_nil => true
end
