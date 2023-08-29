#!/bin/bash

set -e
base=$(cd $(dirname $0); pwd)

source $base/lambda-deploy.sh

initialize
create_lambda_zip
