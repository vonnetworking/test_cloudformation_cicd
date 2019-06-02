#!/usr/bin/env bash

################################################################################
### _jenkins_setup_workspace.sh
###
### Description: simply removes remnants of prior builds and cleans up the ws
###              insuring that results aren't tainted by previous runs
###              this should be redundant to the cleanup step of the pipeline
###              but based on some strange behaviors, repeating the steps is not
###              a terrible idea
###
###   ::PARAMS::
###     No params required
################################################################################

rm -rf build_artifacts
mkdir build_artifacts

rm -rf reports
mkdir reports

rm -rf stage
mkdir stage

rm -rf sync
mkdir sync

rm -rf cfnlint-tmp
mkdir cfnlint-tmp

rm -rf *.out
