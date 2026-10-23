#' look up a single question record in v1qs
#' @param question_id character(1) value matched against `v1qs$question_id`
#' @return one-row data.frame from `v1qs`
#' @export
cbb_question = function(question_id) {
  data("v1qs", package = "CBBBioc")
  hit = v1qs[v1qs$question_id == question_id, , drop = FALSE]
  if (nrow(hit) == 0) {
    stop(sprintf("question_id %s not found in v1qs$question_id", question_id))
  }
  if (nrow(hit) > 1) {
    stop(sprintf("question_id %s is not unique in v1qs$question_id", question_id))
  }
  hit
}

#' get (creating if needed) the BiocFileCache used for CompBioBench downloads
#' @param cache_dir path to cache directory, default from `BiocFileCache::getBFCOption("CACHE")`
#' @return a `BiocFileCache` instance
#' @note downloads are cached by URL, so repeated calls for the same file reuse the local copy
#' @export
cbb_filecache = function(cache_dir = NULL) {
  if (!requireNamespace("BiocFileCache", quietly = TRUE)) {
    stop("BiocFileCache package is required; please install it")
  }
  if (is.null(cache_dir)) {
    BiocFileCache::BiocFileCache(ask = FALSE)
  } else {
    BiocFileCache::BiocFileCache(cache_dir, ask = FALSE)
  }
}

#' fetch the files associated with a question into a destination directory
#' @param question_id character(1) value matched against `v1qs$question_id`
#' @param dest_dir path to directory where files should be placed
#' @param bfc a `BiocFileCache` instance; if NULL, `cbb_filecache()` is used
#' @return character vector of file names written into `dest_dir` (empty if the
#' question has no associated files)
#' @note downloads go through `cbb_filecache()`, so a file already cached locally
#' is not re-downloaded; it is just copied from the cache into `dest_dir`
#' @export
cbb_fetch_files = function(question_id, dest_dir, bfc = NULL) {
  if (is.null(bfc)) bfc = cbb_filecache()
  all_files = fixup_files()
  files = all_files[[question_id]]
  if (is.null(files) || length(files) == 0 || all(files == "")) {
    return(character(0))
  }
  files = files[files != ""]
  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  for (f in files) {
    url = cbb_url(f)
    rpath = BiocFileCache::bfcrpath(bfc, url)
    ok = file.copy(rpath, file.path(dest_dir, f), overwrite = TRUE)
    if (!ok) stop(sprintf("failed to copy cached file for %s into %s", f, dest_dir))
  }
  files
}

#' build the agent-facing prompt text for a question
#' @param question character(1) question text
#' @param files character vector of workspace-relative file names available to the agent
#' @param timeout_minutes numeric(1) time budget to state in the prompt
#' @return character(1) prompt text
#' @note mirrors the prompt format produced by `generate_prompt()` in
#' Genentech's `compbiobench-runner` (`run_benchmark.py`), so prompts staged
#' here are comparable to those used by that runner
#' @export
cbb_build_prompt = function(question, files = character(0), timeout_minutes = 60) {
  parts = c(sprintf("QUESTION: %s", question))

  if (length(files) > 0) {
    parts = c(parts,
      "",
      sprintf("FILES: %s", paste(files, collapse = ", ")),
      "",
      "Note: All files are located in your current working directory (workspace).")
  }

  parts = c(parts,
    "",
    "INSTRUCTIONS:",
    sprintf("- You have %d minutes to complete this task", as.integer(timeout_minutes)),
    "- Do not read/access any other files outside the workspace.",
    "- Get any files or tools you need from the internet.",
    "- You are free to modify the current conda environment as needed.",
    "- Keep all scripts and intermediate data in the workspace only.",
    "",
    "OUTPUT CONTRACT (IMPORTANT):",
    "- Your final response will be graded by exact string match.",
    "- Return EXACTLY ONE LINE containing **ONLY** the final answer in the format required by the question.",
    "- Do NOT include any explanation, reasoning, labels, prefixes, markdown, code fences, citations, or extra whitespace lines.",
    "- Any extra text before or after the answer is incorrect.",
    "- Before sending your final response, verify it is exactly one line and nothing else.",
    "")

  paste(parts, collapse = "\n")
}

#' write a human-readable prompt.md describing a staged question
#' @param prompt_path path to write
#' @param question_id character(1) question identifier
#' @param domain value to report (may be NA)
#' @param question_style value to report (may be NA)
#' @param files character vector of workspace-relative file names
#' @param prompt character(1) full prompt text, as produced by `cbb_build_prompt()`
#' @return (invisibly) `prompt_path`
#' @keywords internal
.cbb_write_prompt_md = function(prompt_path, question_id, domain, question_style, files, prompt) {
  lines = c(
    sprintf("# Prompt: %s", question_id),
    "",
    "| Field | Value |",
    "|-------|-------|",
    sprintf("| **Domain** | %s |", domain),
    sprintf("| **Question Style** | %s |", question_style))
  if (length(files) > 0) {
    lines = c(lines, sprintf("| **Workspace Files** | `%s` |", paste(files, collapse = ", ")))
  }
  lines = c(lines, "", "## Prompt", "", "```", prompt, "```", "")
  writeLines(lines, prompt_path)
  invisible(prompt_path)
}

#' set up a self-contained folder for an agent to answer a v1qs question
#' @param question_id character(1) value matched against `v1qs$question_id`
#' @param base_dir path under which the question folder is created, default `tempdir()`
#' @param timeout_minutes numeric(1) time budget stated in the prompt, default 60
#' @param overwrite logical(1); if TRUE, remove and recreate an existing question folder
#' @param bfc a `BiocFileCache` instance; if NULL, `cbb_filecache()` is used
#' @return (invisibly) a list with elements `question_dir`, `workspace_dir`,
#' `prompt_path`, `files`, and `prompt`
#' @note mirrors the per-question `workspace/` + `prompt.md` layout produced by
#' Genentech's `compbiobench-runner` before it invokes an LLM CLI; this function
#' only stages the folder, it does not run any agent
#' @examples
#' \dontrun{
#'   ws = cbb_setup_workspace("bam-infer-read-length-q1")
#'   ws$workspace_dir
#'   cat(ws$prompt)
#' }
#' @export
cbb_setup_workspace = function(question_id, base_dir = tempdir(), timeout_minutes = 60,
                                overwrite = FALSE, bfc = NULL) {
  row = cbb_question(question_id)

  question_dir = file.path(base_dir, question_id)
  if (dir.exists(question_dir) && overwrite) unlink(question_dir, recursive = TRUE)
  workspace_dir = file.path(question_dir, "workspace")
  dir.create(workspace_dir, recursive = TRUE, showWarnings = FALSE)

  files = cbb_fetch_files(question_id, workspace_dir, bfc = bfc)

  prompt = cbb_build_prompt(row$question, files, timeout_minutes)
  prompt_path = file.path(question_dir, "prompt.md")
  .cbb_write_prompt_md(prompt_path, question_id, row$domain, row$question_style, files, prompt)

  invisible(list(
    question_dir = question_dir,
    workspace_dir = workspace_dir,
    prompt_path = prompt_path,
    files = files,
    prompt = prompt
  ))
}
