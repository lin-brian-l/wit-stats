get '/players' do
  @players = Player.all.sort_by { |player| player.full_tag.capitalize }
  erb :'players/index'
end

get '/players/h2h' do
  @players = Player.all.sort_by { |player| player.full_tag.capitalize }
  erb :'players/h2h'
end

get '/players/:id' do
  @player = Player.find_by(id: params[:id]) 
  return erb :'404' if !@player 
  @tournaments = @player.tournaments.distinct.count

  games = ["Melee Singles", "Wii U Singles", "Project M Singles"]

  matches_by_game = games.map { |game| @player.matches_by_game(game) }.reject { |match_array| match_array.empty? }

  @match_data = matches_by_game.map do |game_type|
    game_name = game_type[0].event.name
    event_count = @player.events_by_game(game_name).count
    match_count = game_type.count
    won_match_count = @player.find_won_matches(game_type).count
    won_match_percent = percent(won_match_count, match_count)
    top_8_placings = reverse_tournament_date(@player.top_8_placings_by_game(game_name))
    [game_name, event_count, match_count, won_match_count, won_match_percent, top_8_placings]
  end

  @placings = reverse_tournament_date(@player.placings)
  @match_array = @placings.map do |placing| 
    @player.query_played_matches("event", placing.event.id)
  end
  erb :'players/show'
end