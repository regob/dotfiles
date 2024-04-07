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
