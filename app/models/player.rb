class Player < ApplicationRecord
  belongs_to :user

  has_many :placings, class_name: "EventEntrant"
  has_many :events, through: :placings
  has_many :tournaments, through: :events
  has_many :phases, through: :events
  has_many :groups, through: :phases

  has_many :played_matches_1, class_name: "Match", foreign_key: :player1_id
  has_many :played_matches_2, class_name: "Match", foreign_key: :player2_id
  has_many :won_matches, class_name: "Match", foreign_key: :winner_id
  has_many :lost_matches, class_name: "Match", foreign_key: :loser_id

  def played_matches
    played_matches_1.or(played_matches_2)
  end

  def matches_against(opponent_id)
    self.played_matches.select { |match| match.player1_id == opponent_id || match.player2_id == opponent_id }
  end

  def match_record(opponent_id, matches)
    wins = matches.select { |match| match.winner_id == self.id }.count
    losses = matches.select { |match| match.loser_id == self.id }.count
    return "#{wins}-#{losses}"
  end

  def no_dq(match_array)
    match_array.select { |played_match| played_match.loser_id != nil }
  end

  def query_played_matches(query, id)
    valid_queries = ["group", "phase", "event", "tournament"]
    return false unless valid_queries.include?(query)
    self.played_matches.select { |match| match.send(query).id == id }
  end

  def full_tag
    sponsor = self.sponsor || ""
    return sponsor + " | " + self.gamer_tag if sponsor.length > 0
    return self.gamer_tag
  end

  def top_8_placings
    self.placings.select { |placing| placing.placing <= 8 }
  end

  def top_8_placings_by_game(game)
    self.top_8_placings.select { |placing| placing.event.name == game }
  end

  def top_3_placings
    self.placings.select { |placing| placing.placing <= 3 }
  end

  def nth_placings(number)
    self.placings.select { |placing| placing.placing == number }
  end

  def events_by_game(game)
    self.events.select {|event| event.name == game }
  end

  def matches_by_game(game)
    self.played_matches.select {|match| match.event.name == game }
  end

  def find_won_matches(match_array)
    match_array.select { |match| match.winner_id == self.id }
  end

  def self.gamer_tag_hash()
    Hash[self.all.collect { |player| [downcase_and_squash(player.gamer_tag), player.id] }]
  end

  def self.create_or_find_by_gamer_tag(new_tag, player_hash, new_sponsor = nil)
    downcased_tag = downcase_and_squash(new_tag)
    if player_hash.key?(downcased_tag)
      self.find(player_hash[downcased_tag])
    else 
      self.create(gamer_tag: new_tag, sponsor: new_sponsor)
    end
  end

end
