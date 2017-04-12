report_generator_ui <- tabItem(
  tabName = "reportgenerator",
  fluidRow(
    column(
      width = 3,
      box(
        width = NULL,
        title = "Inputs",
        uiOutput("teamReportDropdown"),
        downloadButton("report", "Generate Report", icon = icon("cog"))
      )
    )
    # column(
    #   width = 9,
    #   box(
    #     height = 650,
    #     width = NULL,
    #     title = "Report",
    #     includeHTML("reports/report.html")
    #   )
    # )
  )
)