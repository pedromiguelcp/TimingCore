onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fp_dtTicks_to_fixed_opt

do {wave.do}

view wave
view structure
view signals

do {fp_dtTicks_to_fixed.udo}

run -all

quit -force
