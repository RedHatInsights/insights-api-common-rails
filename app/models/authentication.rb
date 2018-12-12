require 'active_record'
require 'rails'
require 'acts_as_tenant'
class Authentication < ActiveRecord::Base
  acts_as_tenant(:tenant)

  belongs_to :resource, :polymorphic => true
  has_one :encryption, :dependent => :destroy

  validates :encryption, :presence => true

  def secret=(secret)
    if encryption.nil?
      self.encryption = Encryption.new(:secret => secret)
    else
      encryption.update_attributes(:secret => secret)
    end
  end

  def secret
   encryption.secret || nil
  end
end
