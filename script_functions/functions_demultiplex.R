#' Title
#'
#' @param path 
#'
#' @return
#' @export
#'
#' @examples
tuxify_path <- function(path) {
  sub(".:", paste0("/mnt/", tolower(substring(path,1,1))), path)
}


#' Title
#'
#' @param path 
#' @param sheet 
#' @param runs 
#' @param divider 
#'
#' @return
#' @export
#'
#' @examples
read_sample_sheet <- function(path, sheet = "Sample_sheet", runs, divider) {
  sample_sheet <- readxl::read_excel(inputfile, sheet = inputtab, skip = 1) %>% 
    select(type = 1, name = 10, fwd = 33, rev = 35) %>% 
    mutate(row = 1:n())
  lig <- which(substring(sample_sheet %>% pull(type), 
                         1, 
                         nchar(divider))
               == divider)  
  sample_sheet <- sample_sheet %>% 
    mutate(ligation = 
             ifelse(row > lig[1] & row < lig[2], 
                    1, 
                    ifelse(row > lig[2] & row < lig[3], 
                           2, 
                           ifelse (row > lig[3], 
                                   3, 
                                   NA)))) %>% 
    filter(!is.na(ligation)) 
  sample_sheet
}



#' Title
#'
#' @param samples 
#' @param path 
#'
#' @return
#' @export
#'
#' @examples
export_sample_sheet <- function(samples, path = "", scheme = "ligation_%") {
  if (nchar(path)) {
    if (!dir.exists(path)) dir.create(path)
  } else {
    path <- file.path(path)
  }
  for (runnr in unique(samples$ligation)) {
    scheme_filled <- gsub('%', runnr, scheme)
    tmp <- samples %>% filter(ligation == runnr)
    write_tsv(tmp %>% select(name, fwd, rev), col_names = FALSE,
              file = file.path(path, paste0(scheme_filled, ".smp")))
  }
  invisible()
}
