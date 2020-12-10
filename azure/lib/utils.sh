function log_warn(){
  local message=${1:-no message provided}
  echo "##[warning]" "$message"
}
function log_info(){
  local message=${1:-no message provided}
  echo "##[info]" "$message"
}
function log_error(){
  local message=${1:-no message provided}
  echo "##[error]" "$message"
}
function mark_task_complete_with_issues(){
  local message=${1:-DONE}
  echo "##vso[task.complete result=SucceededWithIssues;]$message"
}

