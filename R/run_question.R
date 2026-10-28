#' parse one line of Pi's `--mode json` JSONL stream, tolerating non-JSON lines
#' @param line character(1) single line of output
#' @return a list (from `jsonlite::fromJSON(..., simplifyVector = FALSE)`), or
#' `list(type = "raw", content = line)` if `line` is not valid JSON
#' @keywords internal
.cbb_parse_jsonl_line = function(line) {
  if (!nzchar(trimws(line))) return(NULL)
  tryCatch(
    jsonlite::fromJSON(line, simplifyVector = FALSE),
    error = function(e) list(type = "raw", content = line)
  )
}

#' sum Pi per-turn usage fields and extract the final answer from a `pi --mode json` run
#' @param raw_lines character vector, one JSONL event per element (Pi's stdout)
#' @return a list with elements `answer` (character(1)) and `usage` (list of
#' `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_creation_tokens`,
#' `cost_usd`)
#' @note Pi attaches a `usage` object to every assistant `message_end` event,
#' but it reports only that one streamed turn's usage, not the session's
#' cumulative usage -- so, as in `compbiobench-runner`'s `PiProvider.parse_output()`,
#' token counts here are summed across every assistant `message_end` event, and
#' the answer is taken from the last one's last non-empty text line
#' @keywords internal
.cbb_pi_parse_events = function(raw_lines) {
  total_input = total_output = total_cache_read = total_cache_write = 0
  total_cost = 0
  final_text = ""
  saw_assistant_message = FALSE

  for (line in raw_lines) {
    event = .cbb_parse_jsonl_line(line)
    if (is.null(event)) next
    if (!identical(event$type, "message_end")) next
    message = event$message
    if (is.null(message) || !identical(message$role, "assistant")) next
    saw_assistant_message = TRUE

    text_blocks = character(0)
    for (block in message$content) {
      if (identical(block$type, "text") && !is.null(block$text)) {
        text_blocks = c(text_blocks, block$text)
      }
    }
    if (length(text_blocks) > 0) final_text = paste(text_blocks, collapse = "\n")

    usage = message$usage
    if (!is.null(usage)) {
      total_input = total_input + (usage$input %||% 0)
      total_output = total_output + (usage$output %||% 0)
      total_cache_read = total_cache_read + (usage$cacheRead %||% 0)
      total_cache_write = total_cache_write + (usage$cacheWrite %||% 0)
      total_cost = total_cost + ((usage$cost$total %||% 0))
    }
  }

  answer = if (!saw_assistant_message) {
    "ERROR: no assistant message_end event"
  } else {
    lines = strsplit(final_text, "\n")[[1]]
    lines = lines[nzchar(trimws(lines))]
    if (length(lines) == 0) "" else trimws(lines[length(lines)])
  }

  list(
    answer = answer,
    usage = list(
      input_tokens = total_input,
      output_tokens = total_output,
      cache_read_tokens = total_cache_read,
      cache_creation_tokens = total_cache_write,
      cost_usd = total_cost
    )
  )
}

`%||%` = function(x, y) if (is.null(x)) y else x

#' run a v1qs question through the Pi coding agent and return its answer
#' @param question_id character(1) value matched against `v1qs$question_id`
#' @param model character(1) model string as configured in Pi's
#' `~/.pi/agent/models.json`, e.g. `"ollama/gpt-oss:20b"` or
#' `"llama-cpp/qwen3.6-35b-a3b"`
#' @param base_dir path under which the question folder is created, passed to
#' `cbb_setup_workspace()`, default `tempdir()`
#' @param timeout_minutes numeric(1) time budget stated in the prompt and used
#' to derive the default process timeout, default 60
#' @param process_timeout_seconds numeric(1) hard wall-clock limit for the `pi`
#' process itself, default `timeout_minutes * 60 + 60`
#' @param overwrite logical(1); if TRUE, remove and recreate an existing
#' question folder, default FALSE
#' @param bfc a `BiocFileCache` instance; if NULL, `cbb_filecache()` is used
#' @param pi_path character(1) path to the `pi` executable, default `"pi"`
#' (resolved via `PATH`)
#' @param trace_file character(1) path to additionally stream raw JSONL
#' output to as it is produced (e.g. for `tail -f` while the run is in
#' progress); if NULL (default), no such file is written. Unlike `raw_stdout`
#' in the return value, this file is populated incrementally during the run,
#' not only after `pi` exits
#' @return a list with elements `question_id`, `model`, `answer`, `usage`
#' (token counts and cost, see Note), `elapsed_secs`, `raw_stdout` (character
#' vector of JSONL lines), `raw_stderr`, and `workspace` (as returned by
#' `cbb_setup_workspace()`)
#' @note mirrors `PiProvider` in Genentech's `compbiobench-runner`
#' (`run_benchmark.py`): invokes `pi --mode json --model <model> --no-session
#' --print <prompt>` with the working directory set to the staged
#' `workspace/` folder (Pi has no `--add-dir` equivalent; filesystem/tool
#' scope is just the process's cwd), then sums usage across every assistant
#' `message_end` event and takes the last one's last non-empty line as the
#' answer. Locally-served models (Ollama, llama.cpp's `llama-server`, etc.)
#' have no catalog price, so `usage$cost_usd` is always 0 here -- only token
#' counts are meaningful.
#' @examples
#' \dontrun{
#'   res = cbb_run_question("variant-coordinate-lookup-1-q2821",
#'                           model = "llama-cpp/qwen3.6-35b-a3b")
#'   res$answer
#'   res$usage
#'
#'   # watch the trace live from another terminal with e.g.
#'   # tail -f /tmp/q2821_trace.jsonl
#'   res = cbb_run_question("variant-coordinate-lookup-1-q2821",
#'                           model = "llama-cpp/qwen3.6-35b-a3b",
#'                           trace_file = "/tmp/q2821_trace.jsonl")
#' }
#' @export
cbb_run_question = function(question_id, model, base_dir = tempdir(),
                             timeout_minutes = 60,
                             process_timeout_seconds = timeout_minutes * 60 + 60,
                             overwrite = FALSE, bfc = NULL, pi_path = "pi",
                             trace_file = NULL) {
  ws = cbb_setup_workspace(question_id, base_dir = base_dir,
                            timeout_minutes = timeout_minutes,
                            overwrite = overwrite, bfc = bfc)

  old_wd = getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(ws$workspace_dir)

  stderr_file = tempfile()
  on.exit(unlink(stderr_file), add = TRUE)

  # system2() builds a shell command line whenever stderr is redirected to a
  # file, and (per its own docs) does not quote args itself -- a raw
  # multi-line prompt containing shell metacharacters (parens, semicolons,
  # colons, ...) breaks shell parsing unless each arg is shQuote()d here.
  args = shQuote(c("--mode", "json", "--model", model, "--no-session", "--print", ws$prompt))

  # when trace_file is set, stdout is redirected straight to that path by the
  # shell (not buffered through R), so it fills in incrementally while pi is
  # still running and can be tail -f'd from another terminal; raw_stdout is
  # then read back from it once the process exits. Without trace_file,
  # stdout = TRUE is used as before, which only returns after pi exits.
  stdout_dest = if (!is.null(trace_file)) trace_file else TRUE

  start_time = Sys.time()
  stdout_result = tryCatch(
    system2(pi_path, args, stdout = stdout_dest, stderr = stderr_file,
            timeout = process_timeout_seconds),
    warning = function(w) {
      message(sprintf("cbb_run_question: %s", conditionMessage(w)))
      character(0)
    }
  )
  elapsed_secs = as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  raw_stdout = if (!is.null(trace_file)) {
    if (file.exists(trace_file)) readLines(trace_file, warn = FALSE) else character(0)
  } else {
    stdout_result
  }
  raw_stderr = if (file.exists(stderr_file)) {
    paste(readLines(stderr_file, warn = FALSE), collapse = "\n")
  } else {
    ""
  }

  parsed = .cbb_pi_parse_events(raw_stdout)

  list(
    question_id = question_id,
    model = model,
    answer = parsed$answer,
    usage = parsed$usage,
    elapsed_secs = elapsed_secs,
    raw_stdout = raw_stdout,
    raw_stderr = raw_stderr,
    workspace = ws
  )
}
