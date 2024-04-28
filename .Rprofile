.libPaths('~/R/practice_lib')


# hacks from https://github.com/emacs-ess/ESS/issues/1193
options(pillar.subtle = FALSE)
options(rlang_backtrace_on_error = "none")
invisible(addTaskCallback(function(...) {
    if (interactive()) {
        # Remember to install crayon
        try(cat(crayon::reset("")), silent = TRUE)
    }
    TRUE
}, name = "ansi_reset"))


# stop asking to save workspace 
# https://stackoverflow.com/a/4996252
utils::assignInNamespace(
  "q", 
  function(save = "no", status = 0, runLast = TRUE) 
  {
      .Internal(quit(save, status, runLast))
  }, 
  "base"
)
