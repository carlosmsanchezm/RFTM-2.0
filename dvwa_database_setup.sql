-- dvwa_database_setup.sql
CREATE DATABASE IF NOT EXISTS dvwa;
CREATE USER 'dvwaUser'@'%' IDENTIFIED BY 'dvwaPassword';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwaUser'@'%';
FLUSH PRIVILEGES;
