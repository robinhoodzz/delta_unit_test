#!/bin/bash
####################################################
# this is unit test script
# run delta files when current branch is non master
# run all files when current branch is master
# Step0: init variables
# Step1: check is master branch or not, if master run all test cases and return test result, if not run following
# Step2: get all changed file paths from master (git diff master)
# Step3: convert full paths to dirs
# Step4: duplicate dirs
# Step5: run test from changed dirs one by one, if return code is not 0, return the code
# Step6: all cases passed, return 0
####################################################

# Step0
#current_branch=`git rev-parse --abbrev-ref HEAD`
echo "[script] input MED_BRANCH is: $1"
current_branch=$1
master_branch="master"
changed_files=`git diff $master_branch --name-only`
declare -a changed_dirs # array of changed dirs
echo "[script] current branch is: $current_branch"
touch profile.cov # pipeline will read the file finally, if no go file changed, pipeline failed since not file exist

# Step1
if [ $current_branch = $master_branch ]
then
  go test -v -failfast -coverprofile=profile.cov ./...
  exit $?
fi
echo "[script] changed files are: ${changed_files[@]}"

# Step2
for f in ${changed_files[@]}
do
  is_contain_no_test_go=$(echo $f | grep .go | grep .pb.go -v) # find .go file except _test.go or .pb.go since no test file in those dirs
  if [ "$is_contain_no_test_go" != "" ]
  then
    path="${f%/*}" # Step3 convert full paths to dirs
    changed_dirs=("${changed_dirs[@]}" "$path")
  fi
done
echo "[script] changed dirs are: ${changed_dirs[@]}"

# Step4
changed_unique=($(echo "${changed_dirs[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
echo "[script] distinct changed dirs are: ${changed_unique[@]}"

# Step5
for f in ${changed_unique[@]}
do
  go test -v -failfast -coverprofile=profile.cov "./$f"
  if [ $? != 0 ]
  then
    exit $?
  fi
done
echo "[script] non master branch all test cases are passed!"

