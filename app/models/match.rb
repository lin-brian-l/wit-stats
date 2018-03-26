class Match < ApplicationRecord
  
  belongs_to :group
  has_one :phase, through: :group
  has_one :event, through: :phase
  has_one :tournament, through: :event

  belongs_to :winner, class_name: "Player"
  belongs_to :loser, class_name: "Player"
  belongs_to :player1, class_name: "Player", foreign_key: :player1_id
  belongs_to :player2, class_name: "Player", foreign_key: :player2_id

end

