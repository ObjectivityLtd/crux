#!/bin/bash
setVARS() {
  ip=$(hostname -i)
  sts_name=simple-table-server.sh
  test_dir=/test
}
waitForSTS() {
  http_code=666
  sleepSec=2
  until [ "$http_code" == "200" ]; do
    printf "\n\t Waiting for STS ... $sleepSec s"
    sleep $sleepSec
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$ip:9191/sts/INITFILE?FILENAME=google.csv)
    printf "\t\nHTTP Status: $http_code"
  done
}
killScript(){
  script=$1
  kill -9 $(pidof -x "$script") > /dev/null 2>&1
}
killSTS(){
  killScript $sts_name
}
startSTS(){
  #for some reason nohup is no go perhaps SIGHUP is overwritten
  screen -A -m -d -S sts /jmeter/apache-jmeter-*/bin/$sts_name -DjmeterPlugin.sts.addTimestamp=true -DjmeterPlugin.sts.datasetDirectory=/$test_dir &
}
runJMeterTest(){
  local jmx=$1
  shift 1
  local fixed_args="-Gsts=$ip -Gchromedriver=/usr/bin/chromedriver -q /$test_dir/user.properties -Dserver.rmi.ssl.disable=true"
  sh /jmeter/apache-jmeter-*/bin/jmeter.sh -n -t /$test_dir/$jmx $@ $fixed_args -R $(getent ahostsv4 jmeter-slaves-svc | cut -d' ' -f1 | sort -u | awk -v ORS=, '{print $1}' | sed 's/,$//')

}
runTestWithSTS(){
  setVARS
  killSTS
  startSTS
  waitForSTS
  runJMeterTest "$@"
  killSTS
}
runTestWithSTS "$@"
