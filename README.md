# wordpress deployer
It's a bash script that helps to install latest wordpress copy on your linux-based OS.

### How to use: ###

Download and edit file `wordpress_deployer.sh`:
```
sudo vim wordpress_deployer.sh
```

Find and edit this rows(MysqlDB params):

```
DB_NAME="wpdbname"
DB_USER="wpdbuser"
DB_PASSWORD="wpdbpassword"
```

... and this (nginx `server name`)

```
DOMAIN_NAME_OR_IP="192.168.56.101"
```

Make script executable and execute it:
```
sudo chmod +x wordpress_deployer.sh
sudo ./wordpress_deployer.sh
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
* /logs
    * nginx.access.log
    * nginx.error.log
* /www
    * {{ wordpress files }}
* .gitignore
* README.md

### TODO ###

* MysqlDB actions (backup, restore, cron etc.)
* SE-Linux rules
