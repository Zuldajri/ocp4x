#!/bin/bash

echo $(date) " - Starting Master Script"

ADMIN_USER=$1

echo $USER >> /home/$ADMIN_USER/test
