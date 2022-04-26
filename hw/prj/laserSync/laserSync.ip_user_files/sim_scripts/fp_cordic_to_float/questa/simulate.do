onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fp_cordic_to_float_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {fp_cordic_to_float.udo}

run -all

quit -force
