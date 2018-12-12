require 'active_record'
require 'rails'
require 'acts_as_tenant'
class Encryption < ActiveRecord::Base
  include EncryptionConcern
  acts_as_tenant(:tenant)

  validates :authentication_id, :secret, :presence => true

  belongs_to :authentication

  encrypt_column :secret
end
