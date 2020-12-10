function log_warn(){
  local message=${1:-no message provided}
  echo ""
  echo "##[warning] LOG: %s" "$message"
}
function log_info(){
  local message=${1:-no message provided}
  echo ""
  echo "##[info] LOG: %s" "$message"
}
function log_error(){
  local message=${1:-no message provided}
  echo ""
  echo "##[error] LOG: %s" "$message"
}
function mark_task_complete_with_issues(){
  local message=${1:-Complete with issues}
  echo ""
  echo "##vso[task.complete result=SucceededWithIssues;]$message"
}

