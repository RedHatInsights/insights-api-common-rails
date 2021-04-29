class Task < ApplicationRecord
  include TenancyConcern
  belongs_to :source
end
