
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
library(ggplot2)
library(shinyAce)
library(YaleToolkit)

textStorage <- ""

numericNames <- function(data) {
    return(subset(whatis(data), type == "numeric" & !(variable.name %in% c("year", "month", "day")))$variable.name)
}

shinyServer(function(input, output, session) {
    
    source("modules/data.R")
    source("modules/plot.R")
    source("modules/regression.R")
    
    observe({
        if (input$vars == "onevar") updateSelectInput(session, "plottype", choices = c("Histogram" = "histogram", "Boxplot" = "boxplot1"), selected = "histogram")
    })
    
    observe({
        if (input$vars == "onevar") {
            updateSelectInput(session, "x", choices = numericNames(intro.data()), selected = numericNames(intro.data())[1])
            updateSelectInput(session, "y", choices = numericNames(intro.data()), selected = numericNames(intro.data())[2])
        }
    })
    
    observe({
        if (input$vars == "twovar") updateSelectInput(session, "plottype", choices = c("Scatterplot" = "scatterplot", "Line Chart" = "linechart", "Boxplot" = "boxplot2", "Bar Chart" = "barchart", "Pareto Chart" = "paretochart"), selected = "scatterplot")
    })
    
    observe({
        nms <- numericNames(intro.data())
        all.nms <- names(intro.data())
        new.x <- if (input$x %in% nms) input$x else nms[1]
        new.y <- if (input$y %in% nms) input$y else nms[2]
        
        if (input$vars == "twovar") {
            updateSelectInput(session, "y", choices = nms, selected = new.y)
            if (input$plottype %in% c("scatterplot", "linechart")) {
                updateSelectInput(session, "x", choices = nms, selected = new.x)
            } else if (input$plottype %in% c("boxplot2", "barchart", "paretochart")) {
                updateSelectInput(session, "x", choices = all.nms, selected = input$x)
            }
        }
    })
    
    observe({
        updateCheckboxGroupInput(session, "tblvars", choices=names(intro.data()))
    })
    
    observe({
        updateSelectInput(session, "xreg", choices = numericNames(intro.data()), selected = numericNames(intro.data())[1])
        updateSelectInput(session, "yreg", choices = numericNames(intro.data()), selected = numericNames(intro.data())[2])
    })
    
    intro.data <-reactive({
        data.initial <- data.module(input$data_own, input$data, input$own)
        textStorage <<- paste(textStorage, paste(c(readLines("modules/data.R")), collapse = "\n"), "\n")
        updateAceEditor(session, "myEditor", value=textStorage)
        
        return(data.initial)
    })

    output$data <- renderDataTable({
        return(intro.data())
    }, options = list(iDisplayLength = 10))
    
    output$plot <- renderPlot({
        str.eval <- paste(input$plottype, "(intro.data(), input$x, input$y, input$bartype)", sep = "")
        print(eval(parse(text = str.eval)))
    })
    
    output$summary <- renderTable({
        if (is.null(input$tblvars)){
            return(NULL)    
        }
        else if (length(input$tblvars) == 1) {
            val <- summary(intro.data()[,input$tblvars])
            df <- data.frame(paste(names(val), " : ", as.numeric(val)))
            colnames(df) <- input$tblvars
            
            return(df)
        } else {
            val <- summary(intro.data()[,input$tblvars])
            return(val)
        }
    }, include.rownames = FALSE)
    
    output$regplot <- renderPlot({
        return(print(scatterplotreg(intro.data(), input$xreg, input$yreg)))
    })
    
    output$regtable <- renderTable({
        return(tablereg(intro.data(), input$xreg, input$yreg))
    })
})