function log_warn(){
  local message=${1:-no message provided}
  echo ""
  echo "##[warning] WARN: %s" "$message"
}
function log_info(){
  local message=${1:-no message provided}
  echo ""
  echo "##[info] INFO: %s" "$message"
}
function log_error(){
  local message=${1:-no message provided}
  echo ""
  echo "##[error] ERROR: %s" "$message"
}
function mark_task_complete_with_issues(){
  local message=${1:-DONE}
  echo ""
  echo "##vso[task.complete result=SucceededWithIssues;]$message"
}

