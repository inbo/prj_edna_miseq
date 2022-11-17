#!/bin/bash

#################################################################


#BASED ON script from Annelies Haegeman
#https://gitlab.com/ahaegeman/eDNA_INBO-ILVO/-/blob/master/eDNA_demultiplexing.sh
#installeren dos2unix om het bash script in WSL te lopen zonder foutmelding $'\r' not found 
#sudo apt-get install dos2unix
#dos2unix file
#Dit komt vermoedelijk omdat enkel LF verwacht wordt zonder CR

########################################################################

### >>> DEFINITIE VARIABELEN EN ARGUMENTEN

#STEP1: read table and F and R reads using flagged arguments
#Indien dynamisch kan je hieronder de -b, -r, -f die aan het script meegegeven wordt 
# bewaren in variabelen

#while getopts b:f:r:fe:re: option
#do
#case "${option}" in
#b) InputBarcodeTable=${OPTARG};;
#f) Freads=${OPTARG};;
#r) Rreads=${OPTARG};;
#esac
#done

#STAP 1 (niet dynamisch)
#Hier gebeurt hetzelfde als hierboven, maar worden de variabelen statisch ingegeven
Freads="Riaz1_S1_L001_R1_001.fastq"
Rreads="Riaz1_S1_L001_R2_001.fastq"
InputBarcodeTable="ligation1.txt"
SabreBarcodeTable0="SabreBarcodeTable1A.txt"
SabreBarcodeTable1="SabreBarcodeTable1B.txt"


#STAP 2: maak sabre barcodetabellen

#Lees de 3 kolommen uit het bestand temp2
#Het eerste bestand bevat de forward adapter als eerste kolom
#Het tweede bestand bevat de reverse adapter als eerste kolom
#zo coveren we alles die begint met 1 van beide adaptoren
while read col1 col2 col3; do
  echo -e "$col2""\t""$col1"_R1.fq"\t""$col1"_F1.fq >> $SabreBarcodeTable0;		#first barcode sequence for this sample
	echo -e "$col3""\t""$col1"_R2.fq"\t""$col1"_F2.fq >> $SabreBarcodeTable1;		#second barcode sequence for this sample
done < $InputBarcodeTable

#STAP 3: demultiplexen 1e ronde

#Aangezien we met 2 adaptoren werken per staal (1 aan het begin en 1 aan het einde)
#Moeten we sabre laten lopen voor de eerste adaptor, en daarna voor de tweede adaptor
#In beide stappen is niet op voorhand gekend in welke richting de DNA loopt
#Dus soms zal de eerste adaptor eerst staan en in andere gevallen de tweede

sabre pe -f $Freads -r $Rreads -b $SabreBarcodeTable0 -u unknown-round1-1.fq -w unknown-round1-2.fq
sabre pe -f $Freads -r $Rreads -b $SabreBarcodeTable1 -u unknown-round1bis-1.fq -w unknown-round1bis-2.fq

#STAP 4: Voeg de bestanden samen

#We voegen alle bestanden voor de verschillende stalen terug samen
#Omdat we willen dat de forward reads beginnen met de nog niet gedetecteerde barcode
#wisselen we hier de Forward en Reverse om bij de volgende sabre stap

FILES=( *_F1.fq)
#Loop over all files and do all the commands
for f in "${FILES[@]}" 
do 
#definieer de variabele SAMPLE die gehaald wordt uit de filenaam zonder extensie
SAMPLE=`basename $f _F1.fq`
#voeg de FWD reads samen van beide sabre en doe hetzelfde met de REV reads
cat "$SAMPLE"_F1.fq "$SAMPLE"_F2.fq > "$SAMPLE"_round1_F.fq	#concatenate the F reads
cat "$SAMPLE"_R1.fq "$SAMPLE"_R2.fq > "$SAMPLE"_round1_R.fq	#concatenate the R reads
#Kuis dit op, want heel veel schijfruimte
rm "$SAMPLE"_F1.fq "$SAMPLE"_F2.fq "$SAMPLE"_R1.fq "$SAMPLE"_R2.fq	#remove original reads from first round
done

#STAP 5: TWEEDE DEMUX RONDe

#Nu is dit apart per staal omdat we nu toch een file voor ieder staal hebben
#Dus voor ieder staal maken we een barcodetabel 
#(van 2 regels, 1 voor de FWD en 1 voor de REV read)
#Met > wordt het bestand overschreven, met >> gebeurt een append

#Naam van het barcodebestand (we zullen de inhoud telkens overschrijven met >)
SabreBarcodeTable2="Barcode_table_for_Sabre_round2.txt"
#We lezen rij per rij de Inputbarcode tabel in
#En bij iedere regel doen we dan direct een sabre DEMUX
#Ook hier keren we de F-R volgorde om zoals voorheen
#
while read col1 col2 col3; do 
		echo -e "$col2""\t""$col1"_round2_F1.fq"\t""$col1"_round2_R1.fq > $SabreBarcodeTable2;		#first barcode sequence for this sample
		echo -e "$col3""\t""$col1"_round2_R2.fq"\t""$col1"_round2_F2.fq >> $SabreBarcodeTable2;		#second barcode sequence for this sample
		sabre pe -f `echo "$col1"_round1_F.fq` -r `echo "$col1"_round1_R.fq` -b $SabreBarcodeTable2 -u `echo "$col1"_unknown_round2_1.fq` -w `echo "$col1"_unknown_round2_2.fq`
done < $InputBarcodeTable

#opkuis van de bestanden
rm $SabreBarcodeTable2 $SabreBarcodeTable0 $SabreBarcodeTable1
rm unknown-round1-1.fq unknown-round1-2.fq 
rm unknown-round1bis-1.fq unknown-round1bis-2.fq

#STAP 6: Voeg per files van de tweede ronde samen

FILES=( *_round2_F1.fq )

#loop door alle bestanden en voeg de F1 en F2 samen als F en de R1 en R2 als R
for f in "${FILES[@]}" 
do 
  SAMPLE=`basename $f _round2_F1.fq`	#Define the variable SAMPLE who contains the basename where the extension is removed (_round2_F1.fq)
  cat "$SAMPLE"_round2_F1.fq "$SAMPLE"_round2_F2.fq > "$SAMPLE"_F.fq	#concatenate the F reads
  cat "$SAMPLE"_round2_R1.fq "$SAMPLE"_round2_R2.fq > "$SAMPLE"_R.fq	#concatenate the R reads

  #verwijder alle F1, F2, R1, R2 bestanden uit Ronde 2, die zijn immers naar F en R gemerged
  rm "$SAMPLE"_round2_F1.fq "$SAMPLE"_round2_F2.fq 
  rm "$SAMPLE"_round2_R1.fq "$SAMPLE"_round2_R2.fq	
  #Verwijder Ronde 1, want deze bestanden zijn als bron gebruikt voor Ronde 2
  #Alles uit Ronde 1 dat geldig was is meegenomen naar ronde 2
  #En zijn dus niet meer relevant (en ook niet correct meer, want hier is niet voor beide adapters getest)
  rm "$SAMPLE"_round1_F.fq "$SAMPLE"_round1_R.fq 
done

#Ultieme cleanup van ronde 2
rm *_unknown_round2_1.fq # "unknown" files
rm *_unknown_round2_2.fq # "unknown" files





