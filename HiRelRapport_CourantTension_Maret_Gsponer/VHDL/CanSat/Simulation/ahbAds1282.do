onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Reset and clock} /ahbads1282_tb/hreset_n
add wave -noupdate -group {Reset and clock} /ahbads1282_tb/hclk
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/i_tester/registerwrite
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/i_tester/registerread
add wave -noupdate -expand -group AHB-Lite -radix hexadecimal /ahbads1282_tb/haddr
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/hsel
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/htrans
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/hwrite
add wave -noupdate -expand -group AHB-Lite -radix hexadecimal /ahbads1282_tb/hwdata
add wave -noupdate -expand -group AHB-Lite -radix hexadecimal -subitemconfig {/ahbads1282_tb/hrdata(15) {-radix hexadecimal} /ahbads1282_tb/hrdata(14) {-radix hexadecimal} /ahbads1282_tb/hrdata(13) {-radix hexadecimal} /ahbads1282_tb/hrdata(12) {-radix hexadecimal} /ahbads1282_tb/hrdata(11) {-radix hexadecimal} /ahbads1282_tb/hrdata(10) {-radix hexadecimal} /ahbads1282_tb/hrdata(9) {-radix hexadecimal} /ahbads1282_tb/hrdata(8) {-radix hexadecimal} /ahbads1282_tb/hrdata(7) {-radix hexadecimal} /ahbads1282_tb/hrdata(6) {-radix hexadecimal} /ahbads1282_tb/hrdata(5) {-radix hexadecimal} /ahbads1282_tb/hrdata(4) {-radix hexadecimal} /ahbads1282_tb/hrdata(3) {-radix hexadecimal} /ahbads1282_tb/hrdata(2) {-radix hexadecimal} /ahbads1282_tb/hrdata(1) {-radix hexadecimal} /ahbads1282_tb/hrdata(0) {-radix hexadecimal}} -subitemconfig {/ahbads1282_tb/hrdata(15) {-radix hexadecimal} /ahbads1282_tb/hrdata(14) {-radix hexadecimal} /ahbads1282_tb/hrdata(13) {-radix hexadecimal} /ahbads1282_tb/hrdata(12) {-radix hexadecimal} /ahbads1282_tb/hrdata(11) {-radix hexadecimal} /ahbads1282_tb/hrdata(10) {-radix hexadecimal} /ahbads1282_tb/hrdata(9) {-radix hexadecimal} /ahbads1282_tb/hrdata(8) {-radix hexadecimal} /ahbads1282_tb/hrdata(7) {-radix hexadecimal} /ahbads1282_tb/hrdata(6) {-radix hexadecimal} /ahbads1282_tb/hrdata(5) {-radix hexadecimal} /ahbads1282_tb/hrdata(4) {-radix hexadecimal} /ahbads1282_tb/hrdata(3) {-radix hexadecimal} /ahbads1282_tb/hrdata(2) {-radix hexadecimal} /ahbads1282_tb/hrdata(1) {-radix hexadecimal} /ahbads1282_tb/hrdata(0) {-radix hexadecimal}} /ahbads1282_tb/hrdata
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/hready
add wave -noupdate -expand -group AHB-Lite /ahbads1282_tb/hresp
add wave -noupdate -radix hexadecimal -subitemconfig {/ahbads1282_tb/i_dut/writeregisterarray(1) {-radix hexadecimal} /ahbads1282_tb/i_dut/writeregisterarray(0) {-radix hexadecimal}} /ahbads1282_tb/i_dut/writeregisterarray
add wave -noupdate -group {ADC control} /ahbads1282_tb/reset_n
add wave -noupdate -group {ADC control} /ahbads1282_tb/clk
add wave -noupdate -group {ADC control} /ahbads1282_tb/drdy_n
add wave -noupdate -group {ADC control} /ahbads1282_tb/sclk
add wave -noupdate -group {ADC control} /ahbads1282_tb/din
add wave -noupdate -group {ADC control} /ahbads1282_tb/dout
add wave -noupdate -group {ADC control} /ahbads1282_tb/sync
add wave -noupdate -group {ADC control} /ahbads1282_tb/pwdn_n
add wave -noupdate -group {ADC control} /ahbads1282_tb/i_dut/adcsending
add wave -noupdate -group {ADC control} /ahbads1282_tb/i_dut/spiclock
add wave -noupdate -expand -group {Analog signals} -format Analog-Step -height 30 -max 5.0 -min -5.0 /ahbads1282_tb/i_tester/ain1
add wave -noupdate -expand -group {Analog signals} -radix hexadecimal /ahbads1282_tb/i_adc/sin1
add wave -noupdate -expand -group {Analog signals} -radix hexadecimal /ahbads1282_tb/i_dut/adcsample
add wave -noupdate -expand -group {Analog signals} -radix hexadecimal /ahbads1282_tb/i_adc/sin2
add wave -noupdate -expand -group {Analog signals} -format Analog-Step -height 30 -max 5.0 -min -5.0 /ahbads1282_tb/i_tester/ain2
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/enable
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/i_dut/adcstate
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/i_dut/adcsendcommand
add wave -noupdate -expand -group {Sampling sequence} -radix hexadecimal /ahbads1282_tb/i_dut/adccommand
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/i_dut/adcsendread
add wave -noupdate -expand -group {Sampling sequence} -radix unsigned /ahbads1282_tb/i_dut/adcspicounter
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/i_dut/adcsending
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/i_dut/adcCurrentAcquisitionRegister
add wave -noupdate -expand -group {Sampling sequence} /ahbads1282_tb/i_dut/adcVoltageAcquisitionRegister
add wave -noupdate -expand -group {State correction} /ahbads1282_tb/i_dut/adcstate
add wave -noupdate -expand -group {State correction} /ahbads1282_tb/i_dut/adcLastState
add wave -noupdate -expand -group {State correction} /ahbads1282_tb/i_dut/adcHammingCorrection
add wave -noupdate -expand -group {State correction} /ahbads1282_tb/i_dut/adcHammingState
add wave -noupdate -expand -group {State correction} /ahbads1282_tb/i_dut/adcNextState
add wave -noupdate -expand -group {State correction} /ahbads1282_tb/i_dut/adcFSMCorrection
add wave -noupdate -expand -group {WaitCmdTime} /ahbads1282_tb/i_dut/adcCommandWait
add wave -noupdate -expand -group {WaitCmdTime} /ahbads1282_tb/i_dut/adcCmdTimeWait
add wave -noupdate -expand -group {WaitCmdTime} /ahbads1282_tb/i_dut/adcTimecounter
add wave -noupdate -expand -group {WaitCmdTime} /ahbads1282_tb/i_dut/adcCounterEnable
add wave -noupdate -expand -group {WaitCmdTime} /ahbads1282_tb/i_dut/adcConfigured
add wave -noupdate /ahbads1282_tb/i_adc/adcstate
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 148
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {262500 ns}
