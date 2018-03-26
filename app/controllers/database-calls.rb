get '/database-calls/table' do 
  authorize!
  if request.xhr?
    return if params[:value] == ""
    tables_hash = return_tables_hash()
    column_names = tables_hash[params[:value].to_sym].column_names[0..-3]
    {"column_names": column_names}.to_json
  end
end

get '/database-calls/find-data' do 
  authorize!
  if request.xhr?
    tables_hash = return_tables_hash()
    obj = tables_hash[params[:table].to_sym].find_by(id: params[:id])
    {"result": obj}.to_json
  end
end

put '/database-calls/update-data' do
  authorize!
  if request.xhr?
    tables_hash = return_tables_hash()
    entry = tables_hash[params[:table].to_sym].find_by(id: params[:id])
    params_no_table = params
    params_no_table.delete("table")
    entry.update(params_no_table)
    {"result": entry}.to_json
  end
end

get '/database-calls/get-h2h-data' do
  if request.xhr?
    player1 = Player.all.find { |player| player.full_tag == params[:player1] }
    player2 = Player.all.find { |player| player.full_tag == params[:player2] }
    player2_id = player2.id
    
    matches = player1.matches_against(player2_id).select { |match| match.event.name == params[:game] }
    tournaments = matches.map do |played_match|
      { 
        "name": played_match.tournament.name, 
        "date": played_match.tournament.date
      }
    end
    record = player1.match_record(player2_id, matches)
    result = {
      "matches": matches, 
      "tournaments": tournaments,
      "player1":  {
                    "obj": player1,
                    "full_tag": player1.full_tag
                  },
      "player2":  {
                    "obj": player2,
                    "full_tag": player2.full_tag
                  }, 
      "record": record
    }
    result.to_json
  end
end