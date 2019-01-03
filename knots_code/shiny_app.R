library(shiny)
ui <- fluidPage(
  sliderInput(inputId = "num",
              label = "Choose a number",
              value = 25, min = 1, max = 1e2),
  submitButton(text = "Submit"),
  sliderInput(inputId = "num2",
              label = "Choose a number",
              value = 25, min = 1, max = 1e2),
  submitButton(text = "Submit2"),
  mainPanel(
    plotOutput("hist"))
)
server <- function(input, output) {
  data <- reactive({
    switch(input$dataset,
           "rock" = rock,
           "pressure" = pressure,
           "cars" = cars)
  })
  output$hist = renderPlot({
    plot(data)
  })
}
shinyApp(ui = ui, server = server)
