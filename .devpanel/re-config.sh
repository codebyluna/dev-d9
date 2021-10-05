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

STATIC_FILES_PATH="$WEB_ROOT/sites/default/files/"
SETTINGS_FILES_PATH="$WEB_ROOT/sites/default/settings.php"

#Create static directory
if [ ! -d "$STATIC_PATH" ]; then
  mkdir -p $STATIC_FILES_PATH
fi

#== Extract static files
if [[ -f "$APP_ROOT/.devpanel/dumps/files.tgz" ]]; then
  tar xzf "$APP_ROOT/.devpanel/dumps/files.tgz" -C $STATIC_FILES_PATH
fi
#== Import mysql files
if [[ -f "$APP_ROOT/.devpanel/dumps/db.sql.tgz" ]]; then
  SQLFILE=$(tar tzf $APP_ROOT/.devpanel/dumps/db.sql.tgz)
  tar xzf "$APP_ROOT/.devpanel/dumps/db.sql.tgz" -C /tmp/
  sed -e 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' -i /tmp/$SQLFILE
  mysql -h$DB_HOST -u$DB_USER -p$DB_PASSWORD $DB_NAME < /tmp/$SQLFILE
  rm /tmp/$SQLFILE
fi

#== Composer install.
if [[ -f "$APP_ROOT/composer.json" ]]; then
  cd $APP_ROOT && composer install
fi
if [[ -f "$WEB_ROOT/composer.json" ]]; then
  cd $WEB_ROOT && composer install
fi

#== Run quickstart script
if [[ -f "$APP_ROOT/.devpanel/init-quickstart.sh" ]]; then
  $APP_ROOT/.devpanel/quickstart.sh
fi

cd $WEB_ROOT && git submodule update --init --recursive

#== Create settings files
# @link: https://www.drupal.org/docs/7/install/step-3-create-settingsphp-and-the-files-directory
if [[ ! -f "$SETTINGS_FILES_PATH" ]] || [[ $(git check-ignore "$SETTINGS_FILES_PATH") ]]; then
  sudo mv $SETTINGS_FILES_PATH $SETTINGS_FILES_PATH.old
  
  sudo cp $APP_ROOT/.devpanel/drupal9-settings.php $SETTINGS_FILES_PATH
fi

sudo chown www:www-data $SETTINGS_FILES_PATH
sudo chmod 664 $SETTINGS_FILES_PATH

# #Securing file permissions and ownership
# #https://www.drupal.org/docs/security-in-drupal/securing-file-permissions-and-ownership
[[ ! -d "$WEB_ROOT/sites/default/files" ]] && mkdir --mode 775 "$WEB_ROOT/sites/default/files" || sudo chmod 775 -R "$WEB_ROOT/sites/default/files"
chown -R www:www-data .

if [[ ! -z "$DRUPAL_HASH_SALT" ]]; then

  cat <<EOF >>$WEB_ROOT/sites/default/settings.php
\$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT');
EOF

else
  echo "DRUPAL_HASH_SALT environment is not set, Random new hash salt..."
  cat <<EOF >>$WEB_ROOT/sites/default/settings.php
\$settings['hash_salt'] = "$(openssl rand -base64 32)";
EOF

fi
