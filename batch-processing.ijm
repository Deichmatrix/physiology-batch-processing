#@ File (label="Ordner Bilder:", style="directory", description="Wähle den Ordner, der die zu analysierenden Bilder enthält.", value="C:/users/labor") dirFiles
#@ File (label="Ordner Ergebnisse:", style="directory", description="Wähle einen Ordner im dem die Ergebnisse gespeichert werden sollen.", value="C:/users/labor") dirResults
#@ String (label="Name Ergebnisse", description="Name der Ergebnissdatei") result_name
#@ String (choices={"AB count", "Intensity", "Orientation"}, style="listBox", description="<html><ul><li>AB count: Z&auml;hlt im ausgew&auml;hlten Kanal die Antik&ouml;per.</li><li>Intensity: Misst die Intensity &uuml;ber den Zellkernen.</li><li>Orientation: Filtert und misst Orientation.</li></ul></html>") messmodus
#@ String (label="Kanal Nuclei", choices={"blue", "green", "red"}, style="listBox", value="blue") channel_nuclei
#@ String (label="Kanal Marker", choices={"blue", "green", "red"}, style="listBox", value="green") channel_marker
//#@ String (visibility=MESSAGE, value="<html><hr />&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; <br> <h2>Optionen AB-count</h2></html>") docmsg
#@ Integer (label="Nuclei min. Size (µm²):", value="20", description="Partikel, die kleiner als die angegebene Fläche sind, werden herausgefiltert.") nuclei_min_size
#@ String (label="Beobachtungsmodus:", choices={"AN", "AUS"}, style="radioButtonHorizontal", value="AUS", description="Wenn der Beobachtungsmodus aktiviert wird, werden die einzelnen Bearbeitungsschritte zur Kontrolle angezeigt, die Bearbeitung ist langsamer.") batchmode_toggle
//#@ Integer (label="AB min. Size:") ab_min_size
//#@ Integer (label="AB max. Size:") ab_max_size
//#@ Integer (label="Maxima Prominence >", style="slider", min=0, max=30, stepSize=1) prominence

dirResults = replace(dirResults, "\\", "/");
dirFiles = replace(dirFiles, "\\", "/");

list = getFileList(dirFiles);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display invert add nan redirect=None decimal=3");

if (messmodus == "AB count") {
	abcount(channel_nuclei, channel_marker, prominence, nuclei_min_size, ab_min_size, ab_max_size, dirFiles, result_name);
} else if (messmodus == "Intensity") {
	intensity_over_nucleus(channel_nuclei, channel_marker, nuclei_min_size, dirFiles, result_name);
} else if ( messmodus == "Orientation") {
	print("Orientation");
}

function intensity_over_nucleus(channel_nuclei, channel_marker, nuclei_min_size, dirFiles, result_name) {
	data_nuclei = newArray();
	data_intensities = newArray();
	data_areas = newArray();
	data_filenames = newArray();
	
	setBatchMode(false);
	
	channel_to_close = select_unused_channel(channel_nuclei, channel_marker);
	
	for (i=0; i<list.length; i++) {
		open("" + dirFiles + "/" + list[i]);
		data_filenames = Array.concat(data_filenames,getInfo("image.filename"));
		current_file = Image.title;
		
		run("Set Scale...", "distance=5.5 known=1 unit=um global");
		run("Split Channels");
		
		close(current_file + " (" + channel_to_close + ")");

		selectWindow(current_file + " (" + channel_nuclei + ")");
		roiManager("reset");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + current_file + " (" + channel_nuclei + ")" + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		minsizefilter(nuclei_min_size);
		nucleus_number = roiManager("count");
		data_nuclei = Array.concat(data_nuclei, nucleus_number);
		
		selectWindow(current_file + " (" + channel_marker + ")");
		run("Clear Results");
//		roiManager("show all");
//		run("Select All");
		nuclei_indexes = newArray(roiManager("count"));
		for (j=0; j<nuclei_indexes.length; j++) {
		 	nuclei_indexes[j] = j;
		}
		roiManager("select", nuclei_indexes);
		roiManager("Combine");
		roiManager("Add");
//		roiManager("Delete");
//		waitForUser;
//		roiManager("Add");
		roiManager("show none")
		roiManager("Select", nucleus_number);
		wait(1000);
//		waitForUser;
		
		data_intensities = Array.concat(data_intensities, getValue("Mean"));
		data_areas = Array.concat(data_areas, getValue("Area"));
		print("> Bild " + (i+1) + " von " + list.length + " wurde ausgewertet.");
		print("Ergebnisse: " + current_file + ", " + nucleus_number + ", " + getValue("Mean"));
		close("*");
//		wait(5000);
	}
	close("*");
	run("Clear Results");
	Array.show("Results (indexes)", data_filenames, data_nuclei, data_intensities, data_areas);
	updateResults();
}

function abcount(channelKerne, channelAB, promValue, nuclei_size, minsize, maxsize, file_directory, file_name) { 
	data_nuclei = newArray();
	data_antibodies = newArray();
	data_filenames = newArray();
	
	setBatchMode(false);
	
	channel_to_close = select_unused_channel(channel_nuclei, channel_marker);
	
	for (i=0; i<list.length; i++) {
		open("" + file_directory + "/" + list[i]);
		data_filenames = Array.concat(data_filenames,getInfo("image.filename"));
		current_file = Image.title;

		run("Set Scale...", "distance=5.5 known=1 unit=um global");
		run("Split Channels");

		close(current_file + " (" + channel_to_close + ")");

		selectWindow(current_file + " (" + channelKerne + ")");
		
		roiManager("reset");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + current_file + " (" + channelKerne + ")" + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		
		minsizefilter(nuclei_size);
		nucleus_number = roiManager("count");
		data_nuclei = Array.concat(data_nuclei,nucleus_number);
		
//		roiManager("reset");		
//		selectWindow(current_file +  " (" + channelAB + ")");
//		run("Find Maxima...", "prominence=" + promValue + " strict output=[Single Points]");
//		run("Analyze Particles...", "size=" + minsize + "-" + maxsize + "clear include overlay add");
//		ab_number = roiManager("count");
//		data_antibodies = Array.concat(data_antibodies,ab_number);
//	
		selectWindow(current_file +  " (" + channelAB + ")");
		newImage("black", "8-bit black", 1360, 1024, 1);
		run("Merge Channels...", "c1=black c2=["+current_file +  " (" + channelAB + ")] c3=black create");
		run("Stack to RGB");
		close("Composite");
		selectWindow("Composite (RGB)");
		saveAs("Tiff", "C:/Users/labor/Documents/Composite_(RGB).tif");
		
		
		ab_number = Ilastik_Processing("C:/Program Files/ilastik-1.4.0rc5", "C:/Users/labor/Desktop/erik_ab_snapshot.ilp", "C:/Users/labor/Documents/Composite_(RGB).tif", "C:/Users/labor/Documents/");
		
		print("Die von Ilastik gemessene AB-Zahl ist: " + ab_number);
		
		close(current_file +  " (" + channelKerne + ")");
		close(current_file +  " (" + channelAB + ")");	
		close(current_file +  " (" + channelAB + ") Maxima");
		
		print("> Bild " + (i+1) + " von " + list.length + " wurde ausgewertet.");

	}
	close("*");
	run("Clear Results");
	Array.show("Results (row numbers)", data_filenames, data_nuclei, data_antibodies);
	updateResults();
//	saveAs("results", dirResults + "/" + result_name + ".csv");
	Table.save(dirResults + "/" + result_name + ".csv");
}

function intensity () {
	
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

function select_unused_channel(ch1, ch2) {
	if ((ch1 == "blue" && ch2 == "blue") || (ch1 == "green" && ch2 == "green") || (ch1 == "red" && ch2 == "red") == 1) {
		 exit("Der Kanal für Nuclei und Marker können nicht auf die gleiche Farbe eingestellt sein.");
	} else if ((ch1 == "blue" && ch2 == "green") || (ch1 == "green" && ch2 == "blue") == 1) {
		return "red";	
	} else if ((ch1 == "blue" && ch2 == "red") || (ch1 == "red" && ch2 == "blue") == 1) {
		return "green";
	} else if ((ch1 == "red" && ch2 == "green") || (ch1 == "green" && ch2 == "red") == 1) {
		return "blue";
	} 

}

function Ilastik_Processing(IlastikDir, IlastikProject, IlastikInput, IlastikOutput) {
		print("Performing Ilastik antibody count...");
				
		//Prepare text inputs for batch
		q ="\"";
		//inputI = replace(input, "\\", "/");
		IlastikDir1 = replace(IlastikDir+"/ilastik.exe", "\\", "/");
//		IlastikDir1 = q + IlastikDir1 + q;	
		
		print(IlastikDir1);
		
		IlastikProject1 = replace(IlastikProject, "\\", "/");
//		IlastikProject1 = q + IlastikProject1 + q;
	
		IlastikOutDir = IlastikOutput;
		IlastikOutDir = replace(IlastikOutDir, "\\", "/");
//		IlastikOutDir = q + IlastikOutDir + "ilastik_temp_savefile.csv" + q;

		IlastikInput = IlastikInput;
//		IlastikInput = q + IlastikInput + q;
			
		ilcommand = IlastikDir1 +" --headless --project="+IlastikProject1+" --csv-export-file=" + IlastikOutDir + " " + IlastikInput;
		print(ilcommand);
		
		// Create Batch and run
		run("Text Window...", "name=Batch");
		//print("[Batch]", "@echo off" + "\n");
		print("[Batch]", ilcommand);
		run("Text...", "save=[C:/Users/labor/Documents/Ilastikrun.bat]");
		selectWindow("Ilastikrun.bat");
		run("Close"); 
		runilastik = "C:/Users/labor/Documents/Ilastikrun.bat";
		runilastik = replace(runilastik, "\\", "/");
//		runilastik = q + runilastik + q;
		print(runilastik);
		waitForUser;

		exec(runilastik);

		//Cleanup
		File.delete("C:/Users/labor/Documents/Ilastikrun.bat");
		print("");
		
		file_contents = File.openAsString(IlastikOutDir);
		substr = split(file_contents, ",");
		ab_number = parseFloat(substr[1]);
//		
//		open(IlastikOutDir);
//		getResult("C2", 0);
//		ab_number = getResult("C2", 0);	

		print("Die gemessene AB-Zahl ist: " + ab_number);
		return ab_number;

}
