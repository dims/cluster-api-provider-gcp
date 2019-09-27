#!/bin/bash

# Copyright 2019 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

################################################################################
# usage: e2e.sh
#  This program runs the e2e tests.
################################################################################

set -o nounset
set -o pipefail

BOSKOS_HOST=${BOSKOS_HOST:-"boskos.test-pods.svc.cluster.local."}

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
cd "${REPO_ROOT}" || exit 1

echo "using boskos host to checkout project: ${BOSKOS_HOST}"

# If BOSKOS_HOST is set then acquire an GCP account from Boskos.
# Check out the account from Boskos and store the produced environment
# variables in a temporary file.
account_env_var_file="$(mktemp)"
python hack/checkout_account.py 1>"${account_env_var_file}"
checkout_account_status="${?}"

# If the checkout process was a success then load the account's
# environment variables into this process.
# shellcheck disable=SC1090
[ "${checkout_account_status}" = "0" ] && . "${account_env_var_file}"

# Always remove the account environment variable file. It contains
# sensitive information.
rm -f "${account_env_var_file}"

if [ ! "${checkout_account_status}" = "0" ]; then
  echo "error getting account from boskos" 1>&2
  exit "${checkout_account_status}"
fi

(cd "${REPO_ROOT}" && hack/ci/e2e-conformance.sh)

echo "cleaning up - checking in boskos account $BOSKOS_RESOURCE_NAME on host $BOSKOS_HOST"
hack/checkin_account.py
