#@ File (label="Ordner Bilder:", style="directory", description="Wähle den Ordner, der die zu analysierenden Bilder enthält.", value="C:/users/labor") dirFiles
#@ File (label="Ordner Ergebnisse:", style="directory", description="Wähle einen Ordner im dem die Ergebnisse gespeichert werden sollen.", value="C:/users/labor") dirResults
#@ String (label="Name Ergebnisse", description="Name der Ergebnissdatei") result_name
#@ String (choices={"AB count", "Intensity", "Orientation"}, style="listBox", description="<html><ul><li>AB count: Z&auml;hlt im ausgew&auml;hlten Kanal die Antik&ouml;per.</li><li>Intensity: Misst die Intensity &uuml;ber den Zellkernen.</li><li>Orientation: Filtert und misst Orientation.</li></ul></html>") messmodus
#@ String (visibility=MESSAGE, value="<html><hr />&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; <br> <h2>Optionen AB-count</h2></html>") docmsg
#@ Integer (label="Minimum Size:") ab_min_size
#@ Integer (label="Maximum Size:") ab_max_size
#@ Integer (label="Maxima Prominence >", style="slider", min=0, max=30, stepSize=1) prominence

list = getFileList(dirFiles);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display invert add nan redirect=None decimal=3");
//run("Read and Write Excel",  "file=[/Users/labor/Desktop/test.xlsx] stack_results file_mode=read_and_open");

if (messmodus == "AB count") {
	abcount("blue", "green", prominence, ab_min_size, ab_max_size, dirFiles, result_name);
} else if (messmodus == "Intensity") {
	print("Intesity");
} else if ( messmodus == "Orientation") {
	print("Orientation");
}


function abcount(channelKerne, channelAB, promValue, minsize, maxsize, file_directory, file_name) { 
// function description

	for (i=0; i<list.length; i++) {
		open("" + file_directory + "/" + list[i]);
		run("Set Scale...", "distance=5.5 known=1 unit=um global");
		run("Split Channels");

		close(list[i] + " (red)");
		selectWindow(list[i] + " (blue)");
	
		run("Gaussian Blur...", "sigma=2");
		run("Auto Threshold", "method=Huang white");
		run("Fill Holes");
		run("Convert to Mask");
		run("Watershed");
		run("Analyze Particles...", "size=50-Infinity clear include overlay add");
		waitForUser;
	
		nucleus_number = roiManager("count");
		print(nucleus_number);
		roiManager("reset");
		
		selectWindow(list[i] +  " (green)");
		run("Find Maxima...", "prominence=" + promValue + " strict output=[Single Points]");
		run("Analyze Particles...", "size=" + minsize + "-" + maxsize + "clear include overlay add");
		ab_number = roiManager("count");
		print(ab_number);
	
		close(list[i] +  " (blue)");
		close(list[i] +  " (green)");	
		close(list[i] +  " (green) Maxima");
		
		run("Clear Results");
		setResult("Bild Name", 0, list[i]);
		setResult("nuclei", 0, nucleus_number);
		setResult("antibodies", 0, ab_number);
		updateResults();
		run("Read and Write Excel", "file=[/Users/labor/Desktop/test.xlsx] stack_results");
		//print(i + " " + list.length  + " " +  nucleus_number  + " " + ab_number);


	}
	//run("Read and Write Excel", "file_mode=write_and_close");
	close("*");
}

// "file=[" + dirResults + "/" + result_name + ".xlsx]