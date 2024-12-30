#!/bin/bash
sudo apt-get update -y
sudo apt-get install apache2 mysql-server mysql-client php php-mysql libapache2-mod-php -y 
# Destination directory
DEST_DIR="/var/www/html/mompopcafe"

# Check if the destination directory exists
if [ ! -d "$DEST_DIR" ]; then
    # If the directory doesn't exist, create it
    sudo mkdir -p "$DEST_DIR"
    
    # Copy files only if the destination directory was created
    if [ $? -eq 0 ]; then
        sudo cp -rf ./mompopcafe/* "$DEST_DIR/"
        echo "Files copied to $DEST_DIR."
    else
        echo "Failed to create directory $DEST_DIR."
    fi
else
    echo "Directory $DEST_DIR already exists. Skipping copy."
fi
#echo "DocumentRoot /var/www/html/bookalbum" | sudo tee -a  /etc/apache2/sites-available/000-default.conf
#sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/bookalbum|' /etc/apache2/sites-available/000-default.conf
sudo sed -E -i 's|DocumentRoot[[:space:]]+/var/www/html/[^[:space:]]*|DocumentRoot /var/www/html/mompopcafe|' /etc/apache2/sites-available/000-default.conf
sudo systemctl restart apache2

# MySQL credentials
DB_USER="root"
DB_APP_USER="msis"
DB_PASSWORD="Msois@123"
DB_HOST="localhost"
DB_NAME="mom_pop_db"

# SQL script
SQL_SCRIPT="./mompopdb/create-db.sql"

# Execute SQL script using MySQL client
#mysql -h$DB_HOST -u$DB_USER -p$DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
#mysql -h$DB_HOST -u$DB_USER -p$DB_PASSWORD $DB_NAME < $SQL_SCRIPT

# MySQL command to check if the user already exists
CHECK_USER_QUERY="SELECT user FROM mysql.user WHERE user = 'msis';"

# MySQL command to create the user
ALTER_USER_QUERY="ALTER USER 'msis'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Msois@123'";
CREATE_USER_QUERY="CREATE USER IF NOT EXISTS 'msis'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Msois@123';"

# MySQL command to grant privileges to the user
GRANT_PRIVILEGES_QUERY="GRANT ALL PRIVILEGES ON *.* TO 'msis'@'localhost' WITH GRANT OPTION;"

# MySQL command to flush privileges
FLUSH_PRIVILEGES_QUERY="FLUSH PRIVILEGES;"

# Execute MySQL commands
sudo mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "$CHECK_USER_QUERY"
sudo mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "$CREATE_USER_QUERY"

sudo mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "$ALTER_USER_QUERY"
sudo mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "$GRANT_PRIVILEGES_QUERY"
sudo mysql -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "$FLUSH_PRIVILEGES_QUERY"
echo "User 'root' created and granted privileges."

DB_EXISTS=$(mysql -h$DB_HOST -u$DB_USER -p$DB_PASSWORD -e "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='$DB_NAME';" --skip-column-names)

if [ $DB_EXISTS -eq 0 ]; then
    # Create the database if it doesn't exist
    mysql -h$DB_HOST -u$DB_APP_USER -p$DB_PASSWORD -e "CREATE DATABASE $DB_NAME;"
    
    # Execute the SQL script
    mysql -h$DB_HOST -u$DB_APP_USER -p$DB_PASSWORD $DB_NAME < $SQL_SCRIPT
else
    echo "Database $DB_NAME already exists. Skipping creation and SQL script execution."
fi

# Get the IP address of the server
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Echo the message with the IP address
echo "Cafe app is accessible at http://$IP_ADDRESS:80/mompopcafe"
