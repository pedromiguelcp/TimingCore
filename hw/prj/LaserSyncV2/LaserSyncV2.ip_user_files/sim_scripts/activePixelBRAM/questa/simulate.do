onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib activePixelBRAM_opt

do {wave.do}

view wave
view structure
view signals

do {activePixelBRAM.udo}

run -all

quit -force
