# wordpress deployer
It's a bash script that helps to install latest wordpress copy on your linux-based OS.

### HOW TO USE: ###

Set your own params (read below), make script executable and run it:
```
git clone git@github.com:ti-tar/wordpress_deployer.git 
cd wordpress_deployer
sudo chmod +x wordpress_deployer.sh
sudo ./wordpress_deployer.sh
```
During installation command line will ask you to enter mysql root pass twice (database creation and to set user privileges).
After installation, open browser and go to domain/ip you've set.
Everything should work as well.


### Set params: ###

Edit file `wordpress_deployer.sh`:
```
sudo vim wordpress_deployer.sh
```

Find and edit this rows(MysqlDB params). You don't have to create it, DB creation and user/privileges will set up automatically. Just make sure your Mysql is running and you have root-password.

```
DB_NAME="wpdbname"
DB_USER="wpdbuser"
DB_PASSWORD="wpdbpassword"
```

Set nginx `server name` :

```
DOMAIN_NAME_OR_IP="192.168.56.101"
```

You may need to change nginx/php-fpm:

```
NGINX_FOLDER="/etc/nginx"
PHPFPM_FOLDER="/usr/local/php7/etc"
```

### Requirements: ###
1. LEMP Stack installed ( Linux(tested on CentOS7/Ubuntu14.04), Nginx, MySQL(MariaDB), PHP)
2. Internet connection
 
### Folder Structure: ###
 
{{project}}
* /backups
    * .gitkeep
* /scripts
    * .gitkeep
* /configs
    * {{project}}.nginx.conf
    * {{project}}.php-fpm.conf
* /logs
    * nginx.access.log
    * nginx.error.log
    * php-fpm.error.log
* /www
    * {{ wordpress files }}
* .gitignore
* README.md

### TODO ###

* MysqlDB actions (backup, restore, cron etc.)
* SE-Linux rules
