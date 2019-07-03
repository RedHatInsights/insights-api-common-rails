require "manageiq/password/password_mixin"

class Authentication < ApplicationRecord
  include ::ManageIQ::Password::PasswordMixin
  include TenancyConcern

  encrypt_column :password

  belongs_to :resource, :polymorphic => true
end
