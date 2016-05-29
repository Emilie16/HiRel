onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ads1282_tb/i_tester/indicationstring
add wave -noupdate -expand -group {Reset and clock} /ads1282_tb/reset_n
add wave -noupdate -expand -group {Reset and clock} /ads1282_tb/clk
add wave -noupdate -group {Analog inputs} -format Analog-Step -height 30 -max 5.0 -min -5.0 /ads1282_tb/i_tester/ain1
add wave -noupdate -group {Analog inputs} -format Analog-Step -height 30 -max 5.0 -min -5.0 /ads1282_tb/i_tester/ain2
add wave -noupdate -group {Analog inputs} /ads1282_tb/ainp1
add wave -noupdate -group {Analog inputs} /ads1282_tb/ainn1
add wave -noupdate -group {Analog inputs} /ads1282_tb/ainp2
add wave -noupdate -group {Analog inputs} /ads1282_tb/ainn2
add wave -noupdate -expand -group SPI /ads1282_tb/i_dut/commandbitid
add wave -noupdate -expand -group SPI /ads1282_tb/drdy_n
add wave -noupdate -expand -group SPI /ads1282_tb/sclk
add wave -noupdate -expand -group SPI /ads1282_tb/din
add wave -noupdate -expand -group SPI /ads1282_tb/dout
add wave -noupdate -expand -group SPI -radix hexadecimal -subitemconfig {/ads1282_tb/i_tester/spidatain(31) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(30) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(29) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(28) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(27) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(26) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(25) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(24) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(23) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(22) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(21) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(20) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(19) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(18) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(17) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(16) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(15) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(14) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(13) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(12) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(11) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(10) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(9) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(8) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(7) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(6) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(5) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(4) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(3) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(2) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(1) {-radix hexadecimal} /ads1282_tb/i_tester/spidatain(0) {-radix hexadecimal}} /ads1282_tb/i_tester/spidatain
add wave -noupdate -expand -group SPI /ads1282_tb/i_tester/spislaveselect
add wave -noupdate -expand -group ADC /ads1282_tb/i_dut/dataready
add wave -noupdate -expand -group ADC -format Analog-Step -height 30 -max 8000000.0000000009 -min -8000000.0 -radix decimal /ads1282_tb/i_dut/sin1
add wave -noupdate -expand -group ADC -format Analog-Step -height 30 -max 8000000.0000000009 -min -8000000.0 -radix decimal /ads1282_tb/i_dut/sin2
add wave -noupdate -expand -group ADC -radix hexadecimal /ads1282_tb/i_dut/commandid
add wave -noupdate -expand -group ADC /ads1282_tb/i_dut/adcstate
add wave -noupdate -format Analog-Step -height 30 -max 2000000000.0 -min -2000000000.0 -radix decimal /ads1282_tb/i_tester/sampledvalue
add wave -noupdate /ads1282_tb/i_dut/registerid
add wave -noupdate /ads1282_tb/i_dut/registeridcounter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {945792900 ps} 0}
configure wave -namecolwidth 253
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {495488400 ps} {570314600 ps}
