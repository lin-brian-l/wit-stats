require "http"

get '/tournaments' do
  @tournaments = Tournament.order(date: :desc)
  erb :'tournaments/index'
end

get '/tournaments/new' do
  authorize!
  @link = ""
  erb :'tournaments/new'  
end

get '/tournaments/:id' do
  @tournament = Tournament.find_by(id: params[:id])
  return erb :'404' if !@tournament 
  @events = @tournament.events
  erb :'tournaments/show'  
end

post '/tournaments' do
  @link = params[:tournament][:link]
  link = /(?<=tournament\/)(.+)[\d]/.match(@link)
  http = HTTP.get("https://api.smash.gg/tournament/" + link[0] + "?expand[]=phase&expand[]=groups&expand[]=event")
  json_obj = JSON.parse(http)
  tournament_obj = json_obj["entities"]["tournament"]
  if !Tournament.find_by(id: tournament_obj["id"])
    if !save_tournament(tournament_obj)
      @error = "Tournament failed to save."
      return erb :'tournaments/new'
    end
  else
    @error = "A tournament with ID #{tournament_obj['id']} already exists."
    return erb :'tournaments/new'
  end

  event_array = json_obj["entities"]["event"]
  event_array.each do |event|
    if !Event.find_by(id: event["id"])
      if !save_event(event)
        @error = "The event named #{event['name']} failed to save."
        return erb :'tournaments/new'
      end
    else 
      @error = "An event with ID #{event['id']} already exists."
      return erb :'tournaments/new'
    end
  end

  phase_array = json_obj["entities"]["phase"]
  phase_array.each do |phase|
    if !Phase.find_by(id: phase["id"])
      if !save_phase(phase)
        @error = "The phase with name #{phase["name"]}, ID #{phase["id"]}, and event ID #{phase["eventId"]} failed to save."
        return erb :'tournaments/new'
      end
    else
      @error = "A phase with ID #{phase["id"]} already exists."
      return erb :'tournaments/new'
    end
  end

  group_array = json_obj["entities"]["groups"]
  group_array.each do |group|
    if !Group.find_by(id: group["id"])
      if !save_group(group)
        @error = "The group with name #{group["displayIdentifier"]}, ID #{group["id"]}, and phase ID #{phase["phaseId"]} failed to save."
        return erb :'tournaments/new'
      else 
        @group_http = HTTP.get("https://api.smash.gg/phase_group/" + group["id"].to_s + "?expand[]=sets&expand[]=standings&expand[]=entrants&expand[]=seeds")
        group_json = JSON.parse(@group_http)
        player_array = group_json["entities"]["player"]

        create_players(player_array)

        updated_player_hash = Player.gamer_tag_hash
        standing_array = group_json["entities"]["standings"]
        create_standing(standing_array, player_array, updated_player_hash)

        matches_array = group_json["entities"]["sets"]
        create_matches(matches_array, player_array, updated_player_hash)        
      end
    else
      @error = "A group with ID #{group["id"]} already exists."
      return erb :'tournaments/new'
    end
  end

  redirect "/tournaments/#{tournament_obj['id']}"
end

def save_tournament(tournament)
  tournament_hash = {
    "id": tournament["id"],
    "name": tournament["name"],
    "date": Time.at(tournament["startAt"]),
    "link": "https://smash.gg/" + tournament["slug"]
  }
  tournament = Tournament.new(tournament_hash)
  tournament.save  
end

def save_event(event)
  event_hash = {
    "id": event["id"],
    "tournament_id": event["tournamentId"],
    "name": event["name"],
    "smash_gg_link": "https://smash.gg/" + event["slug"]
  }
  event = Event.new(event_hash)
  event.save
end

def save_phase(phase)
  phase_hash = {
    "id": phase["id"],
    "event_id": phase["eventId"],
    "name": phase["name"]
  }
  phase = Phase.new(phase_hash)
  phase.save  
end

def save_group(group)
  group_hash = {
    "id": group["id"],
    "phase_id": group["phaseId"],
    "name": group["displayIdentifier"]
  }
  group = Group.new(group_hash)
  group.save
end

def create_players(player_array)
  player_hash = Player.gamer_tag_hash
  player_array.each do |player| 
    Player.create_or_find_by_gamer_tag(player["gamerTag"], player_hash, player["prefix"])
  end
end

def create_standing(standing_array, player_array, player_hash)
  standing_array.each do |standing|
    competitor_id = find_player_id(standing["entrantId"].to_s, player_array, player_hash)
    event_id = Phase.find(standing["phaseId"]).event.id
    standing_hash = {
      "player_id": competitor_id,
      "event_id": event_id,
      "placing": standing["placement"],
      "games_played": standing["gamesPlayed"],
      "games_won": standing["gamesWon"],
      "sets_played": standing["setsPlayed"],
      "sets_won": standing["setsWon"]
    }
    EventEntrant.create(standing_hash)
  end
end

def create_matches(matches_array, player_array, player_hash)
  matches_array.each do |played_set|
    competitor_1_id = find_player_id(played_set["entrant1Id"].to_s, player_array, player_hash)
    competitor_2_id = find_player_id(played_set["entrant2Id"].to_s, player_array, player_hash)
    match_hash = {
      "id": played_set["id"],
      "group_id": played_set["phaseGroupId"],
      "round_short": played_set["shortRoundText"],
      "round_full": played_set["fullRoundText"],
      "player1_id": competitor_1_id,
      "player2_id": competitor_2_id,
      "winner_id": played_set["entrant1Id"] == played_set["winnerId"] ? competitor_1_id : competitor_2_id,
      "loser_id": played_set["entrant1Id"] == played_set["loserId"] ? competitor_1_id : competitor_2_id,
      "winner_score": played_set["entrant1Id"] == played_set["winnerId"] ? played_set["entrant1Score"] : played_set["entrant2Score"],
      "loser_score": played_set["entrant1Id"] == played_set["loserId"] ? played_set["entrant1Score"] : played_set["entrant2Score"],
      "loser_placing": played_set["lPlacement"],
      "winner_placing": played_set["wPlacement"]
    }
    Match.create(match_hash)
  end
end

def find_player_id(entrant_id, player_array, player_hash)
  return nil if entrant_id.length == 0
  competitor_tag = player_array.find { |player| entrant_id == player["entrantId"] }["gamerTag"]
  player_hash[downcase_and_squash(competitor_tag)]
end