#bin/bash
# do not remove cur_path
cur_path="$(pwd)"
# basic csv format
###### Configre(do not remove variable here) ######
# testbench folder name
default="Example"
# testbench_dir match to each judge method's testbench that require to copy
testbench_dir=( "RTL category" "Gate-Level category" "" )

# success string(please modify testbench succes to random string to prevent fake success)
# remember remove file that student should write
# you also should edit testbench to concate score before judge_str
# EX: 100 b21erhb
judge_str="b21erhb4g3"

# execute folder
operation_dir="execute"

# code which student must write
# if both are match, it will copy the files in the dir to $operation_dir to run JUDGE[i]
# student_code will check whether the string is in the file
student_code=( 
	"module \<AEC\>"
	""
	""
)
# student_file will be concate to "find" parameters,use `man find` for more
student_file=(
	"-type f -name \"*.v\""
	"-type f -name \"*.vo\" -o -name \"*.sdo\""
	"-type f -name \"result.txt\""
)

###### execute command(in student folder)
# the script will call JUDGE, **remember to store $score && $log**
# you can use extract_score to extract score from output
# ex: extract_score "$your_log" "$judge_str"
# ps. you can only use integer in bash,and zsh will start array in 1
if [ $# -eq 0 ] ; then
    echo "Usage ./judge.sh /path/to/moodle/extracted/folder"
	exit
fi
JUDGE=( rtl gate other_check )
rtl () {
	cp "$cur_path/pre_sim.tcl" .
	local presim_log=$(vsim -c -do "do ./pre_sim.tcl testfixture.sv")
	presim_score=$(extract "$presim_log" "$judge_str")
	score=$(($score+$presim_score*3/5))
	#tb='traffic_light_tb.v'
	#irun $tb $(find . -type f ! -name $tb -and -name "*.v" -print) +nc64bit
}

gate () {
	cp "$cur_path/gate_sim.tcl" .
	cp "$student_origin_dir"/result.txt .
	# parameters: testfixture module_name
	# you need to edit library path & name inside
	local gatesim_log=$(vsim -c -do "do ./gate_sim.tcl testfixture.sv AEC")
	gatesim_score=$(extract "$gatesim_log" "$judge_str")
	real_cycle=$(extract "$gatesim_log" "cycle")
	score=$(($score+$gatesim_score/5))
}

dir_structure=$(ls "$default" | xargs -d '\n' -n 1 basename)
echo '學號,面積X時間' > $cur_path/performance.csv
other_check () {
	#check whether directory structure is the same as example
	IFS='_ ' read -r -a array <<< $(basename "$student_origin_dir")
	expect_dir="HW3_${array[0]}_${array[1]}"
	expect_dir_structure=$(ls "$student_origin_dir/$expect_dir" | xargs -d '\n' -n 1 basename)
	if [ "$expect_dir_structure" != "$dir_structure" ]; then
		score=$(($score-5))
		echo -e "\033[0;31m wrong directory format!\033[0m"
	fi

	# read result
	diff=0
	readarray -t report_nums < ./result.txt
	for i in "${!report_nums[@]}"; do
		report_nums[$i]=${report_nums[$i]%%\ *}
	done

	if [ "${report_nums[0]}" != "$presim_score" ]; then
		diff=-10
		echo -e "\033[0;31m different rtl score value to report!\033[0m"
	fi
	if [ "${report_nums[1]}" != "$gatesim_score" ]; then
		diff=-10
		echo -e "\033[0;31m different gate score value to report!\033[0m"
	fi
	if [ "${report_nums[2]}" != "$real_cycle" ]; then
		echo -e "\033[0;31m different gate cycle value to report!\033[0m"
	fi
	score=$(($score-$diff))
	area=$((${report_nums[2]}+${report_nums[3]}+${report_nums[4]}*9))
	time=$((${report_nums[5]}*${report_nums[6]}))
	performance=$(($time*$area))
	echo "$id,$performance" >> $cur_path/performance.csv
}

###### You may not need to edit bellow except the score method changed ######
###### or you can help me to improve this script :D , ex: parallel execute######
# extract score function 
extract() {
	local point=$(echo "$1" | grep -Eo "[0-9]+ $2" | cut -d ' ' -f 1)
	[ -z "$point" ] && point=0
	echo $point
}

# store current pos
echo '學號,成績,評語回饋' > $cur_path/result.csv
# create basic dir
mkdir -p $operation_dir
operation_dir="$cur_path/$operation_dir"
# check whether user removed origin code
for i in "${!student_file[@]}"; do
	find_cmd="find ./$default ${student_file[$i]} -print0 | xargs -0 grep -l \"${student_code[$i]}\" | head -1"
	demo_code="$(eval "$find_cmd")"
	if [[ $demo_code == *[!\ ]* ]] ; then
		echo -e "\033[0;31mPlease check whether you already removed the file student should write.\033[0m"
		echo -e "Or this script might overwrite the file student should write."
		echo -e "found file in example $demo_code sus\n"
	fi
done
all_student_path=$(realpath $1)
# loop every student folderm
for student_origin_dir in $all_student_path/*/ ; do
	# ignore default directory
	#if ! [[ $student_origin_dir -ef $cur_path/$default ]] ; then
	# cut student id & check is valid id
	id=$(grep -Eo '[A-Z][0-9A-Z][0-9]{7}' <<<$student_origin_dir)
	[ -z "$id" ] && echo -e "ignore non student directory: $student_origin_dir\n" && continue

	cd "$student_origin_dir"
	echo "entering $student_origin_dir... "

	# unzip
	unzip -oqq *.zip
	unrar e *.rar  -idq
	chmod -R +rw ./*

	score=0
	log=""
	for i in "${!JUDGE[@]}"; do
		pwd
		# find source code
		find_cmd="find . ${student_file[$i]} -print0 | xargs -0 grep -l \"${student_code[$i]}\" | head -1"
		src_code="$(eval " $find_cmd")"
		src_path=$(dirname "$src_code")
		echo -e "Execute \033[0;33m${JUDGE[$i]}\033[0m from student code path: $student_origin_dir$src_path"
		mkdir -p $operation_dir/$id/${JUDGE[$i]}
		# copy other possible src files
		cp "$src_path"/* -rt "$operation_dir/$id/${JUDGE[$i]}"
		# go to source code location
		cd "$operation_dir/$id/${JUDGE[$i]}"
		# add(replace) testbench
		cp "$cur_path/$default/${testbench_dir[$i]}"/* -rt .
		# execute judge
		${JUDGE[$i]}
		cd "$student_origin_dir"
	done
	# result
	echo -e "\033[0;31m ----------------------score: $score\033[0m\n\n"
	echo "$id,$score,$log" >> $cur_path/result.csv
	#fi
done
cd $cur_path
