cd .\Testing
python CodeProcess.py
cd ..

quartus_map --read_settings_files=on --write_settings_files=off CPU_Testing -c CPU

if($?)
{
	quartus_sh -t "c:/intelfpga_lite/20.1/quartus/common/tcl/internal/nativelink/qnativesim.tcl" --rtl_sim  "CPU_Testing" "CPU" --no_gui
	cd .\Testing
	diff (cat output.txt) (cat Expected_out.txt)
	cd ..
}

else 
{
	Write-Output "Code processing returned error, Simulation not started."
}
