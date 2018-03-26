$(document).ready(function() {
  // /users/settings ******************************
  $("#profile-form").on("change", "#password-1", checkPasswords)
  $("#profile-form").on("change", "#password-2", checkPasswords)
  // /users/settings ******************************

  // /users/admin ******************************
  $("#table-query").on("change", function() {
    var $selector = $(this);
    var query = $selector.get(0).value;
    var data = {value: query};
    $.ajax({
      url: '/database-calls/table',
      data: data      
    }).done(response => {
      $(".table-form").empty();
      $(".column-list").empty();
      if (!response) return
      JSON.parse(response).column_names.forEach(column => {
        let inputField = "<input id='" + column + "' type='text' name='" + column +"' placeholder='" + column + "'><br>"
        $(".table-form").append(inputField);
        let inputBullet = "<li>" + column + "</li>"
        $(".column-list").append(inputBullet);
      })
      let submitField = "<input type='submit' value='Submit'>"
      $(".table-form").append(submitField)
    })
  });

  $(".table-form").on("change", "#id", function() {
    var $idInput = $(this);
    var id = $idInput.get(0).value;
    var table = $("#table-query").get(0).value;
    var data = {table: table, id: id};
    $.ajax({
      url: '/database-calls/find-data',
      data: data
    }).done(response => {
      var result_obj = JSON.parse(response).result;
      if (!result_obj) alert("There is no entry with id " + id + " in the " + table + " table.")
      for (var property in result_obj) {
        if (property !== "created_at" || property !== "updated_at") {
          let inputField = $("#" + property);
          inputField.val(result_obj[property]);
        }
      }  
    })
  })

  $(".table-grid-container").on("submit", ".table-form", function() {
    event.preventDefault();
    var $tableInputs = $(".table-form :input").slice(0, -1);
    if (!checkInput($tableInputs[0])) {
      alert("ID cannot be blank.");
      return
    }
    if (checkBlankInputs($tableInputs.slice(1))) return
    $form = $(this);
    $table = $("#table-query").get(0).value;
    var data = $form.serialize() + "&table=" + $table;
    
    $.ajax({
      method: 'PUT',
      url: '/database-calls/update-data',
      data: data
    }).done(response => {
      var result_obj = JSON.parse(response).result;
      var message = ""
      for (var property in result_obj) {
        message += property + ": " + result_obj[property] + "\n";
      }
      alert("Object has been updated with the following attributes:\n\n" + message);
    })
  })
  // /users/admin ******************************

  // /players/h2h ******************************
  $("#player-h2h-form").on("change", "#player-1-input", checkPlayers)
  $("#player-h2h-form").on("change", "#player-2-input", checkPlayers)

  $("#player-h2h-form").on("submit", function() {
    event.preventDefault();
    var $playerInputs = $("input[name=datalist]");
    var player1 = $playerInputs[0].value;
    var player2 = $playerInputs[1].value;
    var game = $("#game-list").get(0).value;
    if (!validifyPlayers(player1, player2, game)) return
    var data = {player1: player1, player2: player2, game: game};
    $.ajax({
      url: '/database-calls/get-h2h-data',
      data: data
    }).done(response => {
      appendToAllResultsContainer()
      var responseObj = JSON.parse(response);
      var matches = responseObj.matches;
      var player1Tag = responseObj.player1.full_tag;
      var player2Tag = responseObj.player2.full_tag
      if (matches.length === 0) {
        appendNoMatches(player1Tag, player2Tag, game);
        return
      };
      appendRecordData(responseObj.record, player1Tag, player2Tag, game)
      var tournaments = responseObj.tournaments;
      var player1Obj = responseObj.player1.obj;
      var player2Obj = responseObj.player2.obj;
      var $resultsList = $(".match-results-list").last();
      matches.forEach((match, index) => {
        let matchItem = getMatchHTML(match, player1Obj, player2Obj, tournaments[index]);
        $resultsList.append(matchItem);
      })
    })  
  })

  $(".erb-container").on("click", ".clear-button", function() {
    $(".all-match-results-container").empty();
    $(this).remove();
  })
  // /players/h2h ******************************

});

function checkInput(element) {
  return !!element.value;
}

function checkBlankInputs(inputArray) {
  var blank = true;
  inputArray.each(function() {
    if ($(this).get(0).value) blank = false;
  })
  return blank;
}

function checkPasswords() {
  var $passwordInputs = $(":password");
  var password1 = $passwordInputs[1].value;
  var password2 = $passwordInputs[2].value;
  $("#password-error").remove();
  if (!password1 || !password2) return
  if (password1 !== password2) {
    var error = "<span id='password-error'>Your passwords do not match!</span>";
    $(".setting-error-container").append(error);
  }
}

function checkPlayers() {
  var $playerInputs = $("input[name=datalist]");
  var player1 = $playerInputs[0].value;
  var player2 = $playerInputs[1].value;
  if (!player1 || !player2) return
  validifyPlayers(player1, player2);
}

function validifyPlayers(player1, player2, game = true) {
  $(".player-form-error").remove();
  var output = true;
  if (!player1 || !player2) {
    var error = "<li class='player-form-error'>One or more players are blank.</li>";
    $("#player-error-container").append(error);
    output = false;
  }
  if (player1 === player2) {
    var error = "<li class='player-form-error'>The two players must be different.</li>";
    $("#player-error-container").append(error);
    output = false
  }
  var playerArray = $("#playerlist").children()
  var tagsArray = getTagsArray(playerArray)
  if (tagsArray.indexOf(player1) < 0) {
    var error = "<li class='player-form-error'>" + player1 + " is not a valid gamer tag.</li>";
    $("#player-error-container").append(error); 
    output = false;
  }
  if (tagsArray.indexOf(player2) < 0) {
    var error = "<li class='player-form-error'>" + player2 + " is not a valid gamer tag.</li>";
    $("#player-error-container").append(error); 
    output = false;
  }
  if (!game) {
    var error = "<li class='player-form-error'>Game cannot blank.</li>";
    $("#player-error-container").append(error);
    output = false;
  }
  return output
}

function getPercentage(record) {
  var wins = parseInt(record.match(/[^-]*/i)[0]);
  var losses = parseInt(record.match(/[^-]*$/i)[0]);
  var total = wins + losses
  return (Math.round(wins / total * 1000) / 10).toString();
}

function getTagsArray(playerArray) {
  var output = [];
  playerArray.each(function() {
    output.push($(this).get(0).value);
  })
  return output;
}

function appendToAllResultsContainer() {
  var $allResultsContainer = $(".all-match-results-container");
  if ($allResultsContainer.children().length === 0) {
    var $erbContainer = $(".erb-container");
    var clearButton = "<br><button type='button' class='button clear-button'>Clear Queries</button>";
    $erbContainer.append(clearButton);
  }
  var matchContainer = '<div class="match-results-container bottom-border"><ul class=match-results-list></ul><br></div>';
  $allResultsContainer.append(matchContainer);
}

function appendNoMatches(player1Tag, player2Tag, game) {
  var noMatch = "<br><span class='header'>" + player1Tag + " and " + player2Tag + " have never played each other in " + game + ".</span>"
  var $resultsContainer = $(".match-results-container").last();
  $resultsContainer.prepend(noMatch);
}

function appendRecordData(record, player1Tag, player2Tag, game) {
  var recordPercentage = getPercentage(record);
  var $resultsContainer = $(".match-results-container").last();
  var percentageItem = "<p class='header'>" + player1Tag + " vs " + player2Tag + " in " + game + ": (" + record + "), " + recordPercentage + "%</p>";
  $resultsContainer.prepend(percentageItem);
}

function getMatchHTML(match, player1, player2, tournament) {
  if (match["winner_id"] === player1["id"]) {
    return "<li>Won " + match["winner_score"] + "-" + match["loser_score"] + " in " + match["round_short"] + " at " + tournament["name"] + " (" + tournament["date"] + ")"
  } else {
    return "<li>Lost " + match["loser_score"] + "-" + match["winner_score"] + " in " + match["round_short"] + " at " + tournament["name"] + " (" + tournament["date"] + ")"
  }
}