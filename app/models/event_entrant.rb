class EventEntrant < ApplicationRecord
  belongs_to :event
  has_one :tournament, through: :event 
  belongs_to :player
end
