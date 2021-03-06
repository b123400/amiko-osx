AmiKo/CoMed für macOS
=====================

## Funktionen
* Dark/Light Mode support  ;)
* Rezept 
  * erstellen
  * importieren
  * exportieren
    * Email
    * AirDrop
    * Finder
  * Rezept [drucken](https://github.com/zdavatz/amiko-osx/files/1992084/RZ_2018-05-08T151321.pdf)
  * Etikette [drucken](https://user-images.githubusercontent.com/4953/40113867-2336e086-590b-11e8-9617-9fbe284bc9f7.png), 89x36mm mit `Dymo 450` Label-Printer getestet.
  * Einnahmeanweisung pro Packung hinterlegen
* Adresse 
  * aus macOS Adressbuch übernehmen
  * im AmiKo Adressbuch speichern und verwalten
  * mit SmarCard Leser importieren von der Krankenkasse SmartCard. Getestet mit [Xystec SmartCard Reader](http://www.xystec.info/USB-Chipkartenleser-HBCI-faehig-Smart-Card-PX-8935-919.shtml).
* Voll-Text-Suche
* Fachinfo-Suche nach
  * Markennamen
  * ATC-Code (Original/Generikum)
  * Hersteller
  * Swissmedic-Nummer
  * BAG/Swissmedic Kategorie
* [Wortanalyse](https://www.youtube.com/watch?v=ETGQaxiJFi4), erstellt für [Pharmaceutical Care Research Group](https://pharma.unibas.ch/de/research-groups/pharmaceutical-care/) Klingelbergstrasse 50, 4056 Basel, Switzerland
  * Apfel+A zum DB aktualisieren
  * File mit einem oder zwei Wörtern pro Zeile erstellen (UTF-8 codiert). Voll-Text-Suche verwenden um Wörter zu finden.
  * Apfel + I > Input-File wählen
  * Export von allen Sätzen in der Fachinfo, welche die gewünschten Wörter enthalten.
  * Wortanalyse.csv enthält folgende Felder: 
    * Suchbegriff, Wirkstoff, Markenname, ATC-Code, Kapitelname, Satz mit Wort, Link zur [Online Referenz](https://amiko.oddb.org)
  * Das CSV-File mit mehreren tausend Zeilen, lässt sich am besten mit [LibreOffice](https://www.libreoffice.org/download/download/) öffnen. Delimiter ist ein _;_
  * Beispiel [Input-File](http://www.ywesee.com/uploads/AmiKo/Wortliste.csv.txt)
  * Beispiel [Output-File](http://www.ywesee.com/uploads/AmiKo/Wortanalyse.csv.txt)
    
## .amk File lesen
*  `cat RZ_2017-09-22T211907.amk | base64 --decode` wird das JSON File auslesen.

## Datenbankverzeichnis
* amiko-osx/AmiKoOSX
  * `wget http://pillbox.oddb.org/amiko_db_full_idx_de.zip`
  * `wget http://pillbox.oddb.org/amiko_db_full_idx_fr.zip`
  * `wget http://pillbox.oddb.org/amiko_frequency_de.db.zip`
  * `wget http://pillbox.oddb.org/amiko_frequency_fr.db.zip`

## Build Target
* 10.12

## License
* [GPLv3.0](https://github.com/zdavatz/amiko-osx/blob/master/LICENSE.txt)
