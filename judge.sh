#bin/bash
###### Configre ######
# testbench folder name
default="F740XXXXX"
testbench="src"
code_file="CPU.v"

# success string(please modify testbench succes to random string to prevent fake success)
# remember remove file that student should write
# you also should edit testbench to concate score before judge_str
# EX: 100 b21erhb
judge_str="b21erhb4g3"

# folder for arrange
operation_dir="arranged"

# code which student must write (regex)
student_code="module \<CPU\>"
# string for check code location
file_path="$testbench/$code_file"
# search default report file exist
report_file="report.docx"

# execute command(in student folder)
judge () {
	cp "$cur_path/pre_sim.tcl" .
	vsim -c -do "do ./pre_sim.tcl top_tb"
	#tb='traffic_light_tb.v'
	#irun $tb $(find . -type f ! -name $tb -and -name "*.v" -print) +nc64bit
}

###### You may not need to edit bellow except the score method changed ######
# store current pos
cur_path="$(pwd)"
# basic csv format
echo '學號,成績,評語回饋' > $cur_path/result.csv
echo '學號' > $cur_path/wrong_path.csv
echo '學號,原因' > $cur_path/no_report.csv
# basic init(rm default code, create dir) 
rm -f $default/$testbench/$code_file
mkdir -p $operation_dir
operation_dir="$(pwd)/$operation_dir"
# loop every student folderm
for dir in $cur_path/*/ ; do
	# ignore default directory
	if ! [[ $dir -ef $cur_path/$default/ ]] ; then
		cd "$dir"
		echo -n "entering $dir... "
		# cut student id & check is valid id
		id=$(grep -Eo '[A-Z][0-9A-Z][0-9]{7}' <<<$dir)
		[ -z "$id" ] && echo -e "\033[0;31m ignore non student directory: $dir\033[0m" && continue
		
		# unzip
		unzip -oq *.zip
		chmod -R +rw ./*

		# find source code
		src_code="$(find . -type f -name "*.v" -print0 | xargs -0 grep -l "$student_code" | head -1)"
		mkdir -p $operation_dir/$id

		# copy other possible src files
		cp "$(dirname "$src_code")/"* -rt "$operation_dir/$id/"
		# go to source code location
		cd "$operation_dir/$id"
		# add(replace) testbench
		cp "$cur_path/$default/$testbench/"* -rt .

		# judge
		output=$(judge)
		score=$(echo "$output" | grep -Eo "[0-9]+ $judge_str" | cut -d ' ' -f 1)
		[ -z "$score" ] && score=0

		# give last line as log FIXME: irun
		log=$(echo "$output" | tail -n1 | grep "irun:") 
		# compare actual path they should put, -10 if not
		if [ ! -f "$dir$id/$file_path" ] ;then
			#score=$(expr $score - 10)
			echo $id >> "$cur_path/wrong_path.csv"
		fi
		# check report exist and compare report
		report=$(find "$dir" -name "$report_file")
		if [[ -z $report ]] ;then
			echo $id >> "$cur_path/no_report.csv"
		elif [ "$(diff "$report" "$cur_path/$default/$report_file")" == "" ] ;then
			echo "$id,same report" >> "$cur_path/no_report.csv"
		else score=$(expr $score + 20)
		fi
		# result
		echo "score: $score"
		echo "$id,$score,$log" >> $cur_path/result.csv
	fi
done
exec bash
