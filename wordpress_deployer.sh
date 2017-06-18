#!/bin/bash


DB_NAME="wpdbname"
DB_USER="wpdbuser"
DB_PASSWORD="wpdbpassword"
DB_HOST="localhost"
DB_CHARSET="utf8mb4"
DB_COLLATE="utf8mb4_unicode_ci"

DEFAULT_PROJECT_FOLDER_NAME="project"
DEFAULT_INSTALLATION_PATH="/var/www"
DEFAULT_PROJECT_USER="user"

DOMAIN_NAME_OR_IP="192.168.56.101"

PROJECT_FILES=(
"backups/.gitkeep"
"logs/.gitkeep"
"logs/nginx.access.log"
"logs/nginx.error.log"
"logs/php-fpm.error.log"
"configs/.gitkeep"
"scripts/.gitkeep"
"www/.gitkeep"
)


echo -e "\n\e[32mwordpress deployment script";
echo -e "---------------------------\e[0m";

if [[ $EUID -ne 0 ]]; then
  echo -e "\e[31mError: Must be run as root (root or sudoer user)\e[0m"
  exit 1
fi


# $1 - invitation string , $2 - default value
function read_input {
  read -p "$1" name
  name=${name:-$2}
  echo $name
}

function check_user_exists {
  if id "$1" >/dev/null 2>&1; then
    echo -e "\e[32mUser '$1' exists.\e[0m"
  else
    echo -e "\e[31mError: user '$1' does not exist \e[0m"
    exit 1
  fi
}

function check_group_exists {
  if grep -q -E "^$1:" /etc/group; then
    echo -e "\e[32mGroup '$1' exists.\e[0m"
  else
    echo -e "\e[31mError: group '$1' does not exist \e[0m"
    exit 1
  fi
}

PROJECT_FOLDER_NAME=$(read_input "Specify project folder name(default:$DEFAULT_PROJECT_FOLDER_NAME): " "$DEFAULT_PROJECT_FOLDER_NAME")
INSTALLATION_PATH=$(read_input "Define a path where this folder wil be located (default:$DEFAULT_INSTALLATION_PATH): " "$DEFAULT_INSTALLATION_PATH")
PROJECT_PATH=$INSTALLATION_PATH/$PROJECT_FOLDER_NAME

echo "Project will be installed in $PROJECT_PATH"


PROJECT_USER=$(read_input "Enter user name to set his permission to folder after installation (default: $DEFAULT_PROJECT_USER): " "$DEFAULT_PROJECT_USER")

check_user_exists $PROJECT_USER

PROJECT_GROUP=$(read_input "Enter enter group name (enter - the same as user): " "$PROJECT_USER")

check_group_exists $PROJECT_GROUP

echo "After installation, owner permissions will set to $PROJECT_USER:$PROJECT_GROUP"

echo -e "\e[32mCraeting folders and files:\e[0m"

for PROJECT_FILES_ITEM in "${PROJECT_FILES[@]}"; do
  PROJECT_FILES_ITEM_PATH="$PROJECT_PATH/$PROJECT_FILES_ITEM"
  echo "$PROJECT_FILES_ITEM_PATH"
  mkdir -p "$(dirname "$PROJECT_FILES_ITEM_PATH")" && touch "$PROJECT_FILES_ITEM_PATH"
done;


echo -e "\e[32mConfigure Nginx:\e[0m"
if [[ "$(read_input "Do you want to configure nginx('n' - skip nginx at all)?(Y/n)" "Y")" =~ ^[Yy]$ ]];   then
  echo -e "\e[32mCreating config file.\e[0m"

  NGINX_CONF_FILE="$PROJECT_PATH/configs/${PROJECT_FOLDER_NAME}.nginx.conf"

cat << EOF > "$NGINX_CONF_FILE"
server {

    listen 80;
    server_name $DOMAIN_NAME_OR_IP;

    root $PROJECT_PATH/www;
    index index.php;

    access_log $PROJECT_PATH/logs/nginx.access.log;
    error_log $PROJECT_PATH/logs/nginx.error.log info;
    
    charset utf-8;

    client_max_body_size 20M;

    sendfile off;

    error_page  404              /404.html;
    error_page  400 401 402 403 405 /40x.html;
    error_page  500 502 503 504  /50x.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|txt)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\.  {
        deny all;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }
}
EOF
echo "Done!"

echo -e "\e[32mCreate sym-link to /etc/nginx/sites-enabled/ folder.\e[0m"
ln -s "$NGINX_CONF_FILE" /etc/nginx/sites-enabled/
echo "Done!"

fi


cd $PROJECT_PATH

echo -e "\e[32mDownload and extract lastest wordpress.\e[0m"
wget https://wordpress.org/latest.tar.gz
tar zxvf latest.tar.gz 1>/dev/null
mv $PROJECT_PATH/wordpress/* $PROJECT_PATH/www
rm latest.tar.gz
rm -rf $PROJECT_PATH/wordpress

echo "Done!"

echo -e "\e[32mConfigure Wordpress.\e[0m"
cp $PROJECT_PATH/www/wp-config-sample.php $PROJECT_PATH/www/wp-config.php
echo "Done!"


echo -e "\e[32mMySQL Tables.\e[0m"
mysql -u root -p -uroot -e "DROP DATABASE IF EXISTS ${DB_NAME}; CREATE DATABASE ${DB_NAME} CHARACTER SET ${DB_CHARSET} COLLATE ${DB_COLLATE};"
mysql -u root -p -uroot -e "CREATE USER ${DB_USER}@${DB_HOST} IDENTIFIED BY '${DB_PASSWORD}';GRANT ALL ON ${DB_NAME}.* TO ${DB_USER}@${DB_HOST} IDENTIFIED BY '${DB_PASSWORD}';FLUSH PRIVILEGES;"
echo "Done!"


#echo -e "\e[32mConfigure Wordpress.\e[0m"
#sed -i s/database_name_here/$DB_NAME/g $PROJECT_PATH/www/wp-config.php
#sed -i s/username_here/$DB_USER/g $PROJECT_PATH/www/wp-config.php
#sed -i s/password_here/$DB_PASSWORD/g $PROJECT_PATH/www/wp-config.php
#sed -i s/localhost/$DB_HOST/g $PROJECT_PATH/www/wp-config.php
#sed -i s/utf8/$DB_CHARSET/g $PROJECT_PATH/www/wp-config.php
#echo "Done!"

echo -e "\e[32mSet user:group permission to project folder.\e[0m"
chown $PROJECT_USER:$PROJECT_GROUP -R $PROJECT_PATH
echo "Done!"


echo -e "\e[32mRestart nginx and php-fpm.\e[0m"
service nginx restart
service php-fpm restart
echo "Done!"
