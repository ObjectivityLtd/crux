#!/usr/bin/env bash
_read_thresholds(){
  local _thresholds_file="$1"
  local _statistics_file="$2"
  local _test_results_dir="$3"
  local _templates_dir="$4"
  local _title="Thresholds"
  if [ ! -f "$_thresholds_file" ];then
    echo "No thresholds file found"
  else
    while IFS=: read -r f1 f2 f3 || [[ -n "$f1" ]]; do #to include last line for non POSIX files
       if [[ ! "$f1" =~ \#.* ]];then #skip comments
          local _sampler=$f1
          local _metric=$f2
          local _threshold_max=$f3
          echo " -- Evaluating condition for sampler: $_sampler, metric: $_metric, threshold: $threshold_max"
          local _sampler_escaped=$(echo "$_sampler" | sed 's/\//_/g') # chnage / to _
          local _test_name="Metric $_metric should not breach threshold for sampler $_sampler_escaped"
          if [ "$_sampler" == "ANY" ];then #ANY is a special keyword
            res=$(_get_highest_value_for_any_metric "$_statistics_file" "$_metric")
          else
            res=$(_get_metric_for_sampler "$_statistics_file" "$_sampler" "$_metric")
          fi
          local _stack_trace=" Condition : $_sampler, metric actual value: $res, max threshold: $_threshold_max"
          cond=$(awk 'BEGIN {print ('$_threshold_max' >= '$res')}')
          if [ "$cond" == "1" ] ;then #use awk for floating point comparisons
            echo " -- --> Test for $_sampler has passed with metric value: $res"
            _copy_test_template "PASS" "$_test_results_dir" "$_templates_dir" "Threshold has not been breached" "$_stack_trace" "$_test_name" "$_title"
          else
            echo " -- --> Test for $_sampler has failed with metric value: $res"
            _copy_test_template "FAILED" "$_test_results_dir" "$_templates_dir" "Threshold has been breached" "$_stack_trace" "$_test_name" "$_title"
          fi
        fi
    done <"$_thresholds_file"
  fi
}

_get_metric_for_sampler(){
  local _statistics_file=$1
  local _sampler_name=$2
  local _metric=$3
  _get_sample_results_json "$_statistics_file" "$_sampler_name" | jq ".$_metric"
}

_get_sample_results_json(){
  local _statistics_file=$1
  local _sample_name=$2
  cat "$_statistics_file" | jq ".[\"$_sample_name\"]"
}
_get_error_count(){
  local _statistics_file=$1
  _get_highest_value_for_any_metric "$_statistics_file" errorCount
}
_get_highest_value_for_any_metric(){
    local _statistics_file=$1
    local _metric=$2
    _get_any_metric "$_statistics_file" "$_metric" | uniq | sort -nr | head -n1
}
_get_any_metric(){
  local _statistics_file=$1
  local _metric=$2
  cat "$_statistics_file" | jq ".[] | select (.transaction!=\"Total\") .\"$_metric\""

}

_get_error_stack_trace(){
  local _statistics_file=$1
  cat "$_statistics_file" | jq '.[] | select (.errorCount > 0) | [{SamplerName:.transaction,errorCount,percentile_99_milis:.pct3ResTime}]'
}
_copy_test_template(){
  local _type="$1"
  local _res_dir="$2"
  local _template_dir="$3"
  local _message="$4"
  local _stack_trace="$5"
  local _name="$6"
  local _title="$7"
  _name=$(echo "$_name" | sed 's/ /_/g')
  _name="$_type"_"$_name"
  mkdir -p "$_res_dir"
  cp "$_template_dir/$_type"_template.xml "$_res_dir/$_name"_TEST.xml
  sed -i "s+@message+$(echo $_message)+g" "$_res_dir/$_name"_TEST.xml
  sed -i "s+@stacktrace+$(echo $_stack_trace)+g" "$_res_dir/$_name"_TEST.xml
  sed -i "s+@name+$(echo $_name)+g" "$_res_dir/$_name"_TEST.xml
  sed -i "s+@title+$(echo $_title)+g" "$_res_dir/$_name"_TEST.xml
}
_check_for_errors(){
  local _statistics_file=$1
  local _test_results_dir=$2
  local _templates_dir=$3
  local _test_name="Should pass without errors"
  local _title="Errors"
  if [ -f "$_statistics_file" ]; then
    local _errors=$(_get_error_count $_statistics_file)
    if [ "$_errors" != "0" ];then
      echo "Test ended with errors"
      stackTrace=$(_get_error_stack_trace $_statistics_file)
      _copy_test_template "FAILED" "$_test_results_dir" "$_templates_dir" "There are multiple errors in tests" "$stackTrace" "$_test_name" "$_title"
    else
      echo "Test ended without errors"
      _copy_test_template "PASS" "results" "templates" "There are no errors in tests" "no errors" "$_test_name" "$_title"
    fi
  else
    echo "$_statistics_file does not exist"
    _copy_test_template "SKIP" "results" "templates" "Tests have not been run or statistics.json does not exist" "skipped" "$_test_name" "$_title"
  fi

}
evaluate_test_results_as_junit(){
  local _statistics_file=$1
  local _test_results_dir=$2
  local _templates_dir=$3
  local _thresholds_file=$4
  _check_for_errors "$_statistics_file" "$_test_results_dir" "$_templates_dir"
  _read_thresholds "$_thresholds_file" "$_statistics_file" "$_test_results_dir" "$_templates_dir"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  evaluate_test_results_as_junit "$1" "$2" "$3" "$4"
fi