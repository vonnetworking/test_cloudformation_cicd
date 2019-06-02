#!/usr/bin/env bash

# @description Retrieval script to find released CFT code in repo, and submit to IaC Pipeline
# @author Robert Fernie
# @email robert_fernie@freddiemac.com
# @noargs

pwd
config=$(dirname $0)/cfg/iac_input.conf
script_dir=$(dirname $0)
owner_script="cft_extract_owner.py"​

echo $owner_script

source $config
if [[ -z "$run_log" ]]; then
  run_log=$(dirname $0)/run.log
fi

function my_log () {
    facility=$1
    message=$2
    printf "[%s %-7s] %s\n" "$(date +'%Y-%m-%d-%H:%M:%S')" "$facility" "$message" >> $run_log
}



# Retreive data for a specified commit, and call the build/submisssion process
function process_commit () {
  current_commit=$1
​
  my_log DEBUG "====COMMIT $current_commit===="
​
  # Generate diff list specific to files that are being merged back into master
  file_list=$(git log -m -1 --first-parent --name-only --pretty="format:" $current_commit | grep -v '^$')
  for commit_file in $file_list; do
    my_log DEBUG "FILE: $commit_file"
    file_path=$(dirname $commit_file)
    file_name=$(basename $commit_file)
    if [[ "$file_path" == "$goldfield_path/landing-zone" ]]; then
      build_submission $file_path $file_name "landing-zone"
    fi
    if [[ "$file_path" == "$goldfield_path/core" ]]; then
      build_submission $file_path $file_name "core"
    fi
  done
}

# For each selected CFT, prepare package and deliver to IaC Pipeline input location
build_submission () {
  file_path=$1
  file_name=$2
  template_type=$3
​
  template_name=$( echo $file_name | sed -e 's/\(.*\)\.yaml/\1/')
  my_log INFO "TEMPLATE: $template_name"
​
  # Skip templates that don't comply
  if [[ "$template_type" == "core" ]] && ! echo $template_name | grep -q 'Core$'; then
    my_log INFO "$template_name does not comply with naming standards for $template_type. Skipping."
    return
  fi
  if [[ "$template_type" == "landing-zone" ]] && ! echo $template_name | grep -q 'LandingZone$'; then
    my_log INFO "$template_name does not comply with naming standards for $template_type. Skipping."
    return
  fi
​
  # If multiple merges are in the queue, a file could have been renamed or removed
  if [[ ! -f $workspace/code_repo/$file_path/$file_name ]]; then
    my_log INFO "template file no longer exists. Skipping."
    return
  fi
​
  # REMOVE THIS -- force inject of fake tests
  mkdir "$workspace/code_repo/$tests_path/$template_name"
  cp $0 "$workspace/code_repo/$tests_path/$template_name/faketest.bash"
  cp $0 "$workspace/code_repo/$tests_path/$template_name/faketest2.py"
  ​
  build_dir=$workspace/$template_name
  rm -rf $build_dir
  mkdir $build_dir
  if [[ ! -d "$build_dir" ]]; then
    my_log ERROR "Failed to create zip dir: $build_dir"
    return
  fi
  #manifest_content="${template_name}.yaml:\n"
  #manifest_content+=" artifact: ${template_name}.zip\n"
  #manifest_content+=" artifact_path: /$template_type\n"
  manifest_content="# manifest file generated for $template_name on $(date -u)\n"
  manifest_content+="# sha256sum, filename, filesize, update-date, update-time\n"
  source_file="$workspace/code_repo/$file_path/$file_name"
  digest=$(sha256sum $source_file | awk '{ print $1 }')
  file_size=$(ls -l $source_file | awk '{ print $5 }')
  owner=$($owner_script $source_file)
  cp $source_file $build_dir
  manifest_content+="$digest, $file_name, $file_size, $(date +"%Y-%m-%d"), $(date +"%H:%S")\n"
  ​
  # dev params
  source_file="$workspace/code_repo/$params_path/${template_name}${dev_params_tail}"
  if [[ -f "$source_file" ]]; then
    target_file="${template_name}.yaml-dev-params-json"
    digest=$(sha256sum $source_file | awk '{ print $1 }')
    file_size=$(ls -l $source_file | awk '{ print $5 }')
    cp -f $source_file $build_dir/$target_file
    #manifest_content+=" dev_params: ${template_name}${dev_params_tail}\n"
    manifest_content+="$digest, $target_file, $file_size, $(date +"%Y-%m-%d"), $(date +"%H:%S")\n"
  else
    my_log WARNING "No dev params for $template_name"
  fi
  ​
  # test params
  source_file="$workspace/code_repo/$params_path/${template_name}${test_params_tail}"
  if [[ -f "$source_file" ]]; then
    target_file="${template_name}.yaml-test-params-json"
    digest=$(sha256sum $source_file | awk '{ print $1 }')
    file_size=$(ls -l $source_file | awk '{ print $5 }')
    cp -f $source_file $build_dir/$target_file
    #manifest_content+=" dev_params: ${template_name}${dev_params_tail}\n"
    manifest_content+="$digest, $target_file, $file_size, $(date +"%Y-%m-%d"), $(date +"%H:%S")\n"
  else
    my_log WARNING "No test params for $template_name"
  fi
  ​
  # bootstrap files
  source_path="$workspace/code_repo/$bootstrap_path/$template_name"
  if [[ -d "$source_path" ]]; then
    mkdir $build_dir/bootstrap
    tar -C $source_path -cf - . | tar -C $build_dir/bootstrap -xf -
  ​
    for bootstrap_file in $(cd $build_dir && find bootstrap -type f); do
      digest=$(sha256sum $build_dir/$bootstrap_file | awk '{ print $1 }')
      file_size=$(ls -l $build_dir/$bootstrap_file | awk '{ print $5 }')
      manifest_content+="$digest, $bootstrap_file, $file_size, $(date +"%Y-%m-%d"), $(date +"%H:%S")\n"
    done
    #manifest_content+=" post-create-tests: ./tests/*\n"
  else
    my_log WARNING "No bootstrap files for $template_name"
  fi
  ​
  # cft post install tests
  source_path="$workspace/code_repo/$tests_path/$template_name"
  if [[ -d "$source_path" ]]; then
    mkdir $build_dir/tests
  ​
    bash_files=$(ls $source_path/*.bash)
    py_files=$(ls $source_path/*.py)
    for test_file in $bash_files $py_files; do
      digest=$(sha256sum $test_file | awk '{ print $1 }')
      file_size=$(ls -l $test_file | awk '{ print $5 }')
      cp $test_file $build_dir/tests
      manifest_content+="$digest, tests/$(basename $test_file), $file_size, $(date +"%Y-%m-%d"), $(date +"%H:%S")\n"
    done
  #manifest_content+=" post-create-tests: ./tests/*\n"
  else
    my_log WARNING "No tests found for $template_name"
  fi
  ​
  if [[ -n "$owner" ]]; then
    owner_file=$build_dir/NOTIFY_LIST.txt
    echo $owner > $owner_file
    digest=$(sha256sum $owner_file | awk '{ print $1 }')
    file_size=$(ls -l $owner_file | awk '{ print $5 }')
    manifest_content+="$digest, $(basename $owner_file), $file_size, $(date +"%Y-%m-%d"), $(date +"%H:%S")\n"
  fi

  #manifest_content+=" git_sha: $current_commit\n"
  #printf "$manifest_content" > $build_dir/manifest.yaml
  printf "$manifest_content" > $build_dir/FILE_MANIFEST.txt
    (cd $build_dir && zip -r $workspace/$template_name .)
    if [[ -f $workspace/${template_name}.zip ]]; then
      my_log INFO "Submitting to ../inputs/${template_name}.zip"
      aws s3 cp $workspace/${template_name}.zip "../inputs/"
    else
      my_log ERROR "zip file $workspace/${template_name}.zip was not generated"
    fi
}

##########################################
########## BEGIN MAIN EXECUTION ##########
##########################################
main () {
  my_log INFO "Starting execution"
  if [[ "$test_mode" == "true" ]]; then
    my_log WARNING "Running in TEST mode"
  fi
  if [[ ! -d "$workspace" ]]; then
    mkdir -p $workspace
  fi
  if [[ ! -d "$workspace" ]]; then
    my_log ERROR "Failed to create workspace directory: $workspace"
  fi

  #git clone $git_url_root/$code_repo $workspace/code_repo
  #if [[ $? -ne 0 ]]; then
  #my_log ERROR "Failed to clone from $git_url_root/$code_repo"
  #exit 1
  #fi
  pwd
  #if [[ ! -f "$owner_script" ]]; then
  #  my_log ERROR "$owner_script is missing"
  #  exit 1
  #fi

  #export GIT_DIR=$workspace/code_repo/.git
  #export GIT_DIR="../.git"​
  if [[ "$test_mode" == "true" ]]; then
    last_submitted_commit=$(cat ${last_checked_commit_file})
  else
    last_submitted_commit=$(cat $last_checked_commit_file)
  fi

  pending_commits=$(git log --reverse --merges --after="$(git show -s --pretty --format="%ci" $last_submitted_commit)" --format="%H" | tail -n +2)

  for current_commit in $pending_commits; do
    process_commit $current_commit
    last_checked_commit=$current_commit
  done
  
  echo "$last_checked_commit" > $last_checked_commit_file
  # if [[ "$cleanup_workspace" == "true" ]]; then
  #   rm -rf $workspace
  # fi
}

main
