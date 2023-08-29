#!/bin/bash

set -e

source $(cd $(dirname $0); pwd;)/lambda-deploy.sh

initialize
create_lambda_zip
update_lambda_function