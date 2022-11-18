
#' Title
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
get_primers <- function(x) {
  if (x == "Riaz") {
    rv <- c(fwd = "ACTGGGATTAGATACCCC",
            rev = "TAGAACAGGCTCCTCTAG",
            revrc = "CTAGAGGAGCCTGTTCTA",
            fwdrc = "GGGGTATCTAATCCCAGT")
    return(rv)    
  }
  return(NA)
}
