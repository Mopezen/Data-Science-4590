######################## START: REPORT GENERATOR ########################

# render drop down menu of all the teams in the database
output$teamReportDropdown <- renderUI({
  allteams <- getAllTeams()$team_id
  names(allteams) <- getAllTeams()$teamname
  allteams <- allteams[2:length(allteams)] # remove no team at 1
  selectInput("teamReportName", "Select Team: ", choices = allteams, selected = "1610612761")
})

# function to get all the teams in the database
getAllTeams <- reactive({
  nbacon <- connectToDb()
  allTeams <- dbGetQuery(nbacon, paste0("SELECT * FROM Team"))
  setDT(allTeams)
  killDbConnections()
  return(allTeams)
})

# function to get all the players in the database of a chosen team
getAllPlayersOfTeamReport <- reactive({
  nbacon <- connectToDb()
  allPlayers <- dbGetQuery(nbacon, paste0("SELECT player_id FROM Player WHERE team_id = ", input$teamReportName))
  setDT(allPlayers)
  killDbConnections()
  return(allPlayers)
})

# function to get the stats of a player
getPlayerStatsReport <- function(playerID) {
  nbacon <- connectToDb()
  playerAveragesDF <- dbGetQuery(nbacon, paste0("SELECT *, off_rebounds + def_rebounds AS rebounds FROM PlayerSeasonStats WHERE player_id = ", playerID))
  killDbConnections()
  if(nrow(playerAveragesDF) == 0) {
    playerAveragesURL <- paste0("http://stats.nba.com/stats/playercareerstats?PerMode=PerGame&PlayerID=", playerID)
    
    playerAveragesJSON <- fromJSON(RCurl::getURL(playerAveragesURL))
    #playerAveragesJSON <- fromJSON(playerAveragesURL)
    
    playerAveragesDF <- data.frame(matrix(unlist(playerAveragesJSON$resultSets[[3]][[1]]), ncol = 27))
    colnames(playerAveragesDF) <- playerAveragesJSON$resultSets[[2]][[1]]
  } else {
    colnames(playerAveragesDF) <- c("PLAYER_ID", "SEASON_ID", "GP", "GS", "MIN", "FGM", "FGA",
                                    "FG3M", "FG3A", "FTM", "FTA", "OREB", "DREB", "AST", "STL",
                                    "BLK", "TOV", "PF", "PTS", "REB")
    playerAveragesDF$PLAYER_ID <- NULL
    playerAveragesDF$SEASON_ID <- NULL
  }
  playerAveragesDF$PTS <- as.numeric(as.vector(playerAveragesDF$PTS))
  playerAveragesDF$REB <- as.numeric(as.vector(playerAveragesDF$REB))
  playerAveragesDF$AST <- as.numeric(as.vector(playerAveragesDF$AST))
  playerAveragesDF$STL <- as.numeric(as.vector(playerAveragesDF$STL))
  playerAveragesDF$BLK <- as.numeric(as.vector(playerAveragesDF$BLK))
  playerAveragesDF$TOV <- as.numeric(as.vector(playerAveragesDF$TOV))
  return (playerAveragesDF)
}

output$report <- downloadHandler(
  # For PDF output, change this to "report.pdf"
  filename = "report.html",
  content = function(file) {
    # Copy the report file to a temporary directory before processing it, in
    # case we don't have write permissions to the current working dir (which
    # can happen when deployed).
    tempReport <- file.path("server/report.Rmd")
    file.copy("report.Rmd", tempReport, overwrite = TRUE)
    
    # Set up parameters to pass to Rmd document
    params <- list(teamReportId = input$teamReportName, teamReportName = getAllTeams()[team_id == input$teamReportName]$teamname)
    
    # Create a Progress object
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    progress$set(message = "Operation:", value = 0)
    progress$inc(1/2, detail = "Generating Report...")
    
    # Knit the document, passing in the `params` list, and eval it in a
    # child of the global environment (this isolates the code in the document
    # from the code in this app).
    rmarkdown::render(tempReport, output_file = "report.html",
                      params = params,
                      output_dir = "reports",
                      envir = new.env(parent = globalenv())
    )
    progress$inc(1/2, detail = "Report Generated!")
  }
)

######################## END: REPORT GENERATOR ########################
