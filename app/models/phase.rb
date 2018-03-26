class Phase < ApplicationRecord
  has_many :groups
  has_many :matches, through: :groups

  has_many :phase_players
  has_many :players, through: :phase_players, source: :player 
  
  belongs_to :event
  has_one :tournament, through: :event
end
