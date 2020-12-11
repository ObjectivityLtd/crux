#!/usr/bin/env bash
# if you execute these tests on Windows git bash, make sure you install jq via choco: chocolatey install jq

load $HOME/test/test_helper/bats-assert/load.bash
load $HOME/test/test_helper/bats-support/load.bash


function setup_file(){
  rm -f results/*.xml
}

function setup(){
  source evaluate_test_results_as_junit.sh
}
function teardown(){
 rm -f results/*.xml
}

#error-based and general
@test "UT: _get_sample_results_json should return correct result" {
  run _get_sample_results_json test_data/statistics.json "GET /api/skills"
  assert_output --partial 'transaction": "GET /api/skills"'
}

@test "UT: _get_error_count should not return 0 if there are errors in statistics.json" {
  run _get_error_count test_data/statistics.json
  refute_output 0
}

@test "UT: _get_error_count should return 0 if there are no errors in statistics.json" {
  run _get_error_count test_data/statistics.no.errors.json
  assert_output 0
}

@test "IT: evaluate_test_results_as_junit should not throw errors when no errors in statistics.json" {
  run evaluate_test_results_as_junit test_data/statistics.no.errors.json results templates test_data/thresholds.any.properties
  assert_output --partial "Test ended without errors"
}

@test "IT: evaluate_test_results_as_junit should  throw errors when  errors in statistics.json" {
  run evaluate_test_results_as_junit test_data/statistics.json results templates test_data/thresholds.any.properties
  assert_output --partial "Test ended with errors"
}

@test "IT: evaluate_test_results_as_junit should  detect when statistics.json does not exist" {
  run evaluate_test_results_as_junit test_data/statistics.does.not.exist.json results templates test_data/thresholds.any.properties
  assert_output --partial "does not exist"
}

@test "UT: _get_error_stack_trace should include transaction, pecentile and errorCount when errors are found " {
  run _get_error_stack_trace test_data/statistics.json
  assert_output --partial '"SamplerName": "Total"'
  assert_output --partial '"errorCount": 24,'
  assert_output --partial '"percentile_99_milis": 844.040000000001'
}
@test "UT: _copy_test_template produces correct test file for FAILED test" {
  run _copy_test_template "FAILED" "results" "templates" "There are multiple errors in tests" "my stack trace" "Should pass" "Errors"
  assert_success
  run cat results/FAILED_Should_pass_TEST.xml
  assert_output --partial '<failure message="Performance tests failed">There are multiple errors in tests</failure>'
  assert_output --partial '<system-out>my stack trace</system-out'
}
@test "UT: _check_for_errors should produce correctly formatted test results for FAILED test" {
  run _check_for_errors test_data/statistics.json "results" "templates"
  assert_success
  run cat results/FAILED_Should_pass_without_errors_TEST.xml
  assert_output --partial '<failure message="Performance tests failed">There are multiple errors in tests</failure>'
  refute_output --partial '<system-out>my stack trace</system-out'
}
@test "UT: _check_for_errors should produce correctly formatted test results for PASS test" {
  run _check_for_errors test_data/statistics.no.errors.json "results" "templates"
  assert_success
  run cat results/PASS_Should_pass_without_errors_TEST.xml
  assert_success
}
@test "UT: _check_for_errors should produce correctly formatted test results for SKIP test" {
  run _check_for_errors test_data/statistics.does.not.exist.json "results" "templates"
  run cat results/SKIP_Should_pass_without_errors_TEST.xml
  assert_success
}

@test "E2E: _check_for_errors should produce correctly formatted test results for SKIP test" {
  test() {
    local _file=$1
    local _res_dir=$2
    local _templates_dir=$3
    local _test_status=$4
    local _threshold_file=$5
    run evaluate_test_results_as_junit "$_file" "$_res_dir" "$_templates_dir" "$_threshold_file"
    assert_success
    run cat "$_res_dir/$_test_status"_Should_pass_without_errors_TEST.xml
    assert_success
  }
  test test_data/statistics.no.errors.json results templates PASS test_data/thresholds.any.properties
  test test_data/statistics.json results templates FAILED test_data/thresholds.any.properties
  test test_data/statistics.does.not.exist.json results templates SKIP test_data/thresholds.any.properties
  test test_data/statistics.ugly.chars.json results templates PASS test_data/thresholds.any.properties

}

#metric-based

@test "UT: _get_metric_for_sampler should return correct result gor given metric and sampler" {
  test() {
    local _file=$1
    local _sampler=$2
    local _metric=$3
    local _expected_output=$4
    run _get_metric_for_sampler "$_file" "$_sampler" "$_metric" "$_expected_output"
    assert_output "$_expected_output"
  }
  test test_data/statistics.json "PUT /api/userskills" pct1ResTime 259
  test test_data/statistics.json "TC_Change Additional Skill Competence" meanResTime 228.4967948717948
  test test_data/statistics.ugly.chars.json "Sampler~!@$%^&*()_+" minResTime 65.1
}

@test "UT: _get_any_metric should return correct result gor given metric and should ignore Total sampler" {
  test() {
    local _file=$1
    local _metric=$2
    local _expected_output=$3
    local _index=$4
    run _get_any_metric "$_file" "$_metric" "$_expected_output"
    assert_line --index "$_index" --partial "$_expected_output"
  }
  test test_data/statistics.json errorCount 21 25
  test test_data/statistics.json meanResTime 228.4967948717948 7
  test test_data/statistics.ugly.chars.json errorPct 16.666666 1
  test test_data/statistics.ugly.chars.json errorPct "" 3 #3 is null because it is Total
}

@test "UT: _get_highest_value_for_any_metric should return correct results" {
  run _get_highest_value_for_any_metric test_data/statistics.json pct1ResTime
  assert_output 1103.8
}

#e2e test, UT i IT na _read_thresholds z mockami

@test "E2E: _read_thresholds should produce right JUNIT tests files" {
  run _read_thresholds test_data/thresholds.no.alert.properties test_data/statistics.json results templates
  assert_success
  run cat results/FAILED_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_ANY_TEST.xml
  assert_success
  run cat results/PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_PUT__api_userskills_TEST.xml
  assert_success

  run _read_thresholds test_data/thresholds.ugly.chars.properties test_data/statistics.ugly.chars.json results templates
  assert_success
  run cat results/'PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_'\''Sampler~!@$%^&*()_+'\''_TEST.xml'
  assert_success
}

@test "E2E: _read_thresholds JUNIT files should contain correct details inside" {
  run _read_thresholds test_data/thresholds.no.alert.properties test_data/statistics.json results templates
  run cat results/FAILED_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_ANY_TEST.xml
  assert_output --partial '<system-out>Condition : ANY, metric actual value: 1103.8, max threshold: 1100.5</system-out>'
  assert_output --partial '<failure message="Performance tests failed">Threshold has been breached</failure>'
  run cat results/PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_PUT__api_userskills_TEST.xml
  assert_output --partial '<testcase classname="JMeterTests" name="PASS_Metric_pct1ResTime_should_not_breach_threshold_for_sampler_PUT__api_userskills" time="0" />'
}

@test "UT: _read_thresholds should properly evaluate thresholds for samplers" {
  test(){
      local _value=$1
      local _threshold_file=$2
      local _statistics_file=$3
      local _sampler=$4
      local _expected_status=$5

      _get_highest_value_for_any_metric(){ #stub
        echo "$_value"
     }
      _get_metric_for_sampler(){ #stub
       _get_highest_value_for_any_metric
     }
      export -f _get_highest_value_for_any_metric _get_metric_for_sampler
      run _read_thresholds "$_threshold_file" "$_statistics_file" results templates
      assert_output --partial " -- --> Test for $_sampler has $_expected_status with metric value: $_value"
  }
  test 1001 test_data/thresholds.any.properties test_data/statistics.json ANY failed
  test 99.999 test_data/thresholds.any.properties test_data/statistics.json ANY passed
  test 99.999 test_data/thresholds.no.alert.properties test_data/statistics.json "PUT /api/userskills" passed
  test 299.999 test_data/thresholds.no.alert.properties test_data/statistics.json "PUT /api/userskills" failed

}

@test "UT: _read_thresholds should ignore comments in thresholds file" {
  run _read_thresholds test_data/thresholds.comments.properties test_data/statistics.json results templates
  assert_output ""
}