#!/bin/bash

shopt -s extglob
export LC_COLLATE=C

DB=$1
DIR=$1/$2
metaData=.$2

if [[ ! -f $DB/.update ]]; then
	touch $DB/.update
fi
#This function Dispaly operation Menu
function operationsMenu() {
	echo -e "\n+----------Operations Menu---------+"
	echo "| 1. Select Specific Record        |"
	echo "| 2. Select All Record             |"
	echo "| 3. Insert Record                 |"
	echo "| 4. Update Table                  |"
	echo "| 5. Delete Record                 |"
	echo "| 6. Back                          |"
	echo "| 7. Exit                          |"
	echo "+----------------------------------+"
	echo -e "Enter Choice: \c"
	read ch
	case $ch in
	1) selectRecord ;;
	2) selectAllRecord ;;
	3) insertRecord ;;
	4) update ;;
	5) deleteFromTable ;;
	6)
		clear
		source $(pwd)/tables.sh $DB
		tablesMenu
		;;
	7)
		echo BYE
		exit
		;;
	*)
		echo " Wrong Choice "
		operationsMenu
		;;
	esac
}
#This function update specific record 
function update() {
	echo -e "Enter your condition name: \c"
	read cond
	cfid=$(awk -v c="$cond" -F "|" ' {for(i=1;i<=NF;i++){if($i==c){ print i }} }' $DIR)
	if [[ $cfid == "" ]]; then
		echo "condition $cond not found"
		operationsMenu
	else
		echo -e "Enter your condition value: \c"
		read cVal
		data=$(awk -v val="$cVal" -F "|" '{for(i=1;i<=NF;i++){ if(val == $i){print $i}} }' $DIR)
		if [[ $data == "" ]]; then
			echo "there is no record match your value"
			operationsMenu
		else
			echo -e "Enter your column name to update: \c"
			read column
			record=$(awk -v c="$column" -F "|" ' {if(NR != 1){for(i=1;i<=NF;i++){ if( c == $i ) {print NR} }} }' $DB/$metaData)
			rfid=$(awk -v c="$column" -F "|" ' {for(i=1;i<=NF;i++){if($i==c){ print i }} }' $DIR)
			if [[ $record == "" ]]; then
				echo "column $column not found"
				operationsMenu
			else
				record=$(awk -v rec="$record" -F "|" ' {if(NR == rec) print $0}' $DB/$metaData)
				dataType=$(echo $record | cut -d"|" -f2)
				validate=$(echo $record | cut -d"|" -f3)
				if [[ $validate == "PK" ]]; then
					echo -e "You won't able to update Primary Key \c"
					operationsMenu
				else
					echo -e "Enter new value: \c"
					if [[ $dataType == "int" ]]; then
						flag=true
						while $flag; do
							read newVal

							case $newVal in

							+([0-9]))
								flag=false
								;;
							"")
								flag=false
								;;
							*)
								echo "invalid input number"
								echo -e "Enter new value: \c"
								;;
							esac

						done
					elif [[ $dataType == "str" ]]; then
						echo -e "Enter new value: \c"
						read newVal
					fi
				fi
				awk -v cond="$cfid" -v newValue="$newVal" -v recID="$rfid" -v cvalue="$cVal" -F "|" 'BEGIN{ OFS = "|" } {if($cond == cvalue){ $recID = newValue } print $0 }' $DIR >$DB/.update
				newVal=""
				column=""
				cVal=""
				cond=""
				if [[ $? == 0 ]]; then
					cat $DB/.update >$DIR
					echo -e "Table Updated Successfully \c"
				else
					echo -e "error while update records \c"
					operationsMenu
				fi

			fi
		fi

	fi
	operationsMenu
}
#This function dispaly specific record 
function selectRecord() {
	echo -e "Enter Record Number: \c"
	read RecordNUMBER
	if [[ $RecordNUMBER > 0 ]]; then
		res=$(awk -F "|" '{if(NR==('$RecordNUMBER'+1) && NR != 0) print $0}' $DIR | column -t -s '|')
		if [[ $res == "" ]]; then
			echo "There is no record match your value"
			operationsMenu
		else
			awk -F "|" '{if(NR==1) print $0}' $DIR | column -t -s '|' #dispaly column name
			echo $res
		fi
		operationsMenu
	else
		echo "There is no record match your value"
		operationsMenu
	fi
}
#This function dispaly all records in table 
function selectAllRecord() {
	column -t -s '|' $DIR
	operationsMenu

}
#This function delete specific record from table
function deleteFromTable() {
	echo -e "Enter Condition Column name: \c"
	read field
	fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $DIR)
	if [[ $fid == "" ]]; then
		echo "Not Found"
		operationsMenu
	else
		echo -e "Enter Condition Value: \c"
		read val
		res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $DIR 2>>./.error.log)
		if [[ $res == "" ]]; then
			echo "Value Not Found"
			operationsMenu
		else
			NR=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print NR}' $DIR 2>>./.error.log)
			sed -i ''$NR'd' $DIR 2>>./.error.log
			echo "Row Deleted Successfully"
			operationsMenu
		fi
	fi
}
#This function insert new record to table
function insertRecord() {
	recordes=$(wc -l $DB/$metaData | cut -d" " -f1)
	((recordes = recordes - 1))
	index=1
	for var in $(awk -F " " '{if(NR != 1){ print $0 }}' $DB/$metaData); do
		col=$(echo $var | cut -d"|" -f1)
		dataType=$(echo $var | cut -d"|" -f2)
		validate=$(echo $var | cut -d"|" -f3)
		sep="|"
		echo -e "Enter $col: \c"
		if [[ $validate == "PK" ]]; then
			if [[ $dataType == "int" ]]; then
				flag=true

				while $flag; do
					read data

					case $data in

					+([0-9]))
						test=$(awk -v pk="$col" -F "|" '{for(i=1;i<=NF;i++){ if(pk == $i){print i}} }' $DIR)
						flag=false
						for primaryKey in $(awk -v f="$test" -F "|" '{print $f}' $DIR); do
							if [[ $data == $primaryKey ]]; then
								echo "$col already exist"
								flag=true
								echo -e "Enter $col: \c"
							fi
						done
						;;
					"")
						echo "$col is required"
						echo -e "Enter $col: \c"
						;;
					*)
						echo "invalid input number"
						echo -e "Enter $col: \c"
						;;
					esac

				done
			elif [[ $dataType == "str" ]]; then

				flag=true
				while $flag; do
					read data

					test=$(awk -v pk="$col" -F "|" '{for(i=1;i<=NF;i++){ if(pk == $i){print i}}}' $DIR)
					flag=false
					for primaryKey in $(awk -v f="$test" -F "|" '{print $f}' $DIR); do
						if [[ $data == $primaryKey ]]; then
							echo "$data in $col already exist"
							flag=true
							echo -e "Enter $col: \c"
						fi
					done
				done
			fi
		else
			if [[ $dataType == "int" ]]; then
				flag=true
				while $flag; do
					read data

					case $data in

					+([0-9]))
						flag=false
						;;
					"")
						flag=false
						;;
					*)
						echo "invalid input number"
						echo -e "Enter $col: \c"
						;;
					esac

				done
			elif [[ $dataType == "str" ]]; then
				flag=true
				sep="|"
				while $flag; do
					read data
					if [[ "$data" == *"$sep"* ]]; then
						flag=true
						echo "invalid input string"
						echo -e "Enter $col: \c"

					else
						flag=false
					fi

				done

			fi
		fi
		if [[ $index == $recordes ]]; then
			temp+=$data
		else
			temp=$data$sep
		fi
		((index++))
	done
	echo -e $temp >>$DIR
	echo -e "Table Updated Successfully \c"
	operationsMenu

}
#Call operations Menu 
operationsMenu
