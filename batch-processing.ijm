#@ File (label="Ordner Bilder:", style="directory", description="Wähle den Ordner, der die zu analysierenden Bilder enthält.", value="C:/users/labor") dirFiles
#@ File (label="Ordner Ergebnisse:", style="directory", description="Wähle einen Ordner im dem die Ergebnisse gespeichert werden sollen.", value="C:/users/labor") dirResults
#@ String (label="Name Ergebnisse", description="Name der Ergebnissdatei") result_name
#@ String (choices={"AB count", "Intensity", "Orientation"}, style="listBox", description="<html><ul><li>AB count: Z&auml;hlt im ausgew&auml;hlten Kanal die Antik&ouml;per.</li><li>Intensity: Misst die Intensity &uuml;ber den Zellkernen.</li><li>Orientation: Filtert und misst Orientation.</li></ul></html>") messmodus
#@ String (visibility=MESSAGE, value="<html><hr />&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; <br> <h2>Optionen AB-count</h2></html>") docmsg
#@ Integer (label="Nuclei min. Size (µm²):", value="20", description="Partikel, die kleiner als die angegebene Fläche sind, werden herausgefiltert.") nuclei_min_size
#@ Integer (label="AB min. Size:") ab_min_size
#@ Integer (label="AB max. Size:") ab_max_size
#@ Integer (label="Maxima Prominence >", style="slider", min=0, max=30, stepSize=1) prominence

dirResults = replace(dirResults, "\\", "/");
dirFiles = replace(dirFiles, "\\", "/");

list = getFileList(dirFiles);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display invert add nan redirect=None decimal=3");

if (messmodus == "AB count") {
	abcount("blue", "green", prominence, nuclei_min_size, ab_min_size, ab_max_size, dirFiles, result_name);
} else if (messmodus == "Intensity") {
	print("Intesity");
} else if ( messmodus == "Orientation") {
	print("Orientation");
}


function abcount(channelKerne, channelAB, promValue, nuclei_size, minsize, maxsize, file_directory, file_name) { 
	data_nuclei = newArray();
	data_antibodies = newArray();
	data_filenames = newArray();
	
	for (i=0; i<list.length; i++) {
		open("" + file_directory + "/" + list[i]);
		data_filenames = Array.concat(data_filenames,getInfo("image.filename"));
		run("Set Scale...", "distance=5.5 known=1 unit=um global");
		run("Split Channels");

		close(list[i] + " (red)");

		selectWindow(list[i] + " (" + channelKerne + ")");
		
		roiManager("reset");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + list[i] + " (" + channelKerne + ")" + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		
		minsizefilter(nuclei_size);
		nucleus_number = roiManager("count");
		data_nuclei = Array.concat(data_nuclei,nucleus_number);
		
		roiManager("reset");		
		selectWindow(list[i] +  " (green)");
		run("Find Maxima...", "prominence=" + promValue + " strict output=[Single Points]");
		run("Analyze Particles...", "size=" + minsize + "-" + maxsize + "clear include overlay add");
		ab_number = roiManager("count");
		data_antibodies = Array.concat(data_antibodies,ab_number);
	
		close(list[i] +  " (blue)");
		close(list[i] +  " (green)");	
		close(list[i] +  " (green) Maxima");

	}
	close("*");
	run("Clear Results");
	Array.show("Results (row numbers)", data_filenames, data_nuclei, data_antibodies);
	updateResults();
//	saveAs("results", dirResults + "/" + result_name + ".csv");
	Table.save(dirResults + "/" + result_name + ".csv");
}

function minsizefilter(minimum_size) {
		roinumber = roiManager("count"); 
		to_be_deleted = newArray(); 
		
		for (j = 0; j < roinumber; j++) { 
		    roiManager("Select", j); 
			getStatistics(area, mean, min, max, std, histogram);
		    
		    if (area <= minimum_size){
				to_be_deleted = Array.concat(to_be_deleted, j);
			}   
		}
		
		if (to_be_deleted.length > 0){
			roiManager("Select", to_be_deleted);
			roiManager("Delete");
		}
}