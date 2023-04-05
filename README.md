# Verwendung von Max ImageJ Macro

## Installation

### ImageJ

Sofern auf dem Rechner noch nicht Fiji installiert ist, dieses hier (https://fiji.sc/) herunterladen und installieren.

### Installation nötiger Plugins

Für die Ausfühung aller Funktionen des Macros werden einige Plugins für Fiji benötigt. Um diese zu installieren im Menü `Help -> Update...` anklicken. Es kann passieren, dass ImageJ zunächst selbst Updates installieren will. Das sollte man erlauben und im Anschluss einmal Fiji schließen und neu öffnen. Dann bei `Help -> Update...` auf den Knopf `Manage Update Sites` klicken und in der Liste den Haken bei `BIG-EPFL`,  `CSBDeep` and `StarDist` setzen. Danach auf `Close` und `Apply Changes`, und nach Beendigung des Updates FIJI nochmals neu starten.

### Macro herunterladen

Das Macro ist auf Github unter https://github.com/Deichmatrix/physiology-batch-processing zu finden. Um es direkt herunterzuladen, kann man diesem Link hier folgen (https://raw.githubusercontent.com/Deichmatrix/physiology-batch-processing/main/batch-processing.ijm) und per Rechtsklick unter `Seite speichern unter...` direkt in den gewünschten Ordner speichern.

## Benutzung des Makros

### Makro starten

Um das Macro zu starten, wird in der Menüleiste von Fiji `Plugins -> Macros -> Edit...` angeklickt und die zuvor heruntergeladene Macro-Datei ausgewählt. Im neu geöffneten Fenster sollte im Menü bei `Language` die Option `ImageJ Macro` ausgewählt sein. Dann kann man unten links auf den `Run` Button klicken und das folgende Fenster sollte erscheinen:

![GUI des Macros](/docs/MacroGUI.png)

### Nutzeroberfläche

**Ordner Bilder:** Hier wird der Pfad zum Ordner, welcher die zu analysierenden Bilder enthält, ausgewählt. Dies müssen die kombinierten Bilder mit allen Farbkanälen (*Channel 4*) sein.

**Ordner Ergebnisse:** Hier wird die Ergebnistabelle abgespeichert.

**Name Ergebnisse:** Dateiname der Ergebnisstabelle. 

> *Achtung:* Dieses Feld muss nach jedem Durchlauf geändert werden, wenn man nicht möchte, dass die vorherige Ergebnisdatei überschrieben wird.

**Messmodus:** Legt den Modus fest, nach dem die Bilder analysiert werden. (Diese werden im Nachfolgenden noch erklärt.)

**Kanal Nuclei:** Bestimmt den Farbkanal, in dem die Nuclei zu finden sind. (Bei DAPI-Färbung üblicherweise `blue`.)

**Kanal Marker:** Bestimmt den Farbkanal, in dem der zu messende Marker zu finden ist. (Bei Phalloidin beispielsweise `red`.)

> Achtung: Nuclei und Marker können nicht im gleichen Farbkanal liegen.

**Nuclei min. Size (µm²):** Bei der Selektion von Nuclei werden teilweise Artefakte als Nuclei erkannt. Mit dieser Option kann ein Filter eingestellt werden, welcher solche Objekte unter einer physiologisch sinnvollen Größe aus der Selektion herausfiltert.

**Beobachtungsmodus:** Erlaubt das An- und Ausschalten des Beobachtungsmodus. Ist dieser an, werden die einzelnen Bearbeitungsschritte angezeigt. Dies ist langsamer, aber beim ersten Durchlauf eine gute Kontrolle, ob auch alles richtig funktioniert.

**Ordner Ilastik:** Legt den Ordner fest, in dem Ilastik installiert ist. (*Nur im Messmodus "AB count" relevant. Funktioniert nur unter Linux*)

**Ilastik Project (.ilp):** Legt den Dateipfad zum Ilastik-Projekt fest, welches zur Auswertung verwendet wird.  (*Nur im Messmodus "AB count" relevant. Funktioniert nur unter Linux*)

Zum Start des Makros muss `OK` gedrückt werden.

## Messmodi

### Intensity (nuclei)

Dieser Modus misst die durchschnittliche Intesität des Markerkanals im Bereich der Nuclei aus dem Nucleuskanal. Dazu werden die Nuclei zunächst mit dem Plugin *Stardist* automatisch markiert und die einzeln ausgewählten Selektionen zu einem einzigen Messbereich zusammengefasst. Dieser Messbereich wird dann mit der Fiji eigenen Messfunktion auf seine durchschnittliche Intensität im Markerkanal ausgewertet. Die Ergebnistabelle enthält zusätzlich die Anzahl der vorhandenen Nuclei und die Gesamtfläche des Messbereichs. 

Die automatische Selektion der Nuclei mittels Stardist basiert auf dem "Versatile (fluorescent nuclei)"-Modell, welches mit dem Plugin bereits mitgeliefert wird. Es hat sich bei der Auswertung von HUVECs als geeignet erwiesen. Allerdings sind Machine Learning Modelle nicht immer allgemein übertragbar, wenn zu stark von den ursprünglich verwendeten Trainingsdaten abgewichen wird. Sollte dieses Macro also für andere Daten als HUVECs bei 60-facher Vergrößerung verwendet werden, muss die Eignung des Modells zunächst manuell überprüft werden. Im Bedarfsfall ist ein neues Modell zu trainieren.
