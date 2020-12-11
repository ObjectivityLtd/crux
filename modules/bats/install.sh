#!/usr/bin/env bash

#we can install that on the fly for CI systems or we can add this in docker image
function installBATS() {
  clear && rm -rf $HOME/test/test_helper/bats*
  git clone --depth 1 --branch v1.2.1 https://github.com/bats-core/bats-core $HOME/test/test_helper/bats-core
  git clone https://github.com/ztombol/bats-assert $HOME/test/test_helper/bats-assert
  git clone https://github.com/ztombol/bats-support $HOME/test/test_helper/bats-support
  cd $HOME/test/test_helper/bats-core && ls && ./install.sh $HOME
}
installBATS
