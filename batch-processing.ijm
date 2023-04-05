#@ File (label="Ordner Bilder:", style="directory", description="Wähle den Ordner, der die zu analysierenden Bilder enthält.", value="C:/users/labor") image_directory
#@ File (label="Ordner Ergebnisse:", style="directory", description="Wähle einen Ordner im dem die Ergebnisse gespeichert werden sollen.", value="C:/users/labor") results_directory
#@ String (label="Name Ergebnisse", description="Name der Ergebnissdatei") filename_results
#@ String (choices={"AB count", "Intensity (whole)", "Intensity (nuclei)", "Intensity (erythrocytes)", "Orientation"}, style="listBox", description="<html><ul><li>AB count: Z&auml;hlt im ausgew&auml;hlten Kanal die Antik&ouml;per.</li><li>Intensity: Misst die Intensity &uuml;ber den Zellkernen.</li><li>Orientation: Filtert und misst Orientation.</li></ul></html>") messmodus
#@ String (label="Kanal Nuclei", choices={"blue", "green", "red"}, style="listBox", value="blue") channel_nuclei
#@ String (label="Kanal Marker", choices={"blue", "green", "red"}, style="listBox", value="green") channel_marker
//#@ String (visibility=MESSAGE, value="<html><hr />&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; <br> <h2>Optionen AB-count</h2></html>") docmsg
#@ Integer (label="Nuclei min. Size (µm²):", value="20", description="Partikel, die kleiner als die angegebene Fläche sind, werden herausgefiltert.") nuclei_min_size
#@ String (label="Beobachtungsmodus:", choices={"AN", "AUS"}, style="radioButtonHorizontal", value="AUS", description="Wenn der Beobachtungsmodus aktiviert wird, werden die einzelnen Bearbeitungsschritte zur Kontrolle angezeigt, die Bearbeitung ist langsamer.") batchmode_toggle
#@ String (visibility=MESSAGE, value="<html><hr />&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; <br></html>") docmsg
#@ File (label="Ordner Ilastik", style="directory", description="Wähle den Ordner, der die Ilastik-Programmdateien enthält.", value="C:/Program Files") ilastik_directory
#@ File (label="Ilastik Project (.ilp)", style="file", description="Wähle die Ilastik-Projektdatei.", value="C:/users/labor") ilastik_project_filepath
//#@ Boolean (label="Test") test

image_directory = replace(image_directory, "\\", "/");
results_directory = replace(results_directory, "\\", "/");
setBatchMode(set_batchmode_toggle(batchmode_toggle));

list = getFileList(image_directory);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display invert add nan redirect=None decimal=3");

if (messmodus == "AB count") {
	abcount(channel_nuclei, channel_marker, nuclei_min_size, image_directory, results_directory, filename_results, ilastik_directory, ilastik_project_filepath);
} else if (messmodus == "Intensity (nuclei)") {
	intensity_over_nucleus(channel_nuclei, channel_marker, nuclei_min_size, image_directory, filename_results);
} else if ( messmodus == "Orientation") {
	print("Orientation");
}

function intensity_over_nucleus(channel_nuclei, channel_marker, nuclei_min_size, image_directory, filename_results) {
	data_nuclei = newArray();
	data_intensities = newArray();
	data_areas = newArray();
	data_filenames = newArray();
	
	channel_to_close = select_unused_channel(channel_nuclei, channel_marker);
	
	print("Starting analysis of Intensity over nuclei. There are " + list.length + " images in the queue.");
		
	for (i=0; i<list.length; i++) {
		open("" + image_directory + "/" + list[i]);
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
		nuclei_indexes = newArray(roiManager("count"));
		for (j=0; j<nuclei_indexes.length; j++) {
		 	nuclei_indexes[j] = j;
		}
		
		roiManager("select", nuclei_indexes);
		roiManager("Combine");
		roiManager("Add");
		roiManager("show none");
		roiManager("Select", nucleus_number);
		
		data_intensities = Array.concat(data_intensities, getValue("Mean"));
		data_areas = Array.concat(data_areas, getValue("Area"));
		print("> Bild " + (i+1) + " von " + list.length + " wurde ausgewertet.");
		print("Ergebnisse: " + current_file + ", " + nucleus_number + ", " + getValue("Mean"));
		close("*");
	}
	close("*");
	run("Clear Results");
	Array.show("Results", data_filenames, data_nuclei, data_intensities, data_areas);
	Table.renameColumn("data_filenames", "Image Filename");
	Table.renameColumn("data_nuclei", "Nuclei count");
	Table.renameColumn("data_intensities", "Intensities");
	Table.renameColumn("data_areas", "Area of Nuclei (µm²)");
	Table.save(results_directory + "/" + filename_results + ".csv");
}

function abcount(channel_nuclei, channel_marker, nuclei_size, image_directory, results_directory, filename_results, ilastik_directory, ilastik_project_filepath) { 

	data_nuclei = newArray();
	data_antibodies = newArray();
	data_filenames = newArray();
	
	channel_to_close = select_unused_channel(channel_nuclei, channel_marker);
	
	print("Starting counting of antibodies. There are " + list.length + " images in the queue.");
	
	for (i=0; i<list.length; i++) {
		open("" + image_directory + "/" + list[i]);
		data_filenames = Array.concat(data_filenames,getInfo("image.filename"));
		current_file = Image.title;

		run("Set Scale...", "distance=5.5 known=1 unit=um global");
		run("Split Channels");

		close(current_file + " (" + channel_to_close + ")");

		selectWindow(current_file + " (" + channel_nuclei + ")");
		
		roiManager("reset");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + current_file + " (" + channel_nuclei + ")" + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		
		minsizefilter(nuclei_size);
		nucleus_number = roiManager("count");
		data_nuclei = Array.concat(data_nuclei,nucleus_number);
		
		selectWindow(current_file + " (" + channel_marker + ")");
		run("Size...", "width=850 height=640 depth=1 constrain interpolation=None");
		
		newImage("black", "8-bit black", 850, 640, 1);
		run("Merge Channels...", "c1=black c2=["+current_file +  " (" + channel_marker + ")] c3=black create");
		run("Stack to RGB");
		close("Composite");
		selectWindow("Composite (RGB)");
		saveAs("PNG", results_directory + "/Composite_RGB.png");
		
		ab_number = Ilastik_Processing_Windows(ilastik_directory, ilastik_project_filepath, results_directory + "/Composite_RGB.png", results_directory);
		
		print("Die von Ilastik gemessene AB-Zahl ist: " + ab_number);
		
		data_antibodies = Array.concat(data_antibodies, ab_number);
		
		close(current_file +  " (" + channel_nuclei + ")");
		close(current_file +  " (" + channel_marker + ")");	
//		close(current_file +  " (" + channel_marker + ") Maxima");
		
		print("> Bild " + (i+1) + " von " + list.length + " wurde ausgewertet.");

	}
	close("*");
	run("Clear Results");
	Array.show("Results (row numbers)", data_filenames, data_nuclei, data_antibodies);
	updateResults();
	Table.save(results_directory + "/" + filename_results + ".csv");
}

function intensity () {
	
}

function orientation(image_directory, results_directory, filename_results, channel_marker) { 
	for (i=0, i<list.length, i++) {
		open("" + image_directory + "/" + list[i]);
		
	}
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

function Ilastik_Processing(ilastik_program_directory, ilastik_project_filepath, ilastik_image_input, results_directory) {
		print("Performing Ilastik antibody count...");

		q ="/";
		
		ilastik_program_directory = replace(ilastik_program_directory+"/run_ilastik.sh", "\\", "/");
		ilastik_project_filepath = replace(ilastik_project_filepath, "\\", "/");
		ilastik_output_directory = results_directory + q + "ilastik_temp_savefile.csv";
			
		ilcommand = ilastik_program_directory +" --headless --project=" + ilastik_project_filepath + " --csv-export-file=" + ilastik_output_directory + " " + ilastik_image_input;
		print(ilcommand);
		
		// Create Batch and run
		run("Text Window...", "name=Shell");
		//print("[Batch]", "@echo off" + "\n");
		print("[Shell]", "#! /bin/bash");
		print("[Shell]", "\n" + ilcommand);
		run("Text...", "save=[" + results_directory + "/Ilastikrun.sh]");
		selectWindow("Ilastikrun.sh");
		run("Close"); 
		
		run_ilastik = results_directory + "/Ilastikrun.sh";
		print(run_ilastik);
		
		exec("chmod", "+x", run_ilastik);
		exec(run_ilastik);

		File.delete(run_ilastik);
		print("");
		
		file_contents = File.openAsString(ilastik_output_directory);
		substr = split(file_contents, ",");
		ab_number = parseFloat(substr[1]);

		return ab_number;

}

function Ilastik_Processing_Windows(ilastik_program_directory, ilastik_project_filepath, ilastik_image_input, results_directory) {
		print("Performing Ilastik antibody count...");

		q ="/";
		
		ilastik_program_directory = replace(ilastik_program_directory+"/ilastik.exe", "\\", "/");
		ilastik_project_filepath = replace(ilastik_project_filepath, "\\", "/");
		ilastik_output_directory = results_directory + q + "ilastik_temp_savefile.csv";
	
		ilcommand = "\"" + ilastik_program_directory +"\" --headless --project=\"" + ilastik_project_filepath + "\" --csv-export-file=\"" + ilastik_output_directory + "\" \"" + ilastik_image_input + "\"";
		print(ilcommand);
		waitForUser;
		// Create Batch and run
		run("Text Window...", "name=Batch");
		//print("[Batch]", "@echo off" + "\n");
		print("[Batch]", ilcommand);
		run("Text...", "save=[" + results_directory + "/Ilastikrun.bat]");
		selectWindow("Ilastikrun.bat");
		run("Close"); 
		
		run_ilastik = results_directory + "/Ilastikrun.bat";
		print(run_ilastik);
		
		exec("cmd", "/c", run_ilastik);
		exec(run_ilastik);

//		File.delete(run_ilastik);
		print("");
		
		file_contents = File.openAsString(ilastik_output_directory);
		substr = split(file_contents, ",");
		ab_number = parseFloat(substr[1]);

		return ab_number;
}

function set_batchmode_toggle(batchmode_toggle) { 
	if (batchmode_toggle == "AN") {
		return false;
	} else if (batchmode_toggle == "AUS") {
		return true;
	}
}

  function getBar(p1, p2) {
        n = 20;
        bar1 = "--------------------";
        bar2 = "********************";
        index = round(n*(p1/p2));
        if (index<1) index = 1;
        if (index>n-1) index = n-1;
        return substring(bar2, 0, index) + substring(bar1, index+1, n);
  }
