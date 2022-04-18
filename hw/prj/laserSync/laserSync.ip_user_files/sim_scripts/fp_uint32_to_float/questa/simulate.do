onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib fp_uint32_to_float_opt

do {wave.do}

view wave
view structure
view signals

do {fp_uint32_to_float.udo}

run -all

quit -force
