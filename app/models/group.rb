class Group < ApplicationRecord
  has_many :matches
  
  has_many :group_players
  has_many :players, through: :group_players, source: :player 
  
  belongs_to :phase
  has_one :event, through: :phase
  has_one :tournament, through: :event
end
