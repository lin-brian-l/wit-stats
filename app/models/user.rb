require 'bcrypt'

class User < ApplicationRecord
  include BCrypt

  validates :username, { presence: true, uniqueness: true }

  validate :valid_password
  has_one :player

  def password
    @password ||= Password.new(encrypted_password)
  end

  def password=(new_password)
    @password_text = new_password
    @password = Password.create(new_password)
    self.encrypted_password = @password
  end

  def authenticate(new_password)
    self.password == new_password
  end

  def valid_password
    if @password_text.nil?
      errors.add(:password, "can't be blank.")
    elsif @password_text.length < 6
      errors.add(:password, "must be at least 6 characters long.")
    end
  end

  def change_password(new_password)
    self.password = new_password
    self.save
  end

end
