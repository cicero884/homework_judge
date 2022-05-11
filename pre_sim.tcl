puts {
  ModelSim general compile script version 1.2
  Copyright (c) Doulos June 2017, SD
}

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.

# testfixture to be fix
set test_library "test_library {./$1.v"
set a [exec ls ./]
set b [llength $a]
set k 1
for { set i 0 } { $i<$b } { incr i } {
  set c [lindex $a $i]
  if { [string range $c end-1 end]==".v" && [string range $c end-3 end]!="tb.v"} {
    set test_library "$test_library ./$c"
    incr k
  }
}
set test_library "$test_library}"

# set library_file_list(design_library) {}
# set library_file_list(test_library) $d
set library_file_list "
                       design_library {}
                       $test_library
                      "
 # test => module name
set top_level              test_library.$1
set wave_patterns {
                           /*
}
set wave_radices {
                           hexadecimal {data q}
}


# After sourcing the script from ModelSim for the
# first time use these commands to recompile.

proc r  {} {uplevel #0 source ../pre_sim.tcl}
proc rr {} {global last_compile_time
            set last_compile_time 0
            r                            }
proc q  {} {quit -force                  }

#Does this installation support Tk?
set tk_ok 1
if [catch {package require Tk}] {set tk_ok 0}

# Prefer a fixed point font for the transcript
set PrefMain(font) {Courier 10 roman normal}

# Compile out of date files
set time_now [clock seconds]
if [catch {set last_compile_time}] {
  set last_compile_time 0
}
foreach {library file_list} $library_file_list {
  vlib $library
  vmap work $library
  foreach file $file_list {
    if { $last_compile_time < [file mtime $file] } {
      if [regexp {.vhdl?$} $file] {
        vcom -93 $file
      } else {
        if [catch {vlog $file}] {
          puts "** Compile error **"
        }
      }
      set last_compile_time 0
    }
  }
}
set last_compile_time $time_now

# Load the simulation
eval vsim -novopt $top_level

# If waves are required
# if [llength $wave_patterns] {
#   noview wave
#   foreach pattern $wave_patterns {
#     add wave $pattern
#   }
#   configure wave -signalnamewidth 1
#   foreach {radix signals} $wave_radices {
#     foreach signal $signals {
#       catch {property wave -radix $radix $signal}
#     }
#   }
# }

# Run the simulation
run -all

# If waves are required
# if [llength $wave_patterns] {
#   if $tk_ok {wave zoomfull}
# }

# puts {
#   Script commands are:
# 
#   r = Recompile changed and dependent files
#  rr = Recompile everything
#   q = Quit without confirmation
# }

# How long since project began?
# if {[file isfile start_time.txt] == 0} {
#   set f [open start_time.txt w]
#   puts $f "Start time was [clock seconds]"
#   close $f
# } else {
#   set f [open start_time.txt r]
#   set line [gets $f]
#   close $f
#   regexp {\d+} $line start_time
#   set total_time [expr ([clock seconds]-$start_time)/60]
#   puts "Project time is $total_time minutes"
# }

exit
