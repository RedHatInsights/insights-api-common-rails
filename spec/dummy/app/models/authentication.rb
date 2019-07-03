require "manageiq/password/password_mixin"

class Authentication < ApplicationRecord
  include ::ManageIQ::Password::PasswordMixin
  encrypt_column :password

  include TenancyConcern

  belongs_to :resource, :polymorphic => true
end
