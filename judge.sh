#bin/bash
###### Configre ######
# testbench folder name
default="F740XXXXX"
testbench="src"
code="traffic_light.v"

# success string(please modify testbench succes to random string to prevent fake success)
# remember remove file that student should write
# you also should edit testbench to concate score before judge_str
# EX: 100 b21erhb
judge_str="b21erhb4g3"

# folder for anti-cheat
cheat_dir="check_cheat"

#FIXME: current auto get into student module location(:57-63)
# model name which student write 
module_name="traffic_light"
# string for check code location
file_path="$testbench/$code"
# search default report file exist
report_file="report.docx"

# execute command(in student folder) FIXME: should run on modelsim
judge () {
	# cd ./src
	tb='traffic_light_tb.v'
	# vsim -c -do ./pre_sim.tcl
	irun $tb $(find . -type f ! -name $tb -and -name "*.v" -print) +nc64bit
}

###### You may not need to edit bellow ######
# store current pos
cur_path="$(pwd)"
# basic csv format
echo '學號,成績,評語回饋' > $cur_path/result.csv
echo '學號' > $cur_path/wrong_path.csv
echo '學號' > $cur_path/no_report.csv
# basic init(rm default code, create dir) FIXME :current only fit for CO homework
rm -f $default/$testbench/$code
mkdir -p $cheat_dir
cheat_dir="$(pwd)/$cheat_dir"
# loop every student folderm
for dir in $cur_path/*/ ; do
	# ignore default directory
	if ! [[ $dir -ef $cur_path/$default/ ]] ; then
		cd "$dir"
		echo "entering $dir"
		# cut student id & check is valid id
		id=$(grep -Eo '[A-Z][0-9A-Z][0-9]{7}' <<<$dir)
		[ -z "$id" ] && echo -e "\033[0;31m ignore non student directory: $dir\033[0m" && continue
		
		# unzip ,TODO check folder format
		unzip -oq *.zip

		# find source code FIXME :current only fit for CO homework
		src_code="$(find . -type f -name "*.v" -print0 | xargs -0 grep -l "module \<$module_name\>" | head -1)"
		# add to anti-cheat FIXME :current only fit for CO homework
		mkdir -p $cheat_dir/$id
		cp "$src_code" "$cheat_dir/$id/$code"
		# go to source code location FIXME :current only fit for CO homework
		cd "$(dirname "$src_code")"
		# add(replace) testbench. FIXME :current only fit for CO homework
		cp $cur_path/$default/$testbench/* -rt .

		# judge
		output=$(judge)
		score=$(echo "$output" | grep -Eo "[0-9]+ $judge_str" | cut -d ' ' -f 1)
		[ -z "$score" ] && score=0
		# give last line as log
		log=$(echo "$output" | tail -n1 | grep "irun:") 
		# basic result
		echo "$id,$score,$log" >> "$cur_path/result.csv"
		# compare actual path they should put
		[ ! -f "$dir$id/$file_path" ] && echo $id >> "$cur_path/wrong_path.csv"
		# check report exist and compare report
		report=$(find "$dir" -name "$report_file")
		[[ -z $report ]] || [ "$(diff "$report" "$cur_path/$default/$report_file")" == "" ] && echo $id >> "$cur_path/no_report.csv"
	fi
done
exec bash
