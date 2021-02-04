#!/bin/bash
DIR=$1

shopt -s extglob
export LC_COLLATE=C

PS3="Choose Number: "
#This function Dispaly Table Menu
function tablesMenu() {
    echo -e "\n+-----------Tables Menu------------+"
    echo "| 1. List Tables                   |"
    echo "| 2. Open Table                    |"
    echo "| 3. Create Table                  |"
    echo "| 4. Drop Table                    |"
    echo "| 5. Show Table content            |"
    echo "| 6. Back to main menu             |"
    echo "| 7. Exit                          |"
    echo "+----------------------------------+"
    echo -e "Enter Choice: \c"
    read ch
    case $ch in
    1) listTable ;;
    2) selectTable ;;
    3) createTable ;;
    4) dropTable ;;
    5) showTable ;;
    6)
        clear
        source $(pwd)/main.sh
        mainMenu
        ;;
    7)
        echo BYE
        exit
        ;;
    *)
        echo " Wrong Choice "
        tablesMenu
        ;;
    esac
}
#This function List all existing tables in specicfic DB
function listTable() {

    if [ "$(ls $DIR)" ]; then
        ls $DIR | egrep -v '^d'
    else
        echo "No Avilable Tables"
    fi
    tablesMenu
}
#This function delete table from specicfic DB
function dropTable() {
    echo Enter Table Name:
    read tname
    if [ -f $DIR/$tname ]; then
        #rm $DIR/$tname 2>>./.error.log
        rm $DIR/$tname
        rm $DIR/.$tname
        echo "Table deleted successfully"
    else
        echo "Table doesn't exist"
    fi
    tablesMenu
}
#This function dispaly table content
function showTable() {
    echo Enter Table Name:
    read tname
    if [ -f $DIR/$tname ]; then
        column -t -s '|' $DIR/$tname
    else
        echo "Table doesn't exist"
    fi
    tablesMenu

}
#This function open specicfic table in specicfic DB
function selectTable() {
    echo Enter Table Name:
    read tname
    if [ -f $DIR/$tname ]; then
        ./operations.sh $DIR $tname
    else
        echo "Table doesn't exist"
        tablesMenu
    fi

}
#This function Create new table in specicfic DB
function createTable() {
    echo -e "Table Name: \c"
    read -a table
    ELEMENTS=${#table[@]}
    if [[ $ELEMENTS == 1 ]]; then
        if [[ ${table[0]} =~ ^[A-Za-z_]+ ]]; then
            tableName=${table[0]}
            if [[ -f $DIR/$tableName ]]; then
                echo "table already existed ,choose another name"
                tablesMenu
            fi
            echo -e "Number of Columns: \c"

            counter=1
            sep="|"
            rSep="\n"
            pKey=""
            temp=""
            metaData="Field"$sep"Type"$sep"key"
            flag=true
            exist=true
            while $flag; do
                read colsNum

                case $colsNum in

                +([1-9]))
                    flag=false

                    ;;
                *)
                    echo "invalid input number"
                    echo -e "Number of Columns: \c"
                    ;;
                esac

            done
            declare -a arr
            let len=0
            while [ $counter -le $colsNum ]; do
                echo -e "Name of Column No.$counter: \c"
                read colName
                for i in ${arr[*]}; do
                    if [[ $i == $colName ]]; then
                        echo "Invalid Colunmn Name"
                        continue 2
                    fi
                done
                if [[ $colName =~ ^[A-Za-z_]+ ]]; then

                    echo -e "Type of Column $colName: "

                    select var in "int" "str"; do
                        case $var in
                        int)
                            colType="int"
                            break
                            ;;
                        str)
                            colType="str"
                            break
                            ;;
                        *) echo "Wrong Choice" ;;
                        esac
                    done
                    if [[ $pKey == "" ]]; then
                        echo -e "Make PrimaryKey ? "
                        select var in "yes" "no"; do
                            case $var in
                            yes)
                                pKey="PK"
                                metaData+=$rSep$colName$sep$colType$sep$pKey
                                break
                                ;;
                            no)
                                metaData+=$rSep$colName$sep$colType$sep""
                                break
                                ;;
                            *) echo "Wrong Choice" ;;
                            esac
                        done
                    else
                        metaData+=$rSep$colName$sep$colType$sep""
                    fi
                    if [[ $counter == $colsNum ]]; then
                        temp=$temp$colName
                    else
                        temp=$temp$colName$sep
                    fi
                    ((counter++))
                else
                    echo "Colunmn name shouldn't contain any special charcter except '_' "
                fi
                arr[$len]=$colName
                ((len++))
            done

            touch $DIR/$tableName
            echo -e $metaData >>$DIR/.$tableName
            check=true
            res=$(grep PK $DIR/.$tableName | cut -d '|' -f3)
            if [[ $res == "PK" ]]; then
                :
            else
                while $check; do
                    echo -e "You Should detect PrimaryKey for table \n"
                    echo -e "Enter colunm number to assign PrimaryKey: \c"
                    read var
                    if [[ $var == $colsNum || $var -le $colsNum ]]; then
                        check=false
                        echo -e "New Meta Data for $tableName :\n"
                        gawk -i inplace -F "|" '{if(NR==('$var'+1)) sub("|", "PK", $3);print $0}' OFS="|" $DIR/.$tableName
                        awk -F "|" '{print $0}' OFS="|" $DIR/.$tableName
                    else
                        echo "invalid colunm number"
                    fi
                done
            fi
            touch $DIR/$tableName
            echo -e $temp >>$DIR/$tableName
            if [[ $? == 0 ]]; then
                echo "Table Created Successfully"
                tablesMenu
            else
                echo "Error Creating Table $tableName"
                tablesMenu
            fi
        else
            echo "Table name shouldn't contain any special charcter except '_' "
            tablesMenu
        fi
    else
        echo "It isn't allowed to use spaces in Tables name "
        tablesMenu
    fi
}
#Call Table menu
tablesMenu
