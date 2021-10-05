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

#== If webRoot has not been difined, we will set appRoot to webRoot
if [[ ! -n "$WEB_ROOT" ]]; then
  export WEB_ROOT=$APP_ROOT
fi

#== Composer install.
if [[ -f "$APP_ROOT/composer.json" ]]; then
  cd $APP_ROOT && composer install;
fi
if [[ -f "$WEB_ROOT/composer.json" ]]; then
  cd $WEB_ROOT && composer install;
fi

#== Run quickstart script
if [[ -f "$APP_ROOT/.devpanel/init-quickstart.sh" ]]; then
  $APP_ROOT/.devpanel/init-quickstart.sh
fi

cd $WEB_ROOT && git submodule update --init --recursive

# #Securing file permissions and ownership
# #https://www.drupal.org/docs/security-in-drupal/securing-file-permissions-and-ownership
[[ ! -d "$WEB_ROOT/sites/default/files" ]] && mkdir --mode 775 "$WEB_ROOT/sites/default/files"
chown -R www:www-data .;

#== Use Drush to create site installed
drush -y site-install standard --account-name=$DRUPAL_ADMIN --account-pass=$DRUPAL_ADMINPWD --db-url=mysql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME;