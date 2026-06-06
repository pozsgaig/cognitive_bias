library(httr)
library(jsonlite)
library(future.apply)

load("Raw_data/Lit_Rev_updated_2025_12_14.RDA")

Lit_Rev_new<-Lit_Rev |>
  filter(!is.na(scopusID)) |> 
  filter(!scopusID %in% Scopus_searches$scopusID) |>
  filter(!is.na(abstract), !abstract=="")


plan(multisession, workers = 2)  # start small

OLLAMA_URL  <- "http://localhost:11434/api/chat"  # Ollama chat endpoint
# OLLAMA_MODEL <- "llama3.3"
# OLLAMA_MODEL <- "Qwen3.5"
# OLLAMA_MODEL <- "Qwen2.5"
OLLAMA_MODEL <- "qwen2.5:14b"   

get_llm_decision_ollama <- function(title, abstract, keywords, kw1, kw2) {
  # Ensure all fields are character
  title    <- ifelse(is.null(title)    || is.na(title),    "", trimws(as.character(title)))
  abstract <- ifelse(is.null(abstract) || is.na(abstract), "", trimws(as.character(abstract)))
  keywords <- ifelse(is.null(keywords) || is.na(keywords), "", trimws(as.character(keywords)))
  kw1      <- ifelse(is.null(kw1)      || is.na(kw1),      "", trimws(as.character(kw1)))
  kw2      <- ifelse(is.null(kw2)      || is.na(kw2),      "", trimws(as.character(kw2)))
  
  prompt_text <- paste(
    "Decide whether to include or exclude this paper for a systematic review based on the following criteria (apply in order):",
    "1. Title and abstract present",
    "2. Language is English",
    "3. Original research, must not be a literature review, systematic review, or meta-analysis",
    "4. Annual cash crop, not woody",
    "5. Not lab/greenhouse, GMO, pesticide testing",
    "6. Organism intervention (not just management practices)",
    "7. Must be a hands-on field experiment with sampling, investigation. There should be a control/treatment and replications. Consider this carefully, not only based on word occurrences.",
    "8. Must be related to ecosystem services/disservices, even if these expressions are not explicitely used.",
    "9. KW1/KW2 relevance (use semantic understanding, not just keywords). The main topic should be around the KW1 organism.",
    "Most nuanced decisions for 7-9.",
    "",
    "Paper:",
    paste("Title:", title),
    paste("Abstract:", abstract),
    paste("Keywords:", keywords),
    paste("KW1:", kw1),
    paste("KW2:", kw2),
    "",
    "Task: Decide whether to INCLUDE or EXCLUDE this paper for the systematic review.",
    "You MUST choose exactly one of the two options based on the criteria. Decide exclude if unsure (less than 70%).",
    "",
    "Output format:",
    "Answer with a single word only, exactly one of:",
    "- Include",
    "- Exclude",
    "Do not write anything else.",
    sep = "\n"
  )
  
  body <- list(
    model = OLLAMA_MODEL,
    stream = FALSE,
    format = schema,
    messages = list(
      list(role = "user", content = prompt_text)
    ),
    options = list(
      temperature = 0.15,
      top_p = 0.9,
      top_k = 40,
      num_ctx = 4096,
      num_predict = 10,
      seed = 42
    )
  )
  
  resp <- POST(
    OLLAMA_URL,
    body   = body,
    encode = "json"
  )
  
  if (status_code(resp) != 200) {
    txt <- tryCatch(content(resp, "text", encoding = "UTF-8"), error = function(e) "(parse error)")
    return(list(Decision = "Error", Reason = paste("Ollama API error:", txt)))
  }
  
  res <- content(resp, "parsed", encoding = "UTF-8")
  if (is.null(res$message) || is.null(res$message$content)) {
    return(list(Decision = "Error", Reason = "No message content in Ollama response"))
  }
  
  reply <- paste(res$message$content, collapse = "\n")
  
  # Trim and split into tokens
  reply_trim <- trimws(reply)
  tokens <- unlist(strsplit(reply_trim, "\\s+"))
  first  <- if (length(tokens) > 0) tokens[1] else ""
  
  decision_norm <- tolower(first)
  
  if (decision_norm %in% c("include", "included")) {
    decision <- "Include"
  } else if (decision_norm %in% c("exclude", "excluded")) {
    decision <- "Exclude"
  } else {
    decision <- "Error"
  }
  
  decision
  
}

safe_decision <- function(row) {
  tryCatch(
    get_llm_decision_ollama(
      title    = row$articletitle,
      abstract = row$abstract,
      keywords = row$keywords,
      kw1      = row$KW1,
      kw2      = row$KW2
    ),
    error = function(e) {
      list(Decision = "Error")
    }
  )
}



colnames(Lit_Rev_new)
AI_decided_papers_upd<-Lit_Rev_new[,c("scopusID", "articletitle", "abstract", "keywords", "KW1", "KW2")]
AI_decided_papers_upd<-AI_decided_papers_upd |> 
  filter(!abstract=="" & !keywords=="")

n <- nrow(AI_decided_papers_upd)
decisions <- vector("list", n)

for (i in seq_len(n)) {
  decisions[[i]] <- safe_decision(AI_decided_papers_upd[i, ])
  if (i %% 10 == 0 || i == n) {
    pct <- round(100 * i / n, 1)
    cat("Progress:", i, "of", n, "rows (", pct, "%)\n")
  }
}
AI_decided_papers_upd$Decision<-unlist(decisions)

table(AI_decided_papers_upd$Decision)
save(AI_decided_papers_upd, file = "Calculated_data/AI_decided_papers_upd2.RDA")


# for (i in 1:nrow(AI_decided_papers_upd)) {
#   title <- AI_decided_papers_upd[i, "articletitle"]
#   abstract <- AI_decided_papers_upd[i, "abstract"]
#   keywords <- AI_decided_papers_upd[i, "keywords"]
#   kw1 <- AI_decided_papers_upd[i, "KW1"]
#   kw2 <- AI_decided_papers_upd[i, "KW2"]
#   
#   result <- get_llm_decision_ollama(title, abstract, keywords, kw1, kw2)
#   AI_decided_papers_upd[i, "Decision"] <- result$Decision
#   AI_decided_papers_upd[i, "Reason"] <- result$Reason
#   cat("Row", i, "done\n")
# }