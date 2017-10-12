#!/bin/bash
yum update -y
yum install mysql -y
service mysql start
chkconfig mysql on
