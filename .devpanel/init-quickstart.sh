#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2021 DevPanel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation version 3 of the
# License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# For GNU Affero General Public License see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------

echo -e "[QUICKSTART] Start attach additional drupal module"

# SKL exit if no MODULE parameter found
if [[ ! -n $DP_MODULE_GIT_URL ]]; then
  exit 0;
fi

# Functions
generate_module_dir()
{
  PROJECT_URL=$1
  # Extract the protocol (includes trailing "://").
  PARSED_PROTO="$(echo $PROJECT_URL | sed -nr 's,^(.*://).*,\1,p')"
  # Remove the protocol from the URL.
  PARSED_URL="$(echo ${PROJECT_URL/$PARSED_PROTO/})"
  # Extract the user (includes trailing "@").
  PARSED_USER="$(echo $PARSED_URL | sed -nr 's,^(.*@).*,\1,p')"
  # Remove the user from the URL.
  PARSED_URL="$(echo ${PARSED_URL/$PARSED_USER/})"
  # Extract the port (includes leading ":").
  PARSED_PORT="$(echo $PARSED_URL | sed -nr 's,.*(:[0-9]+).*,\1,p')"
  # Remove the port from the URL.
  PARSED_URL="$(echo ${PARSED_URL/$PARSED_PORT/})"
  # Extract the path (includes leading "/" or ":").
  PARSED_PATH="$(echo $PARSED_URL | sed -nr 's,[^/:]*([/:].*),\1,p')"
  # Remove the path from the URL.
  PARSED_HOST="$(echo ${PARSED_URL/$PARSED_PATH/})"

  SPLITED_STRING=$(echo $PARSED_PATH | sed 's/\// /g' | xargs)

  declare -a SPLITED_ARR=($SPLITED_STRING)

  echo ${SPLITED_ARR[-1]}
}


#== Install needed tool
if [[ ! -n $(which jq) ]]; then
  echo -e "[QUICKSTART] Install needed tool"
  sudo apt update && sudo apt install -y jq 
fi

# SKL since we've already added the git submodule to the repo, we don't need to do this here.
# MODULE_GIT_URL="https://git.drupalcode.org/project/feeds"
# MODULE_GIT_URL="https://git.drupalcode.org/issue/feeds-3217262.git"

# SKL don't pass the MODULE parameter on GET and the following lines will not run
MODULE_GIT_URL=$DP_MODULE_GIT_URL
MODULE_PATH="$WEB_ROOT/modules/$(generate_module_dir $MODULE_GIT_URL)"

#== Install module using gitsubmodule
git submodule add -f $MODULE_GIT_URL $MODULE_PATH

#== Install dependencies

# requires
cd $MODULE_PATH
REQUIRE=$(jq '."require"' composer.json)

if [[ $REQUIRE != "null" ]]
then
    REQUIRE=$(jq -r '."require" | to_entries[] | .key+":"+.value | strings' composer.json | tr -d ' ' | tr '\n' ' ')
    echo -e "[QUICKSTART] Install dependencies"
    echo -e "COMPOSER_MEMORY_LIMIT=-1 composer require -d $APP_ROOT $REQUIRE \n"

    COMPOSER_MEMORY_LIMIT=-1 composer require -d $APP_ROOT $REQUIRE
fi

# requires-dev
cd $MODULE_PATH
REQUIRE_DEV=$(jq -r '."require-dev" | to_entries[] | .key+":"+.value | strings' composer.json | tr -d ' ' | tr '\n' ' ')

echo -e "[QUICKSTART] Install dev dependencies"
echo -e "COMPOSER_MEMORY_LIMIT=-1 composer require --dev -d $APP_ROOT $REQUIRE_DEV \n"

COMPOSER_MEMORY_LIMIT=-1 composer require --dev -d $APP_ROOT $REQUIRE_DEV
