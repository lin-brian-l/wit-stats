require 'active_support/core_ext/integer/inflections'

class Tournament < ApplicationRecord
  has_many :events
  has_many :event_results, class_name: "EventEntrant", through: :events, source: :results 
  has_many :attendees, class_name: "Player", through: :event_results, source: :player 
  has_many :phases, through: :events
  has_many :groups, through: :phases
  has_many :matches, through: :groups

  def formatted_date
    unformatted_date = Time.parse(self.date.to_s)
    unformatted_date.strftime("%B #{unformatted_date.day.ordinalize}, %Y")
  end
end
