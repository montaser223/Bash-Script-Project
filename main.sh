#!/bin/bash
DIR="/home/$USER/DBMS"
echo "Welcome To DBMS"
#This function check user has directory to put DB on it or not
function checkDir() {
  if [ ! -d $DIR ]; then
    mkdir /home/$USER/DBMS
  fi
}
#Call checkDir function
checkDir
#This function Dispaly DataBase Menu
function mainMenu() {
  echo -e "\n+---------Main Menu-------------+"
  echo "| 1. Open DB                    |"
  echo "| 2. Create DB                  |"
  echo "| 3. Drop DB                    |"
  echo "| 4. List DBs                   |"
  echo "| 5. Exit                       |"
  echo "+-------------------------------+"
  echo -e "Enter Choice: \c"
  read ch
  case $ch in
  1) selectDB ;;
  2) createDB ;;
  3) dropDB ;;
  4) listDB ;;
  5)
    echo BYE
    exit
    ;;
  *)
    echo " Wrong Choice "
    mainMenu
    ;;
  esac
}
#This function Open specific DB
function selectDB() {
  echo -e "Enter Database Name: \c"
  read dbName
  if [[ -d $DIR/$dbName ]]; then
    echo "Database $dbName was Successfully Selected"
    ./tables.sh $DIR/$dbName
  else
    echo "Database $dbName wasn't found"
    mainMenu
  fi
}
#This function Create new DB
function createDB() {
  echo -e "Enter Database Name: \c"
  read -a db
  ELEMENTS=${#db[@]}
  if [[ $ELEMENTS == 1 ]]; then
    if [[ ${db[0]} =~ ^[A-Za-z_]+ ]]; then
      dbName=${db[0]}
      if [[ -d $DIR/$dbName ]]; then
        echo "DataBase already existed ,choose another name"
        mainMenu
      else
        mkdir $DIR/$dbName
        if [[ $? == 0 ]]; then
          echo "Database Created Successfully"
        else
          echo "Error Creating Database $dbName"
        fi
      fi
    else
      echo "DB name shouldn't contain any special charcter except '_' "
    fi
  else
    echo "It isn't allowed to use spaces in Database name "
  fi
  mainMenu
}

function dropDB() {
  echo -e "Enter Database Name: \c"
  read dbName
  rm -r $DIR/$dbName 2>>./.error.log
  if [[ $? == 0 ]]; then
    echo "Database Dropped Successfully"
  else
    echo "Database Not found"
  fi
  mainMenu
}
#This function List all avilable DB
function listDB() {

  if [[ "$(ls $DIR | egrep -v '^f')" ]]; then
    ls $DIR | egrep -v '^f'
  else
    echo "No Avilable Databases"
  fi
  mainMenu
}
# Call DB menu
mainMenu
