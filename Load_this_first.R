### for networks
library(igraph)
library(RSelenium)
library(bibliometrix)
library(jsonlite)
library(rvest)
library(httr)
library(XML)
library(RMySQL)
library(openxlsx)
library(shiny)
library(readr)
library(reshape2)
library(wesanderson) # for colour pallettes
library(bipartite) #for bipartite networks
library(qgraph) # for the nice layout
library(RColorBrewer) # for colours
library(fmsb) # for radial plots
library(ggraph) # for linear networks and other plot
library(tidygraph) # general graph manipulation in the tidyverse
library(circlize) # circular chord graphs https://jokergoo.github.io/circlize_book/book/index.html
library(seriation) # for matrix reordering with seriation
library(NetIndices) # for collected network indices
library(scales) #for rescaling data
library(plyr) # for rbind.fill
library(dplyr) # for case_when()
library(easyGgplot2) # for some barplots
library(gridExtra) # for multiple plots on one page
library(ggpubr) # for ggarrange
library(yarrr) # for pirate plots

library(rstudioapi)
setwd(dirname(rstudioapi::getSourceEditorContext()$path))

source(paste(paste(functions, "compare_layouts_function.R", sep="/")))
source(paste(paste(functions, "bipart_project_G_function.R", sep="/")))

keywords<-read.table(paste(Raw_data, "keywords.csv", sep="/"), sep=",", header = T)
keywords2<-read.table(paste(Raw_data, "keywords2.csv", sep="/"), sep=",", header = T)
keywords3<-read.table(paste(Raw_data, "keywords3.csv", sep="/"), sep=",", header = T)

EDS<-as.character(unique(keywords3[keywords3$Type=="EDS", "Keyword"]))
ES<-as.character(unique(keywords3[keywords3$Type=="ES", "Keyword"]))
ESP<-as.character(unique(keywords3$ESP))

summarise<-dplyr::summarise
degree<-igraph::degree
select<-dplyr::select
