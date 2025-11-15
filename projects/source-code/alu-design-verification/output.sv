Start time: 17:50:07 on Nov 15,2025
qrun -batch -access=rw+/. -uvmhome uvm-1.2 -timescale 1ns/1ns -mfcu design.sv testbench.sv -voptargs="+acc=npr" -do " run -all; exit" 
Creating library 'qrun.out/work'.
Mapping library 'mtiUvm' to 'qrun.out/work'.
QuestaSim-64 vlog 2024.3_1 Compiler 2024.10 Oct 17 2024
Start time: 17:50:07 on Nov 15,2025
vlog -timescale 1ns/1ns -mfcu -ccflags "-Wno-missing-declarations" -ccflags "-Wno-maybe-uninitialized" -ccflags "-Wno-return-type" -ccflags "-DQUESTA" /usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_dpi.cc /usr/share/questa/questasim/verilog_src/uvm-1.2/src/uvm_pkg.sv /usr/share/questa/questasim/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv design.sv testbench.sv -work qrun.out/work "+incdir+/usr/share/questa/questasim/verilog_src/uvm-1.2/src" -statslog qrun.out/stats_log -writesessionid "+qrun.out/top_dus" -csession=incr 
-- Compiling package uvm_pkg (uvm-1.2 Built-in)
-- Compiling package questa_uvm_pkg
-- Importing package uvm_pkg (uvm-1.2 Built-in)
-- Compiling package alu_pkg
-- Compiling module alu
-- Importing package alu_pkg
-- Compiling package uvm_pkg_sv_unit
-- Importing package alu_pkg
-- Compiling module testbench

Top level modules:
	testbench
-- Compiling DPI/PLI C++ file /usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_dpi.cc

In file included from /usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_hdl.c:27,
                 from /usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_dpi.cc:37:
/usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_hdl_questa.c: In function 'int uvm_is_vhdl_path(char*)':
/usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_hdl_questa.c:90:12: warning: 'char* strncpy(char*, const char*, size_t)' specified bound depends on the length of the source argument [-Wstringop-overflow=]
   90 |     strncpy(path_copy, path, path_len);
      |     ~~~~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~
/usr/share/questa/questasim/verilog_src/uvm-1.2/src/dpi/uvm_hdl_questa.c:72:20: note: length computed here
   72 |   path_len = strlen(path);
      |              ~~~~~~^~~~~~

End time: 17:50:10 on Nov 15,2025, Elapsed time: 0:00:03
Errors: 0, Warnings: 0
QuestaSim-64 vopt 2024.3_1 Compiler 2024.10 Oct 17 2024
** Warning: (vopt-10587) Some optimizations are turned off because the +acc switch is in effect. This will cause your simulation to run slowly. Please use -access/-debug to maintain needed visibility. The +acc switch would be deprecated in a future release.
Start time: 17:50:10 on Nov 15,2025
vopt -access=rw+/. -timescale 1ns/1ns -mfcu "+acc=npr" -findtoplevels qrun.out/work+1+ -work qrun.out/work -statslog qrun.out/stats_log -csession=incr -o qrun_opt -csessionid=2 

Top level modules:
	testbench

Analyzing design...
-- Loading module testbench
-- Loading module alu
Optimizing 4 design-units (inlining 0/2 module instances):
-- Optimizing package alu_pkg(fast)
-- Optimizing package uvm_pkg_sv_unit(fast)
-- Optimizing module testbench(fast)
-- Optimizing module alu(fast)
Optimized design name is qrun_opt
End time: 17:50:10 on Nov 15,2025, Elapsed time: 0:00:00
Errors: 0, Warnings: 1
# vsim -batch -lib qrun.out/work -do " run -all; exit" -statslog qrun.out/stats_log qrun_opt -appendlog -l qrun.log 
# Start time: 17:50:10 on Nov 15,2025
# Loading /tmp/unknown@972010446ef1_dpi_51/linux_x86_64_gcc-10.3.0/export_tramp.so
# //  Questa Sim-64
# //  Version 2024.3_1 linux_x86_64 Oct 17 2024
# //
# // Unpublished work. Copyright 2024 Siemens
# //
# // This material contains trade secrets or otherwise confidential information
# // owned by Siemens Industry Software Inc. or its affiliates (collectively,
# // "SISW"), or its licensors. Access to and use of this information is strictly
# // limited as set forth in the Customer's applicable agreements with SISW.
# //
# // This material may not be copied, distributed, or otherwise disclosed outside
# // of the Customer's facilities without the express written permission of SISW,
# // and may not be used in any way not expressly authorized by SISW.
# //
# Loading sv_std.std
# Loading work.alu_pkg(fast)
# Loading work.uvm_pkg_sv_unit(fast)
# Loading work.testbench(fast)
# Loading work.alu(fast)
# Loading /tmp/unknown@972010446ef1_dpi_51/linux_x86_64_gcc-10.3.0/vsim_auto_compile.so
# 
# run -all
# 
# All tests finished. Pass=205, Fail=0, Coverage=89.6%
# ** Note: $finish    : testbench.sv(118)
#    Time: 6195 ns  Iteration: 2  Instance: /testbench
# End time: 17:50:12 on Nov 15,2025, Elapsed time: 0:00:02
# Errors: 0, Warnings: 0
End time: 17:50:12 on Nov 15,2025, Elapsed time: 0:00:05
*** Summary *********************************************
    qrun: Errors:   0, Warnings:   0
    vlog: Errors:   0, Warnings:   0
    vopt: Errors:   0, Warnings:   1
    vsim: Errors:   0, Warnings:   0
  Totals: Errors:   0, Warnings:   1