class User < ApplicationRecord
  include TenancyConcern
end
