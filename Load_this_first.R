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

#home<-"C:/ADATOK/Gabor/China_FAFU_postdoc/Others/111"
#home<-"C:/Gabor/Munka/China_FAFU_postdoc/Others/111_2"
home<-"D:/Gabor/Munka/China_FAFU_postdoc/Others/111"
#home<-"D:/Gabor/Dropbox/Munka/China_FAFU_postdoc/Others/111"
setwd(home)
Raw_data<-paste(home, "Raw_data", sep="/")
Calculated_data<-paste(home, "Calculated_data", sep="/")
R<-paste(home, "R", sep="/")
plots<-paste(home, "Plots", sep="/")
functions<-"D:/Gabor/Munka/R_functions"
#functions<-"C:/Gabor/Munka/R_functions"
#functions<-"D:/Gabor/Dropbox/Munka/R_functions"

source(paste(paste(functions, "my_file_rename.R", sep="/")))
source(paste(paste(functions, "sajat_functions.R", sep="/")))
source(paste(paste(functions, "Scopus_API.R", sep="/")))
source(paste(paste(functions, "compare_layouts_function.R", sep="/")))
source(paste(paste(functions, "bipart_project_G_function.R", sep="/")))
# for re-reading data only
# source(paste(paste(R, "mysql_data_read", sep="/")))
#

keywords<-read.table(paste(Raw_data, "keywords.csv", sep="/"), sep=",", header = T)
keywords2<-read.table(paste(Raw_data, "keywords2.csv", sep="/"), sep=",", header = T)
keywords3<-read.table(paste(Raw_data, "keywords3.csv", sep="/"), sep=",", header = T)

EDS<-as.character(unique(keywords3[keywords3$Type=="EDS", "Keyword"]))
ES<-as.character(unique(keywords3[keywords3$Type=="ES", "Keyword"]))
ESP<-as.character(unique(keywords3$ESP))

summarise<-dplyr::summarise
degree<-igraph::degree
select<-dplyr::select
#load(paste(Raw_data, "Data2analyse.RData", sep="/"))
