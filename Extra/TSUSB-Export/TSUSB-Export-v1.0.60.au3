#cs ----------------------------------------------------------------------------

	 AutoIt Version:
	 Author:         Hans de Jong

	 Script Function:


#ce ----------------------------------------------------------------------------

; -----------------------------------------
; Make sure to update the version number when having made changes
; -----------------------------------------

$Version="1.0.57"

if @Compiled=False then $Version = stringreplace(@ScriptName,".au3","")


; -----------------------------------------
; #includes
; -----------------------------------------
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <Misc.au3>
#include <WinAPIvkeysConstants.au3>
#include <WinAPIFiles.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <WinAPIShellEx.au3>
#include <AutoItConstants.au3>
#include <GuiConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <AVIConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <Date.au3>
;#include "E:\Hans\Documents\AutoIT\CompInfo.au3"

;ConsoleWrite(_ComputerGetMotherboard() & @CRLF)
 ;Exit


$USBstickPrefixTurtleSt = "TURTLEST"
$USBstickPrefixUpdate = "UPDATETS"
$ExtraDataFileName = "ExtraData.txt"
$DesktopUpdateName = "DesktopUpdate"
$DocumentsUpdateName= "DocumentsUpdate"
$ExitForUpdateFileName = "MustExit.txt"

$SectionExitForUpdate="ExitForUpdateInfo"
$PathToOpenKW="PathToOpen"
$PathToOpenMessageKW="Message"
$FileToExecuteKW="FileToExecute"

Global Const $Password="Techniek"


Global Const $ErrorBackgroundColor = 0xFF0000
Global Const $ErrorForegroundColor = 0xFFFFFF

;First find the path of the download folder on this machine
Local $s_Path_Downloads = _WinAPI_ShellGetKnownFolderPath($FOLDERID_Downloads)
Local $s_Path_Documents = _WinAPI_ShellGetKnownFolderPath($FOLDERID_Documents)
Local $s_Path_Desktop = _WinAPI_ShellGetKnownFolderPath($FOLDERID_Desktop)


;~ If you're passing strings with spaces, then you will need to escape these using "double quotes" in your commandline string.
;~ @@SyntaxHighlighting@@ $CmdLine[0] ; Contains the total number of items in the array. $CmdLine[1] ; The first parameter. $CmdLine[2] ; The second parameter. ... $CmdLine[nth] ; The nth parameter e.g. 10 if the array contains 10 items. @@End@@
;~ So if you were to run your script directly using AutoIt3.exe:
;~ @@SyntaxHighlighting@@ AutoIt3.exe myScript.au3 param1 "This is a string parameter" 99 @@End@@ @@SyntaxHighlighting@@ $CmdLine[0] ; This contains 3 parameters. $CmdLine[1] ; This contains param1 and not myScript.au3 as this is ignored when running non-compiled. $CmdLine[2] ; This contains This is a string parameter. $CmdLine[3] ; This contains 99. $CmdLineRaw ; This contains myScript.au3 param1 "This is a string parameter" 99. @@End@@
;~ So if you were to use the compiled executable by passing commandline parameters:
;~ @@SyntaxHighlighting@@ myProg.exe param1 "This is a string parameter" 99 @@End@@ @@SyntaxHighlighting@@ $CmdLine[0] ; This contains 3 parameters. $CmdLine[1] ; This contains param1. $CmdLine[2] ; This contains This is a string parameter. $CmdLine[3] ; This contains 99. @@End@@


; --------------------------------------------------------------------
; -- Read the .INI file ----------------------------------------------
; --------------------------------------------------------------------

; The .INI file is either in a TurtleStich folder in the Documents folder (prio 1) or in
; the Desktop folder (prio 2)
; The .INI file is optional
; Default values in case of an absent .INI file or an absent parameter is specified in the IniRead commands below

$FirstPathIniFolder = @MyDocumentsDir & "\TurtleStitch\"
ConsoleWrite($FirstPathIniFolder & @CRLF)
$AlternatePathIniFolder = @DesktopDir & "\TurtleStitch\"
ConsoleWrite($AlternatePathIniFolder & @CRLF)
$IniFileName = "TSUSB-Export.ini"

; Determine where the .ini file is - if any
$IniFilePath = $FirstPathIniFolder & $IniFileName
If FileExists($IniFilePath) = 0 Then
	$IniFilePath = $AlternatePathIniFolder & $IniFileName
	If FileExists($IniFilePath) = 0 Then $IniFilePath = ""
EndIf

ConsoleWrite("$IniFilePath=" & $IniFilePath & @CRLF)
$SectionName = "TurtleStitch"      ; all parameters are in a section labeled as [TurtleStitch]


$MaxColors = Int(IniRead($IniFilePath, $SectionName, "MaxColors", "1"))
$MaxStitches = Int(IniRead($IniFilePath, $SectionName, "MaxStitches", "7000"))
$XMax = Int(IniRead($IniFilePath, $SectionName, "XMax", "100"))
$YMax = Int(IniRead($IniFilePath, $SectionName, "YMax", "100"))
$ConfigLanguage = StripComment(IniRead($IniFilePath, $SectionName, "Language", "OS"))
$StoreLocal = StripComment(IniRead($IniFilePath, $SectionName, "StoreLocal", "Y"))
$MaxTimeBetweenSavesMin = Int(IniRead($IniFilePath, $SectionName, "MaxTimeBetwSaves", "5"))
$MaxTimeBetweenSavesSec = $MaxTimeBetweenSavesMin * 60
$DispCustEndMsg = StripComment(IniRead($IniFilePath, $SectionName, "DispCustEndMsg", "N"))
$RotationAllowed = StripComment(IniRead($IniFilePath, $SectionName, "RotationAllowed", "N"))
$LocalServerFolder = StripComment(IniRead($IniFilePath, $SectionName, "LocalServerFolder", ""))

$doublequote='"'
$LocalServerFolder=$doublequote & $LocalServerFolder & $doublequote
$whattorun = "python -m http.server --directory " & $LocalServerFolder & "," & $LocalServerFolder
$whattorun= "python -m http.server --directory E:\Hans\Documents\Turtlestitch\Offline\turtlestitch-2.11.3 --bind 127.0.0.1"
;ConsoleWrite($whattorun & @CRLF)
;$result=run($whattorun)
;ConsoleWrite("$result=" & $result & "@error=" & @error & @CRLF)
;WinSetState($result,"",@SW_MINIMIZE)



;-----------------------------
;---- Update the language to take into account the system language
;-----------------------------

Global $SupportedLanguages
; Language defines
$LangEnglish = "09"
$LangDutch = "13"
$LangGerman = "07"
$LangDanish = "06"
$LangItalian = "10"
$LangSweden = "1D"
$LangTurkish = "1F"
$LangSpanish = "0A"
$LangFrench = "OC"


;$SupportedLanguages = $LangEnglish & "|" & $LangDutch & "|" & $LangGerman & "|" & $LangDanish & "|" & $LangTurkish

Global Const $LanguageActive = 0
Global Const $LanguageName = 1
Global Const $LanguageNumber = 2
Global Const $LanguageDetailWindowX = 3
Global Const $LanguageDetailWindowY = 4

Global $LanguageArray[9][5]=[ _
	[  True, "English", $LangEnglish, 0, 0 ], _
	[  True, "Nederlands", $LangDutch, 0, 0 ], _
	[  True, "Deutsch", $LangGerman, 0, 0 ], _
	[  True, "Dansk", $LangDanish, 0, 0 ] , _
	[  False, "Italiano", $LangItalian, 0, 0 ] , _
	[  False, "Svenska", $LangSweden, 0 ], _
	[  True, "Türkçe", $LangTurkish, 0 ], _
	[  False, "Español", $LangSpanish, 0, 0 ], _
	[  False, "Français", $LangFrench, 0 ] _
	]

; create the string with all supported languages
Local $i
For $i = 0 to UBound($LanguageArray, 1) - 1

	if $LanguageArray[$i][$LanguageActive] = True then
		if $i <> 0 then $SupportedLanguages=$SupportedLanguages & "|"
		$SupportedLanguages=$SupportedLanguages & $LanguageArray[$i][ $LanguageName]
	EndIf
Next

ConsoleWrite ("SupportedLanguages=" & $SupportedLanguages & @CRLF)



;$LanguageArray[$Language,$OSLanguageIndex] = $OSLangDutch

; First set the default language to English
$Language=$LangEnglish

If $ConfigLanguage = "OS" Then
	ConsoleWrite(@OSLang & @CRLF)
	$OSLanguageNumber = StringMid(@OSLang, 3, 2)
	ConsoleWrite("OSLang=" & $OSLanguageNumber & @CRLF)

	;look whether the language is supported. If so, choose that language, otherwise the default English stays

	for $i=0 to UBound($LanguageArray, 1) - 1
		if $OSLanguageNumber = $LanguageArray [$i][$LanguageNumber] then
			; the OS language is supported, therefore set the language to the OS language
			$Language=$OSLanguageNumber
			ExitLoop
		EndIf
	Next
else
	$Language=LanguageName2Language($ConfigLanguage)
EndIf

ConsoleWrite("Language="& $Language & @CRLF)

func LanguageName2Language ($LangName)
	; First set the default language to English
	Local $Lang=$LangEnglish
	for $i=0 to UBound($LanguageArray, 1) - 1
		if $LangName = $LanguageArray [$i][ $LanguageName] then
			$Lang=$LanguageArray[$i][ $LanguageNumber]
			ExitLoop
		EndIf
	Next
	Return $Lang
EndFunc

func Language2Index ($Lang)
	; First set the default language to English
	for $i=0 to UBound($LanguageArray, 1) - 1
		if $Lang = $LanguageArray [$i][ $LanguageNumber] then
			Return $i
		EndIf
	Next

EndFunc

; These are the default filenames of TurtleStitch separated by vertical bars. If we find a file with one of these names, we know that the user has not used Save As and given the file an own name
Global $ForbiddenNames = "zonder titel|Untitled|unavngivet|Unbenannt|senza titolo|Namnlös|kaydedilmemiş|Sans titre|sin titulo|turtlestitch"
global $ForbiddenName="turtlestitch"



ConsoleWrite("MaxColors = " & $MaxColors & @CRLF)
ConsoleWrite("$MaxStitches = " & $MaxStitches & @CRLF)
ConsoleWrite("$XMax = " & $XMax & @CRLF)
ConsoleWrite("$YMax = " & $YMax & @CRLF)
ConsoleWrite("Language = " & $Language & @CRLF)
ConsoleWrite("$StoreLocal = " & $StoreLocal & @CRLF)
ConsoleWrite("$MaxTimeBetweenSavesMin = " & $MaxTimeBetweenSavesSec & @CRLF)
ConsoleWrite("$DispCustEndMsg = " & $DispCustEndMsg & @CRLF)

;----------------------------------------------------------------
;--- Set strings in local language
;----------------------------------------------------------------

; Declare all variables used for messages and texts
Global $msgNoDST, $msgNoXML, $msgInvalidName, $msgTooMuchTimeDiff, $msgTooManyColors, $msgTooLarge, $msgTooManyStitches, $msgCopyRetry, $msgUpdRetry, $msgNoUSBStick, $msgCopyError
Global $msgSuccess, $lblChooseLanguage, $mbtnEndScript, $mbtnContinue, $hdrStopScript, $msgSure2StopTheScript, $hdrAbort, $mbtnOK, $mbtnCancel, $hdrReallyStop, $hdrRetry, $hdrContinueEdit
Global $msgContinueEdit, $mbtnBackup, $mbtnEdit, $hdrNoDST, $hdrNoXML, $mbtnClose, $mbtnEndScript, $btnContinue
Global $msgXMLDSTnamesNotMatching, $msgCloudSaving, $mlblPassword,$mlblST, $NewestDSTFileTime, $NewestXMLFileTime, $XML2DSTdiff, $NewestXMLFilePath, $hdrDetails, $hdrDone

Global $hDetailsGUI
Global $grpDST, $lblLA, $lblCO, $txtLabel, $txtColor, $mlstForbidden, $lblXMLfile, $lblDSTfile
Global $txtDSTPath, $cmbLanguage, $lblLanguage, $lblVersion, $lblForbidden, $btnCancel, $mbtnAbort, $lblOverridePW
Global $chkIgnoreErrors, $txtError, $XMLPath2Show, $lblMinX, $lblMinY, $lblPlusX, $lblPlusY, $txtPlusY
Global $txtMinY, $txtMinX, $txtPluxX, $lblSizeX, $txtSizeY, $txtSizeX, $lblSizeY, $grpMax, $txtMaxX
Global $txtMaxY, $txtMaxColor, $lblTimeDiff, $txtTimeDiff, $txtPassword, $txtXMLtime, $txtDSTtime, $lblMaxTime
Global $txtMaxTime, $chkTryLandscape, $mgrpDST, $mlblLA,$mlblXMLfile, $mlblDSTfile, $mlblForbidden,	$mlblMinX, $mlblMinY,$mlblPlusX, $mlblPlusY,$mlblCO
Global $mlblOverridePW, $mchkIgnoreErrors,$mlblSizeX, $mlblSizeY, $mgrpMax, $mlblTimeDiff, $mlblMaxTime, $mchkTryLandscape,$mtxtError, $mtxtTimeDiff, $mtxtPassword
global $mtxtDSTtime, $mtxtMaxTime, $mlblInitFile, $vtxtInitFile

Global $Name, $ActColors, $MinX, $PlusX, $MinY, $PlusY, $SizeX, $SizeY, $StitchCount
Global $GUIhandle2Close

Global $hdrStarting, $msgDesktopCopyStart, $msgDesktopUpdateSuccess, $hdrSucces, $hdrFailure, $msgDocumentsCopyStart, $msgDocumentsUpdateSuccess
Global $msgDocumentsUpdateFailed, $msgSystemInfoWritten, $msgDesktopUpdateFailed
Global $hdrMustExit, $msgMustExit


; Declare the messageflag variables
Global $msgXMLDSTnamesNotMatchingFlag, $msgTooMuchTimeDiffFlag, $msgTooManyColorsFlag, $msgTooLargeFlag, $msgTooManyStitchesFlag, $msgForbiddenNameFlag
Global $msgCloudSavingFlag, $msgYTooLargeFlag, $msgXTooLargeFlag, $msgForbiddenLabelFlag, $msgForbiddenLabel
Global $ErrorFlags, $msgForbiddenName


; Now set the stings in the local language for the first time. This is also done each time after a change in language is made
SetMessagesInLanguage()

Func SetMessagesInLanguage()

	; Note that all messages that are conditionally displayed in the Details panel have a Flag variable as well. This is because we must show the correct translated message
	; The error message to be displayed is remembered based on the flag. This holds for error messages as well as the message for the location of the .XML file

	; The settings for English will always be set, so that they are the default in case a language is not supported or not all strings have been translated for that language

	$hdrNoDST = "No DST file present"
	$msgNoDST = "You have not yet created a .DST file for the embroidery machine. Or you have not placed it in the downloads folder " & $s_Path_Downloads & ". Click on Export as Tajima/DST"
	$hdrNoXML = "No XML file present"
	$msgNoXML = "You haven't saved your design yet. Or you haven't placed it in the downloads folder " & $s_Path_Downloads & ". Make sure your file has your own name."

	$msgForbiddenNameFlag = 1
	$msgForbiddenName = "You have used a forbidden name as filename. You should specify your own name when saving the project. Save again and then export the .DST file."

	$msgXMLDSTnamesNotMatchingFlag = 2
	$msgXMLDSTnamesNotMatching = "The latest XML file and the latest DST file do not belong together"

	$msgTooMuchTimeDiffFlag = 4
	$msgTooMuchTimeDiff = "The time between saving your design as an .XML file and exporting as a .DST file is more than " & $MaxTimeBetweenSavesMin & " minutes. Save again and export again."

	$msgTooManyColorsFlag = 8
	$msgTooManyColors = "You have used too many colors in your design. The maximum is" & $MaxColors & "."

	$msgTooLargeFlag = 16
	$msgTooLarge = "Your design does not fit in the embroidery hoop. Change your design so that it is a maximum of " & $XMax & " mm wide and " & $YMax & " mm high."

	$msgTooManyStitchesFlag = 32
	$msgTooManyStitches = "You have too many stitches in your design. Limit it to a maximum of " & $MaxStitches & " stitches."

	$msgCloudSavingFlag = 64
	$msgCloudSaving = " The .XML file should be saved to the cloud. Did you?"

	$msgXTooLargeFlag = 128
	$msgYTooLargeFlag = 256

	$msgForbiddenLabelFlag=512
	$msgForbiddenLabel="The name in the label field in the .DST file is forbidden. You can solve this by saving the design under your own name and then exporting to .DST again"

	$hdrRetry = "Try again"
	$msgCopyRetry = "Remove the USB stick. If there was an error, fix it, save and export again, and then put the USB stick back in."
	$msgUpdRetry = "Remove the USB stick. If there was an error, fix it, and then put the USB stick back in."
	$msgNoUSBStick = "The USB stick has been removed."
	$msgCopyError = "Writing to the USB stick failed."
	$msgSuccess = "Your design has been written to the USB stick." & @CRLF & "Remove the USB stick from the laptop." & @CRLF & "Pick up a piece of felt and go to the embroidery machine."
	$lblChooseLanguage = "Language"
	$btnEndScript = "End Script"
	$btnContinue = "Continue"
	$hdrStopScript = "Stop or Continue"
	$msgSure2StopTheScript = "Are you sure you want to stop the script?"
	$hdrAbort = "Abort"
	$mbtnOK = "OK"
	$mbtnCancel = "Cancel"
	$mbtnClose = "Close"
	$mbtnEndScript="Abort"
	$hdrReallyStop = "Really stop"
	$hdrContinueEdit = "Edit or Backup old design"
	$mbtnBackup = "Backup old"
	$mbtnEdit = "Edit old"
	$msgContinueEdit = "There are old designs on the USB stick. " & @CRLF & @CRLF & "Pressing " & $mbtnEdit & " will open the USB stick. Then drop the file to be edited in an open TurtleStitch Window." & @CRLF & @CRLF
	$msgContinueEdit = $msgContinueEdit & $mbtnBackup & " will move the .XML, .DST and " & $ExtraDataFileName & " files to a time stamped folder to avoid naming conflicts with the new design to be copied."

	; strings for the details panel
	$hdrDetails="Error Details and Context"
	$mgrpDST = "DST file info"
	$mlblLA = "LA (Label)"
	$mlblCO = "CO (Color)"
	$mlblST= "ST (Stitches)"

	$mlblXMLfile = "XML File"
	$mlblDSTfile = "DST File"

	$mlblLanguage = "Language"
	$mlblVersion = "Version"
	$mlblForbidden = "Forbidden Names"
	$mbtnCancel = "Cancel"
	$mbtnAbort = "Abort"
	$mlblOverridePW = "Password"
	$mchkIgnoreErrors = "Ignore Errors"

	$mlblMinX = "-X"
	$mlblMinY = "-Y"
	$mlblPlusX = "+X"
	$mlblPlusY = "+Y"

	$mlblSizeX = "Size X (mm)"
	$mlblSizeY = "Size Y (mm)"
	$mgrpMax = "Max Values"

	$mlblTimeDiff = "Time Difference (s)"

	$mlblMaxTime = "Max"

	$mchkTryLandscape = "Try Landscape"

	$mlblInitFile="Config File"
	$mNone="None" ; used if there is no init file

	$mlblPassword="Password"

	$hdrDone="Done"

	$hdrStarting="Starting"
	$msgDesktopCopyStart="Copying to desktop is starting"
	$msgDesktopUpdateSuccess="Update of desktop was successful"
	$msgDesktopUpdateFailed="Update of desktop failed"
	$hdrSucces="Succes"
	$hdrFailure="Failure"
	$msgDocumentsCopyStart="Copying to the Documents folder is starting"
	$msgDocumentsUpdateSuccess="Update of Documents folder was successful"
	$msgDocumentsUpdateFailed="Update of Documents folder failed"
	$msgSystemInfoWritten="Systeem info is being written to the USB stick"

	$hdrMustExit="Must Exit for Update"
	$msgMustExit="A window has now opened where you will find a file that you must execute yourself by double clicking. This program will be terminated when you click the button because it has to be updated itself. The file to execute yourself is: "



	$mtxtError = ""


	$mtxtTimeDiff = ""
	$mtxtPassword = ""
	$mtxtXMLtime = ""
	$mtxtDSTtime = ""

	$mtxtMaxTime = ""

	Switch $Language
		Case $LangDutch
			$hdrNoDST = "Geen DST-bestand aanwezig"

			$msgNoDST = "Je hebt nog geen .DST-bestand voor de borduurmachine aangemaakt. Of je hebt het niet in de map Downloads geplaatst " & $s_Path_Downloads & ". Klik op Exporteren als Tajima/DST"

			$hdrNoXML = "Geen XML-bestand aanwezig"

			$msgNoXML = "Je hebt je ontwerp nog niet opgeslagen. Of je hebt het niet in de map Downloads geplaatst " & $s_Path_Downloads & ". Zorg ervoor dat je bestand je eigen naam heeft."

			$msgForbiddenNameFlag = 1

			$msgForbiddenName = "Je hebt een verboden naam als bestandsnaam gebruikt. Je moet je eigen naam opgeven bij het opslaan van het project. Sla opnieuw op en exporteer vervolgens het .DST-bestand."

			$msgXMLDSTnamesNotMatchingFlag = 2

			$msgXMLDSTnamesNotMatching = "Het meest recente XML-bestand en het meest recente DST-bestand horen niet bij elkaar."

			$msgTooMuchTimeDiffFlag = 4

			$msgTooMuchTimeDiff = "De tijd tussen het opslaan van je ontwerp als een .XML-bestand en het exporteren als een .DST-bestand is langer dan " & $MaxTimeBetweenSavesMin & " minuten. Sla opnieuw op en exporteer opnieuw."

			$msgTooManyColorsFlag = 8

			$msgTooManyColors = "Je hebt te veel kleuren in je ontwerp gebruikt. Het maximum is " & $MaxColors & "."

			$msgTooLargeFlag = 16

			$msgTooLarge = "Je ontwerp past niet in de borduurring. Wijzig je ontwerp zodat het maximaal " & $XMax & " mm breed en " & $YMax & " mm hoog is."

			$msgTooManyStitchesFlag = 32

			$msgTooManyStitches = "Je ontwerp bevat te veel steken. Beperk het tot maximaal " & $MaxStitches & " steken."

			$msgCloudSavingFlag = 64

			$msgCloudSaving = "Het .XML-bestand zou in de cloud moeten zijn opgeslagen. Heb je dat gedaan?"

			$msgXTooLargeFlag = 128

			$msgYTooLargeFlag = 256

			$msgForbiddenLabelFlag = 512

			$msgForbiddenLabel = "De naam in het labelveld in het .DST-bestand is verboden. Je kunt dit oplossen door het ontwerp onder je eigen naam op te slaan en het vervolgens opnieuw naar .DST te exporteren."

			$hdrRetry = "Probeer het opnieuw"

			$msgCopyRetry = "Verwijder de USB-stick. Als er een fout is opgetreden, corrigeer deze dan, sla het ontwerp opnieuw op en exporteer het nogmaals, en plaats de USB-stick vervolgens terug."

			$msgUpdRetry = "Verwijder de USB-stick. Als er een fout is opgetreden, corrigeer deze dan en plaats de USB-stick vervolgens terug."

			$msgNoUSBStick = "De USB-stick is verwijderd."

			$msgCopyError = "Schrijven naar de USB-stick is mislukt."

			$msgSuccess = "Je ontwerp is naar de USB-stick geschreven." & @CRLF & "Verwijder de USB-stick uit de laptop." & @CRLF & "Pak een stuk vilt en ga naar de borduurmachine."

			$lblChooseLanguage = "Taal"

			$btnEndScript = "Script beëindigen"

			$btnContinue = "Doorgaan"

			$hdrStopScript = "Stoppen of doorgaan"

			$msgSure2StopTheScript = "Weet je zeker dat je het script wilt stoppen?"

			$hdrAbort = "Afbreken"

			$mbtnOK = "OK"

			$mbtnCancel = "Annuleren"

			$mbtnClose = "Sluiten"

			$mbtnEndScript="Afbreken"

			$hdrReallyStop = "Echt stoppen"

			$hdrContinueEdit = "Oud ontwerp bewerken of back-up maken"

			$mbtnBackup = "Maak Back-up"

			$mbtnEdit = "Bewerken"

			$msgContinueEdit = "Er staan ​​oude ontwerpen op de USB-stick. " & @CRLF & @CRLF & "Door op " & $mbtnEdit & " te drukken, wordt de USB-stick geopend. Sleep vervolgens het te bewerken bestand naar een geopend TurtleStitch-venster." & @CRLF & @CRLF

			$msgContinueEdit = $msgContinueEdit & $mbtnBackup & " zal de .XML-, .DST- en " & $ExtraDataFileName & " bestanden naar een map met tijdstempel verplaatsen om naamconflicten met het nieuwe ontwerp dat gekopieerd moet worden te voorkomen."

			; Teksten voor het detailvenster

			$hdrDetails="Foutdetails en context"

			$mgrpDST = "DST-bestandsinformatie"

			$mlblLA = "LA (Label)"

			$mlblCO = "CO (Kleur)"

			$mlblST = "ST (Steken)"

			$mlblXMLfile = "XML-bestand"

			$mlblDSTfile = "DST-bestand"

			$mlblLanguage = "Taal"

			$mlblVersion = "Versie"

			$mlblForbidden = "Verboden namen"

			$mbtnCancel = "Annuleren"

			$mbtnAbort = "Afbreken"

			$mlblOverridePW = "Wachtwoord"

			$mchkIgnoreErrors = "Fouten negeren"

			$mlblMinX = "-X"

			$mlblMinY = "-Y"

			$mlblPlusX = "+X"

			$mlblPlusY = "+Y"

			$mlblSizeX = "Afmeting X (mm)"

			$mlblSizeY = "Afmeting Y (mm)"

			$mgrpMax = "Maximaal"

			$mlblTimeDiff = "Tijdsverschil (s)"

			$mlblMaxTime = "Maximum"

			$mchkTryLandscape = "Probeer landschap"

			$mlblInitFile="Configuratiebestand"

			$mNone="Geen" ; gebruikt als er geen init-bestand is

			$mlblPassword="Wachtwoord"

			$hdrDone="Klaar"

			$hdrStarting="Starten"

			$msgDesktopCopyStart="Kopiëren naar bureaublad wordt gestart"

			$msgDesktopUpdateSuccess="Update van bureaublad is gelukt"

			$msgDesktopUpdateFailed="Update van bureaublad is mislukt"

			$hdrSucces="Geslaagd"

			$hdrFailure="Mislukt"

			$msgDocumentsCopyStart="Kopiëren naar de map Documenten wordt gestart"

			$msgDocumentsUpdateSuccess="Update van de map Documenten is gelukt"

			$msgDocumentsUpdateFailed="Update van de map Documenten is mislukt"

			$msgSystemInfoWritten="Systeeminformatie wordt naar de USB-stick geschreven"

			$hdrMustExit="Afsluiten verplicht voor update"

			$msgMustExit="Er is nu een venster geopend met een bestand dat je zelf moet uitvoeren door erop te dubbelklikken. Dit programma wordt beëindigd wanneer je op de knop klikt omdat het zelf bijgewerkt moet worden. Het bestand dat je zelf moet uitvoeren is: "

		Case $LangGerman
			$hdrNoDST = "Keine DST-Datei vorhanden"

			$msgNoDST = "Sie haben noch keine .DST-Datei für Ihre Stickmaschine erstellt oder sie nicht im Ordner " & $s_Path_Downloads & " abgelegt. Klicken Sie auf Exportieren als Tajima/DST."

			$hdrNoXML = "Keine XML-Datei vorhanden"

			$msgNoXML = "Sie haben Ihr Design noch nicht gespeichert oder es nicht im Ordner " & $s_Path_Downloads & " abgelegt. Stellen Sie sicher, dass Ihre Datei Ihren eigenen Namen hat."

			$msgForbiddenNameFlag = 1

			$msgForbiddenName = "Sie haben einen unzulässigen Namen als Dateinamen verwendet. Sie müssen beim Speichern des Projekts einen eigenen Namen angeben. Speichern Sie erneut und exportieren Sie dann die .DST-Datei."
			$msgXMLDSTnamesNotMatchingFlag = 2

			$msgXMLDSTnamesNotMatching = "Die aktuellste XML-Datei und die aktuellste DST-Datei stimmen nicht überein."

			$msgTooMuchTimeDiffFlag = 4

			$msgTooMuchTimeDiff = "Die Zeitspanne zwischen dem Speichern Ihres Designs als .XML-Datei und dem Exportieren als .DST-Datei ist länger als " & $MaxTimeBetweenSavesMin & " Minuten. Speichern und exportieren Sie erneut."

			$msgTooManyColorsFlag = 8

			$msgTooManyColors = "Sie haben zu viele Farben in Ihrem Design verwendet. Die maximale Anzahl beträgt " & $MaxColors & "."

			$msgTooLargeFlag = 16

			$msgTooLarge = "Ihr Design passt nicht in den Stickrahmen. Passen Sie Ihr Design so an, dass es maximal " & $XMax & " mm breit und " & $YMax & " mm hoch ist."

			$msgTooManyStitchesFlag = 32

			$msgTooManyStitches = "Ihr Design enthält zu viele Stiche. Beschränken Sie es auf maximal " & $MaxStitches & " Stiche."

			$msgCloudSavingFlag = 64

			$msgCloudSaving = "Die .XML-Datei sollte in der Cloud gespeichert werden. Haben Sie das getan?"

			$msgXTooLargeFlag = 128

			$msgYTooLargeFlag = 256

			$msgForbiddenLabelFlag = 512

			$msgForbiddenLabel = "Der Name im Beschriftungsfeld der .DST-Datei ist unzulässig. Speichern Sie das Design unter Ihrem eigenen Namen und exportieren Sie es anschließend erneut als .DST."

			$hdrRetry = "Erneut versuchen."

			$msgCopyRetry = "Entfernen Sie den USB-Stick. Beheben Sie gegebenenfalls einen Fehler, speichern Sie das Design erneut und exportieren Sie es ein weiteres Mal. Stecken Sie den USB-Stick anschließend wieder ein."

			$msgUpdRetry = "Entfernen Sie den USB-Stick. Beheben Sie gegebenenfalls einen Fehler und stecken Sie den USB-Stick anschließend wieder ein."

			$msgNoUSBStick = "Der USB-Stick wurde entfernt."
			$msgCopyError = "Fehler beim Schreiben auf den USB-Stick."

			$msgSuccess = "Ihr Design wurde auf den USB-Stick geschrieben." & @CRLF & "Entfernen Sie den USB-Stick vom Laptop." & @CRLF & "Nehmen Sie ein Stück Filz und gehen Sie zur Stickmaschine."

			$lblChooseLanguage = "Sprache"

			$btnEndScript = "Skript beenden"

			$btnContinue = "Fortfahren"

			$hdrStopScript = "Stoppen oder fortfahren"

			$msgSure2StopTheScript = "Möchten Sie das Skript wirklich beenden?"

			$hdrAbort = "Abbrechen"

			$mbtnOK = "OK"

			$mbtnCancel = "Abbrechen"

			$mbtnClose = "Schließen"

			$mbtnEndScript="Abbrechen"

			$hdrReallyStop = "Wirklich stoppen"

			$hdrContinueEdit = "Altes Design bearbeiten oder sichern"

			$mbtnBackup = "Altes Design sichern"

			$mbtnEdit = "Altes Design bearbeiten"

			$msgContinueEdit = "Auf dem USB-Stick befinden sich alte Designs." & @CRLF & @CRLF & "Durch Drücken von " & $mbtnEdit & " wird der USB-Stick geöffnet. Ziehen Sie anschließend die zu bearbeitende Datei in ein geöffnetes TurtleStitch-Fenster." & @CRLF & @CRLF

			$msgContinueEdit = $msgContinueEdit & $mbtnBackup & " verschiebt die .XML-, .DST- und " & $ExtraDataFileName & "-Dateien in einen Ordner mit Zeitstempel, um Namenskonflikte mit dem neuen Design zu vermeiden, das kopiert werden muss."

			; Texte für den Detailbereich

			$hdrDetails="Fehlerdetails und Kontext"

			$mgrpDST = "DST-Dateiinformationen"

			$mlblLA = "LA (Beschriftung)"

			$mlblCO = "CO (Farbe)"

			$mlblST = "ST"

			$mlblXMLfile = "XML-Datei"

			$mlblDSTfile = "DST-Datei"

			$mlblLanguage = "Sprache"

			$mlblVersion = "Version"

			$mlblForbidden = "Verbotene Namen"

			$mbtnCancel = "Abbrechen"

			$mbtnAbort = "Abbrechen"

			$mlblOverridePW = "Passwort"

			$mchkIgnoreErrors = "Fehler ignorieren"

			$mlblMinX = "-X"

			$mlblMinY = "-Y"

			$mlblPlusX = "+X"

			$mlblPlusY = "+Y"

			$mlblSizeX = "Abmessung X (mm)"

			$mlblSizeY = "Abmessung Y (mm)"

			$mgrpMax = "Maximalwerte"

			$mlblTimeDiff = "Zeitdifferenz (s)"

			$mlblMaxTime = "Maximal"

			$mchkTryLandscape = "Querformat testen"

			$mlblInitFile="Konfigurationsdatei"

			$mNone="Keine" ; wird verwendet, wenn keine Initialisierungsdatei vorhanden ist

			$mlblPassword="Passwort"

			$hdrDone="Fertig"

			$hdrStarting="Wird gestartet"
			$msgDesktopCopyStart="Das Kopieren auf den Desktop wird gestartet"
			$msgDesktopUpdateSuccess="Die Aktualisierung des Desktops war erfolgreich"
			$msgDesktopUpdateFailed="Die Aktualisierung des Desktops ist fehlgeschlagen"
			$hdrSucces="Erfolg"
			$hdrFailure="Fehler"
			$msgDocumentsCopyStart="Das Kopieren in den Ordner Dokumente wird gestartet"
			$msgDocumentsUpdateSuccess="Die Aktualisierung des Ordners Dokumente war erfolgreich"
			$msgDocumentsUpdateFailed="Die Aktualisierung des Ordners Dokumente ist fehlgeschlagen"
			$msgSystemInfoWritten="Systeminformationen werden auf den USB-Stick geschrieben"

			$hdrMustExit="Für die Aktualisierung muss das Programm beendet werden"
			$msgMustExit="Es hat sich ein Fenster geöffnet, in dem Sie eine Datei finden, die Sie per Doppelklick ausführen müssen. Dieses Programm wird beendet, sobald Sie auf die Schaltfläche klicken, da es aktualisiert werden muss. Die auszuführende Datei ist: "
		Case $LangDanish
				$hdrNoDST = "Ingen DST-fil til stede"

				$msgNoDST = "Du har endnu ikke oprettet en .DST-fil til broderimaskinen. Eller du har ikke placeret den i mappen Downloads "& $s_Path_Downloads & ". Klik på Eksporter som Tajima/DST"

				$hdrNoXML = "Ingen XML-fil til stede"

				$msgNoXML = "Du har ikke gemt dit design endnu. Eller du har ikke placeret det i mappen Downloads "& $s_Path_Downloads & ". Sørg for, at din fil har dit eget navn."

				$msgForbiddenNameFlag = 1

				$msgForbiddenName = "Du har brugt et forbudt navn som filnavn. Du skal angive dit eget navn, når du gemmer projektet. Gem igen, og eksporter derefter .DST-filen."

				$msgXMLDSTnamesNotMatchingFlag = 2

				$msgXMLDSTnamesNotMatching = "Den seneste XML-fil og den seneste DST-fil stemmer ikke overens."

				$msgTooMuchTimeDiffFlag = 4

				$msgTooMuchTimeDiff = "Tiden mellem at gemme dit design som en .XML-fil og eksportere det som en .DST-fil er længere end "& $MaxTimeBetweenSavesMin &" minutter. Gem igen og eksporter igen."

				$msgTooManyColorsFlag = 8

				$msgTooManyColors = "Du har brugt for mange farver i dit design. Maksimum er "& $MaxColors & "."

				$msgTooLargeFlag = 16

				$msgTooLarge = "Dit design passer ikke i broderirammen. Rediger dit design, så det højst er "& $XMax & " mm bredt og "& $YMax & " mm højt."

				$msgTooManyStitchesFlag = 32

				$msgTooManyStitches = "Dit design indeholder for mange sting. Begræns det til højst "& $MaxStitches & " sting."

				$msgCloudSavingFlag = 64

				$msgCloudSaving = ".XML-filen skal gemmes i skyen. Har du gjort det?"

				$msgXTooLargeFlag = 128

				$msgYTooLargeFlag = 256

				$msgForbiddenLabelFlag = 512

				$msgForbiddenLabel = "Navnet i etiketfeltet i .DST-filen er forbudt. Du kan løse dette ved at gemme designet under dit eget navn og derefter eksportere det til .DST igen."

				$hdrRetry = "Prøv igen"

				$msgCopyRetry = "Fjern USB-nøglen. Hvis der opstod en fejl, skal du rette den, gemme designet igen og eksportere det endnu en gang, og derefter indsætte USB-nøglen igen."

				$msgUpdRetry = "Fjern USB-nøglen. Hvis der opstod en fejl, skal du rette den og derefter indsætte USB-nøglen igen."

				$msgNoUSBStick = "USB-nøglen er blevet fjernet."
				$msgCopyError = "Skrivning til USB-nøglen mislykkedes."

				$msgSuccess = "Dit design er blevet skrevet til USB-nøglen." & @CRLF & "Fjern USB-nøglen fra den bærbare computer." & @CRLF & "Tag et stykke filt og gå hen til broderimaskinen."

				$lblChooseLanguage = "Sprog"

				$btnEndScript = "Afslut script"

				$btnContinue = "Fortsæt"

				$hdrStopScript = "Stop eller fortsæt"

				$msgSure2StopTheScript = "Er du sikker på, at du vil stoppe scriptet?"

				$hdrAbort = "Afbryd"

				$mbtnOK = "OK"

				$mbtnCancel = "Annuller"

				$mbtnClose = "Luk"

				$mbtnEndScript="Afbryd"

				$hdrReallyStop = "Stop virkelig"

				$hdrContinueEdit = "Rediger gammelt design eller sikkerhedskopiér"

				$mbtnBackup = "Sikkerhedskopier gammelt design"

				$mbtnEdit = "Rediger gammelt design"

				$msgContinueEdit = "Der er gamle designs på USB-nøglen." & @CRLF & @CRLF & "Ved at trykke på " & $mbtnEdit & ", åbnes USB-nøglen. Træk derefter den fil, der skal redigeres, til et åbent TurtleStitch-vindue." & @CRLF & @CRLF

				$msgContinueEdit = $msgContinueEdit & $mbtnBackup & " vil flytte .XML-, .DST- og " & $ExtraDataFileName & "-filerne til en tidsstemplet mappe for at forhindre navnekonflikter med det nye design, der skal kopieres."

				; Tekster til detaljepanelet

				$hdrDetails="Fejloplysninger og kontekst"

				$mgrpDST = "DST-filoplysninger"

				$mlblLA = "LA (Etiket)"

				$mlblCO = "CO (Farve)"

				$mlblST = "ST"

				$mlblXMLfile = "XML-fil"

				$mlblDSTfile = "DST-fil"

				$mlblLanguage = "Sprog"

				$mlblVersion = "Version"

				$mlblForbidden = "Forbudte navne"

				$mbtnCancel = "Annuller"

				$mbtnAbort = "Afbryd"

				$mlblOverridePW = "Adgangskode"

				$mchkIgnoreErrors = "Ignorer fejl"

				$mlblMinX = "-X"

				$mlblMinY = "-Y"

				$mlblPlusX = "+X"

				$mlblPlusY = "+Y"

				$mlblSizeX = "Dimension X (mm)"

				$mlblSizeY = "Dimension Y (mm)"

				$mgrpMax = "Maksimumværdier"

				$mlblTimeDiff = "Tidsforskel (s)"

				$mlblMaxTime = "Maksimum"

				$mchkTryLandscape = "Prøv landskab"

				$mlblInitFile="Konfigurationsfil"

				$mNone="Ingen" ; bruges hvis der ikke er en init-fil

				$mlblPassword="Adgangskode"

				$hdrDone="Udført"

				$hdrStarting="Starter"
				$msgDesktopCopyStart="Kopiering til skrivebord starter"
				$msgDesktopUpdateSuccess="Opdatering af skrivebord lykkedes"
				$msgDesktopUpdateFailed="Opdatering af skrivebord mislykkedes"
				$hdrSucces="Lykkedes"
				$hdrFailure="Fejl"
				$msgDocumentsCopyStart="Kopiering til Dokumenter-mappen starter"
				$msgDocumentsUpdateSuccess="Opdatering af Dokumenter-mappen lykkedes"
				$msgDocumentsUpdateFailed="Opdatering af Dokumenter-mappen mislykkedes"
				$msgSystemInfoWritten="Systemoplysninger skrives til USB-nøglen"

				$hdrMustExit="Skal afsluttes for opdatering"
				$msgMustExit="Et vindue er nu åbnet, hvor du finder en fil, som du selv skal køre ved at dobbeltklikke på. Dette program afsluttes, når du klikker på knappen, fordi det selv skal opdateres. Filen, du selv skal køre er: "

		case $LangTurkish
				$hdrNoDST = "DST dosyası mevcut değil"

				$msgNoDST = "Nakış makinesi için henüz bir .DST dosyası oluşturmadınız. Veya dosyayı İndirilenler klasörüne yerleştirmediniz. " & $s_Path_Downloads & ". Tajima/DST olarak Dışa Aktar'ı tıklayın."

				$hdrNoXML = "XML dosyası mevcut değil"

				$msgNoXML = "Tasarımınızı henüz kaydetmediniz. Veya dosyayı İndirilenler klasörüne yerleştirmediniz. " & $s_Path_Downloads & ". Dosyanızın kendi adınızla adlandırıldığından emin olun."

				$msgForbiddenNameFlag = 1

				$msgForbiddenName = "Dosya adı olarak yasaklanmış bir ad kullandınız. Projeyi kaydederken kendi adınızı belirtmelisiniz. Tekrar kaydedin ve ardından .DST dosyasını dışa aktarın."
				$msgXMLDSTnamesNotMatchingFlag = 2

				$msgXMLDSTnamesNotMatching = "En son XML dosyası ve en son DST dosyası eşleşmiyor."

				$msgTooMuchTimeDiffFlag = 4

				$msgTooMuchTimeDiff = "Tasarımınızı .XML dosyası olarak kaydetme ve .DST dosyası olarak dışa aktarma arasındaki süre " & $MaxTimeBetweenSavesMin & " dakikadan uzun. Tekrar kaydedin ve tekrar dışa aktarın."

				$msgTooManyColorsFlag = 8

				$msgTooManyColors = "Tasarımınızda çok fazla renk kullandınız. Maksimum renk sayısı " & $MaxColors & "."

				$msgTooLargeFlag = 16

				$msgTooLarge = "Tasarımınız nakış kasnağına sığmıyor. Tasarımınızı en fazla " & $XMax & " mm genişliğinde ve " & $YMax & " mm yüksekliğinde olacak şekilde değiştirin."

				$msgTooManyStitchesFlag = 32

				$msgTooManyStitches = "Tasarımınız çok fazla dikiş içeriyor. En fazla " & $MaxStitches & " dikişle sınırlayın."

				$msgCloudSavingFlag = 64

				$msgCloudSaving = ".XML dosyası buluta kaydedilmeli. Bunu yaptınız mı?"

				$msgXTooLargeFlag = 128

				$msgYTooLargeFlag = 256

				$msgForbiddenLabelFlag = 512

				$msgForbiddenLabel = ".DST dosyasındaki etiket alanındaki ad yasak. Bunu, tasarımı kendi adınızla kaydedip ardından tekrar .DST olarak dışa aktararak çözebilirsiniz."

				$hdrRetry = "Tekrar deneyin"

				$msgCopyRetry = "USB belleği çıkarın. Bir hata oluştuysa, düzeltin, tasarımı tekrar kaydedin ve bir kez daha dışa aktarın, ardından USB belleği tekrar takın."

				$msgUpdRetry = "USB belleği çıkarın. Bir hata oluştuysa, düzeltin ve ardından USB belleği tekrar takın."

				$msgNoUSBStick = "USB bellek çıkarıldı."
				$msgCopyError = "USB belleğe yazma başarısız oldu."

				$msgSuccess = "Tasarımınız USB belleğe yazıldı." & @CRLF & "USB belleği dizüstü bilgisayardan çıkarın." & @CRLF & "Bir parça keçe alın ve nakış makinesine gidin."

				$lblChooseLanguage = "Dil"

				$btnEndScript = "Komut dosyasını sonlandır"

				$btnContinue = "Devam et"

				$hdrStopScript = "Durdur veya devam et"

				$msgSure2StopTheScript = "Komut dosyasını durdurmak istediğinizden emin misiniz?"

				$hdrAbort = "İptal"

				$mbtnOK = "Tamam"

				$mbtnCancel = "İptal"

				$mbtnClose = "Kapat"

				$mbtnEndScript="İptal"

				$hdrReallyStop = "Gerçekten durdur"

				$hdrContinueEdit = "Eski tasarımı düzenle veya yedekle"

				$mbtnBackup = "Eski tasarımı yedekle"

				$mbtnEdit = "Eski tasarımı düzenle"

				$msgContinueEdit = "USB bellekte eski tasarımlar var." & @CRLF & @CRLF & "" & $mbtnEdit & " tuşuna basarak USB bellek açılacaktır. Ardından düzenlenecek dosyayı açık bir TurtleStitch penceresine sürükleyin." & @CRLF & @CRLF

				$msgContinueEdit = $msgContinueEdit & $mbtnBackup & " .XML, .DST ve " & $ExtraDataFileName & " dosyalarını, kopyalanması gereken yeni tasarımla isim çakışmalarını önlemek için zaman damgalı bir klasöre taşıyacaktır."

				; Detay bölmesi için metinler

				$hdrDetails="Hata detayları ve bağlamı"

				$mgrpDST = "DST dosya bilgileri"

				$mlblLA = "LA (Etiket)"

				$mlblCO = "CO (Renk)"

				$mlblST = "ST"

				$mlblXMLfile = "XML dosyası"

				$mlblDSTfile = "DST dosyası"

				$mlblLanguage = "Dil"

				$mlblVersion = "Sürüm"

				$mlblForbidden = "Yasaklanmış adlar"

				$mbtnCancel = "İptal"

				$mbtnAbort = "İptal"

				$mlblOverridePW = "Şifre"

				$mchkIgnoreErrors = "Hataları yok say"

				$mlblMinX = "-X"

				$mlblMinY = "-Y"

				$mlblPlusX = "+X"

				$mlblPlusY = "+Y"

				$mlblSizeX = "Boyut X (mm)"

				$mlblSizeY = "Boyut Y (mm)"

				$mgrpMax = "Maksimum değerler"

				$mlblTimeDiff = "Zaman farkı (s)"

				$mlblMaxTime = "Maksimum"

				$mchkTryLandscape = "Yatay modu dene"

				$mlblInitFile="Yapılandırma dosyası"

				$mNone="Yok" ; başlatma dosyası yoksa kullanılır

				$mlblPassword="Şifre"

				$hdrDone="Bitti"

				$hdrStarting="Başlatılıyor"

				$msgDesktopCopyStart="Masaüstüne kopyalama başlıyor"

				$msgDesktopUpdateSuccess="Masaüstü güncellemesi başarılı"

				$msgDesktopUpdateFailed="Masaüstü güncellemesi başarısız"

				$hdrSucces="Başarılı"

				$hdrFailure="Başarısız"

				$msgDocumentsCopyStart="Belgeler klasörüne kopyalama başlıyor"

				$msgDocumentsUpdateSuccess="Belgeler klasörünün güncellemesi başarılı"

				$msgDocumentsUpdateFailed="Belgeler klasörünün güncellemesi başarısız"

				$msgSystemInfoWritten="Sistem bilgileri USB belleğe yazılıyor"

				$hdrMustExit="Güncelleme için Çıkılmalı"

				$msgMustExit="Şimdi bir pencere açıldı, burada çift tıklayarak kendiniz çalıştırmanız gereken bir dosya bulacaksınız. Tıkladığınızda bu program sonlandırılacaktır. Düğmeyi değiştirmemiz gerekiyor çünkü kendisinin de güncellenmesi şart. Kendiniz çalıştırmanız gereken dosya şu: "

	EndSwitch

	if $IniFilePath="" Then
		$vtxtInitFile=$mNone
	else
		$vtxtInitFile=$IniFilePath
	EndIf



EndFunc   ;==>SetMessagesInLanguage

Func SetDynamicStrings($Flags)
	Local $ErrorString
	; After the correct language strings have been set, we should also set the strings that dynamically use the language strings.
	; This is especiallly the case for the error message, which will need to hold a number of messages to show, as steered by the $ErrorFlags variable
	If BitAND($Flags, $msgForbiddenNameFlag) <> 0 Then $ErrorString = $msgForbiddenName & @CRLF
	If BitAND($Flags, $msgForbiddenLabelFlag) <> 0 Then $ErrorString = $ErrorString & $msgForbiddenLabel & @CRLF
	If BitAND($Flags, $msgXMLDSTnamesNotMatchingFlag) <> 0 Then $ErrorString = $ErrorString & $msgXMLDSTnamesNotMatching & @CRLF
	If BitAND($Flags, $msgTooMuchTimeDiffFlag) <> 0 Then $ErrorString = $ErrorString & $msgTooMuchTimeDiff & @CRLF
	If BitAND($Flags, $msgTooManyColorsFlag) <> 0 Then $ErrorString = $ErrorString & $msgTooManyColors & @CRLF
	If BitAND($Flags, $msgTooLargeFlag) <> 0 Then $ErrorString = $ErrorString & $msgTooLarge & @CRLF
	If BitAND($Flags, $msgTooManyStitchesFlag) <> 0 Then $ErrorString = $ErrorString & $msgTooManyStitches & @CRLF


	;if ... = $msgCloudSavingFlag then $XMLPath2Show=$msgCloudSaving
; continue displaying the panel as long as the language was changed
	return $ErrorString
EndFunc









;ConsoleWrite($s_Path_Downloads & @CRLF)
;ConsoleWrite($s_Path_Documents & @CRLF)
;ConsoleWrite($s_Path_Desktop & @CRLF)



$DBT_DEVICEARRIVAL = "0x00008000"
;$WM_DEVICECHANGE = 0x0219

$hGUI1 = GUICreate("")
GUIRegisterMsg($WM_DEVICECHANGE, "USBstickDetection")


; Waint forever. The processing starts when a USB stick is inserted
While (1)
	Sleep(1000000)
WEnd

Exit

Func USBstickDetection($hWndGUI, $MsgID, $WParam, $LParam)
	;msgbox(4096,"bla","blabla",2)

	; if shift (left or right) is pressed while inserting the USB stick then a menu will pop up with the option to stop the script
	; Also the language can be changed as on every panel
	If IsShiftPressed() Then
		; Display the two buttons. The second (2) is the exit button
		DisplayPanel(1, $hGUI1, $hdrStopScript, "", $btnContinue, $mbtnEndScript, "", 2)
	EndIf

	; msgbox(4096,"bla",$MsgID,2)

	Local $aArray = DriveGetDrive($DT_REMOVABLE)
	Local $i
	If @error Then
		; An error occurred when retrieving the drives.
		;MsgBox($MB_SYSTEMMODAL, "", "It appears an error occurred.")
	Else

		;Go through all driveletters with removable drives and see whether it is the one for TurtleStitch
		For $i = 1 To $aArray[0]

			; Get the driveletters of the removable drives
			Local $DriveLetter = $aArray[$i]
			;ConsoleWrite("i=" & $i & " " & $aArray[$i] )
			; Show all the drives found and convert the drive letter to uppercase.
			;MsgBox($MB_SYSTEMMODAL, "drive  ",$DriveLetter)
			; MsgBox($MB_SYSTEMMODAL, "", "Drive " & $i & "/" & $aArray[0] & ":" & @CRLF & StringUpper($aArray[$i]) &  "\" & Drivegetlabel($aArray[$i]) )

			; Get the volumelabel given the driveletter
			$USBvolume = DriveGetLabel($DriveLetter)
			Local $result = 2
			;MsgBox(0,"label", $DriveLetter)
			If StringInStr($USBvolume, $USBstickPrefixTurtleSt, 1) = 1 Then
				;MsgBox (0,"bla", $USBvolume)
				; The USB stick to copy the designs onto is present
				$result = CopyDesignToUSB($s_Path_Downloads, $DriveLetter)
				If $result = False Then
					;MsgBox($MB_ICONINFORMATION,$hdrRetry,$msgCopyRetry)
					;If there was an error, display what to do
					DisplayPanel(1, "", $hdrRetry, $msgCopyRetry, $mbtnOK, "", "", 0)
				EndIf
				_WinAPI_EjectMedia($DriveLetter)
				;Drivesetlabel($aArray[$i],"TurtleST" & $USBstickNumber)
				;$USBvolume=Drivegetlabel($aArray[$i])
				;$USBstickNumber=$USBstickNumber+1
			ElseIf StringInStr($USBvolume, $USBstickPrefixUpdate, 1) = 1 Then

				; The updatestick was found
				$result = UpdateFromUSB($s_Path_Desktop, $s_Path_Documents, $DriveLetter)
				If $result = False Then
					;MsgBox($MB_ICONINFORMATION,"Opnieuw",$msgCopyRetry)

					;If there was an error, display what to do
					DisplayPanel(1, "", $hdrRetry, $msgUpdRetry, $mbtnOK, "", "", 0)

				EndIf

			EndIf
			;msgbox(0,"USB drive",$USBvolume,2)
		Next

		; DBT_DEVICEREMOVECOMPLETE
	EndIf

EndFunc   ;==>USBstickDetection


Func CopyDesignToUSB($Folder, $USBDriveLetter)

	; Make sure that variables are cleared that may hold some information of the previous USB stick that was inserted

	$XMLPath2ShowFlag = 0
	$XMLPath2Show=""
	$vtxtLabel = ""
	$ActColors = ""
	$vtxtPlusY = ""
	$vtxtMinY = ""
	$vtxtMinX = ""
	$vtxtPlusX = ""
	$vtxtSizeY = ""
	$vtxtSizeX = ""
	$ErrorFlags=0



	; if an .XML file already exists on the USB drive then ask the user what is wanted: continue with that project or use the stick to copy the new design onto?
	If FileExists($USBDriveLetter & "\*.XML") Then
		$result = DisplayPanel(1, $hGUI1, $hdrContinueEdit, $msgContinueEdit, $mbtnBackup, $mbtnEdit, $mbtnCancel)
	Else
		$result = 4
	EndIf

	; When cancelled or when window closed, do not continue with this stick
	If $result = 3 Or $result = 0 Then Return True

	If $result = 2 Then
		; start explorer with the USB drive open, so that the old design can be copied by the user into an open TurtleStitch window
		ShellExecute($USBDriveLetter & "\")
		Return True
	EndIf


	Local $Dir2Test = $USBDriveLetter & "\"
	ConsoleWrite("aa" & $USBDriveLetter & "bb")
	If FileExists($Dir2Test) = 0 Then

		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgNoUSBStick, $mbtnOK, "", "")
		;MsgBox($MB_ICONERROR, "Geen USB Stick", $msgNoUSBStick)
		ConsoleWrite("fileexists fail")

		Return False
	EndIf

	;ClearUSBStick($USBDriveLetter)



	If $result = 1 Or FileExists($USBDriveLetter & "\*.DST") or FileExists($USBDriveLetter & "\" & $ExtraDataFileName) Then
		local $Now= _NowCalc()
		ConsoleWrite("Now=" & $Now & @CRLF)
		$Now=stringreplace($Now,"/","-")
		$Now=StringReplace($Now," ","--")
		$Now=StringReplace($Now, ":", "-")
		ConsoleWrite("Now=" & $Now & @CRLF)
		Local $BackupDir = $USBDriveLetter & "\TSOLD" & "-"& $Now
		$result=DirCreate($BackupDir)
		if $result=1 then FileMove ($USBDriveLetter & "\*.XML",$BackupDir)
		if $result = 1 then FileMove ($USBDriveLetter & "\*.DST",$BackupDir)
		if $result = 1 then	FileMove ($USBDriveLetter & "\" & $ExtraDataFileName,$BackupDir)
		If $result <> 1 then
			ConsoleWrite("some copy failed")
			$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgCopyError, $mbtnOK, "", "")
			;MsgBox($MB_ICONERROR, "Kopie lukt niet", $msgCopyError)
			Return False
		EndIf
	EndIf






	; now test whether there is a .DST file present in the download location
	Global $NewestDSTFilePath = FindNewestFile($Folder, "*.DST")

	ConsoleWrite(FileExists($USBDriveLetter & "\*.XML"))

	ConsoleWrite("$NewestDSTFilePath=" & $NewestDSTFilePath & @CRLF)

	If $NewestDSTFilePath = "" Then
		;MsgBox ($MB_ICONERROR,"Geen DST", $msgNoDST)
		DisplayPanel(1, $hGUI1, $hdrNoDST, $msgNoDST, $mbtnClose, "", "")
		Return False
	EndIf

	; Find the newest .DST file, since that is the one we want to copy to the USB drive
	Local $dummy
	Local $NewestDSTFileName
	Local $aArray = _PathSplit($NewestDSTFilePath, $dummy, $dummy, $NewestDSTFileName, $dummy)
	$NewestDSTFileTime = FileGetTime($NewestDSTFilePath, $FT_MODIFIED, $FT_STRING)
	$vtxtDSTtime = SplitTimeDateString($NewestDSTFileTime)  ; put it into the variable for display in a comprehensible form
	Local $DSTBaseFileName = GetBaseFile($NewestDSTFileName)

	If IsNameForbidden($DSTBaseFileName) Then
		$ErrorFlags = $ErrorFlags + $msgForbiddenNameFlag
		;display the error <-----
		;DisplayPanel(1, $hGUI1, $hdrNoDST, $msgForbiddenName, $mbtnClose, "", "")
		;Return False
	EndIf

	consolewrite ("$StoreLocal=" & $StoreLocal & @CRLF)
	; Now also find the newest .XML file to see whether the design was saved, but only do so when storing designs locally
	If $StoreLocal = "Y" Then

		;Find the newest .XML file
		$NewestXMLFilePath = FindNewestFile($Folder, "*.XML")
		ConsoleWrite("535-$NewestXMLFilePath=" & $NewestXMLFilePath & @CRLF)

		If $NewestXMLFilePath = "" Then
			; if none present then probably user did not save the design
			DisplayPanel(1, $hGUI1, $hdrNoXML, $msgNoXML, $mbtnClose, "", "")
			Return False
		EndIf


		Local $NewestXMLFileName
		Local $aArray = _PathSplit($NewestXMLFilePath, $dummy, $dummy, $NewestXMLFileName, $dummy)
		$NewestXMLFileTime = FileGetTime($NewestXMLFilePath, $FT_MODIFIED, $FT_STRING)

		Local $XMLBaseFileName = GetBaseFile($NewestXMLFileName)

		ConsoleWrite("$550-NewestXMLFilePath=" & " " & $NewestXMLFilePath & @CRLF)
		ConsoleWrite("$551-NewestXMLFileTime=" & " " & $NewestXMLFileTime & @CRLF)

		If $XMLBaseFileName <> $DSTBaseFileName Then
			$ErrorFlags = $ErrorFlags+$msgXMLDSTnamesNotMatchingFlag
		Else

			; ConsoleWrite("NewestXML",$NewestXMLFilePath & "   "  & $NewestXMLFileName & "  " & $NewestXMLFileTime & "   " & $XMLBaseFileTime )

			$XML2DSTdiff = Abs($NewestDSTFileTime - $NewestXMLFileTime)
			ConsoleWrite("$NewestDSTFileTime" & $NewestDSTFileTime & @CRLF)
			ConsoleWrite("$NewestXMLFileTime" & $NewestXMLFileTime & @CRLF)
			ConsoleWrite("$XML2DSTdiff=" & $XML2DSTdiff & @CRLF)

			If $XML2DSTdiff > $MaxTimeBetweenSavesSec Then
				$ErrorFlags = $ErrorFlags + $msgTooMuchTimeDiffFlag
			EndIf
		EndIf

		;msgbox(64,"Timediff",$XML2DSTdiff)




	Else
		;Remember that the translated "Saved in the Cloud" message has to be displayed.
		$XMLPath2ShowFlag = $msgCloudSavingFlag

	EndIf






	ParseDSTFile($NewestDSTFilePath, $Name, $ActColors, $MinX, $PlusX, $MinY, $PlusY, $SizeX, $SizeY, $StitchCount)

	ConsoleWrite("$ActColors="& $ActColors & @CRLF)

	If ($SizeX > $XMax Or $SizeY > $YMax) Then
		$ErrorFlags = $ErrorFlags + $msgTooLargeFlag
	EndIf

	If $SizeX > $XMax then $ErrorFlags = $ErrorFlags + $msgXTooLargeFlag
	If $SizeY > $YMax then $ErrorFlags = $ErrorFlags + $msgYTooLargeFlag



	If ($StitchCount > $MaxStitches) Then
		$ErrorFlags = $ErrorFlags + $msgTooManyStitchesFlag
	EndIf


	If ($ActColors > $MaxColors) Then
		$ErrorFlags = $ErrorFlags + $msgTooManyColorsFlag
	EndIf

	ConsoleWrite("1 Errorflags=" & $ErrorFlags & @CRLF)

	ConsoleWrite("$Name="& $Name & "X" & @CRLF)

	ConsoleWrite("isforbidden=" & IsNameForbidden($Name) & @crlf )
	If IsNameForbidden($Name) = True Then
		ConsoleWrite("name forbidden $Name="& $Name & @CRLF)

		consolewrite("$msgForbiddenLabelFlag=" & $msgForbiddenLabelFlag & @crlf)

		$ErrorFlags = $ErrorFlags + $msgForbiddenLabelFlag
	EndIf
	;if $Name=$ForbiddenName then $ErrorFlags = $ErrorFlags + $msgForbiddenLabelFlag

	ConsoleWrite("2 Errorflags=" & $ErrorFlags & @CRLF)
	If $ErrorFlags <> 0 Then
		; display the error message(s) <------------
		$result=DisplayPanel(2, $hGUI1, $hdrDetails, $ErrorFlags, $mbtnOK, $mbtnCancel, "", "")
		if $result<>1 then Return False
	EndIf



	;Now the files look OK. We can copy them to the USB drive
	;$UserName=""
	;while $UserName=""
	;	local $UserName=InputBox("Naam","Tik je naam in")
	;	if @error=1 then Return False
	;wend

	Local $Dir2Test = $USBDriveLetter & "\"
	ConsoleWrite("aa" & $USBDriveLetter & "bb")
	If FileExists($Dir2Test) = 0 Then

		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgNoUSBStick, $mbtnOK, "", "")
		;MsgBox($MB_ICONERROR, "Geen USB Stick", $msgNoUSBStick)
		ConsoleWrite("fileexists fail")

		Return False
	EndIf

	;ClearUSBStick($USBDriveLetter)

	If FileCopy($NewestDSTFilePath, $USBDriveLetter & "\") = 0 Then
		ConsoleWrite("DST fail")
		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgCopyError, $mbtnOK, "", "")
		;MsgBox($MB_ICONERROR, "Kopie lukt niet", $msgCopyError)
		Return False
	EndIf

	If FileCopy($NewestXMLFilePath, $USBDriveLetter & "\") = 0 Then
		ConsoleWrite("XML fail")
		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgCopyError, $mbtnOK, "", "")

		;MsgBox($MB_ICONERROR, "Kopie lukt niet", $msgCopyError)
		Return False
	EndIf

	Local $hExtraFile = FileOpen($USBDriveLetter & "\" & $ExtraDataFileName, $FO_OVERWRITE)
	If $hExtraFile = -1 Then
		ConsoleWrite("FileOpen fail")
		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgCopyError, $mbtnOK, "", "")

		;MsgBox($MB_ICONERROR, "Kopie lukt niet", $msgCopyError)
		Return False
	EndIf

;~ 	if FileWriteLine($hExtraFile,"User=" & $UserName)=0 then
;~ 		MsgBox($MB_ICONERROR,"Kopie lukt niet",$msgCopyError)
;~ 		ConsoleWrite("UserName fail")
;~ 		fileclose($hExtraFile)
;~ 		Return False
;~ 	EndIf
	If FileWriteLine($hExtraFile, "Machine=" & @ComputerName) = 0 Then
		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgCopyError, $mbtnOK, "", "")

		;MsgBox($MB_ICONERROR, "Kopie lukt niet", $msgCopyError)
		ConsoleWrite("Machine fail")
		FileClose($hExtraFile)
		Return False
	EndIf

	Local $USBvolume = DriveGetLabel($USBDriveLetter)
	If FileWriteLine($hExtraFile, "USBstick=" & $USBvolume) = 0 Then
		$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgCopyError, $mbtnOK, "", "")
		;MsgBox($MB_ICONERROR, "Kopie lukt niet", $msgCopyError)
		ConsoleWrite("Machine fail")
		FileClose($hExtraFile)
		Return False
	EndIf


	FileClose($hExtraFile)

	DisplayPanel(1, "", $hdrDone, $msgSuccess, $mbtnOK, "", "", 0)
	;MsgBox($MB_ICONINFORMATION, "Gelukt!", $msgSuccess)

	Return True
EndFunc   ;==>CopyDesignToUSB


Func ClearUSBStick($DriveLetter)
	FileDelete($DriveLetter & "\*.xml")
	FileDelete($DriveLetter & "\*.dst")
	FileDelete($DriveLetter & "\" & $ExtraDataFileName)
EndFunc   ;==>ClearUSBStick

Func GetBaseFile($Filenam)
	Local $result = StringStripWS(StringRegExpReplace($Filenam, "\(.*\)", ""), $STR_STRIPLEADING + $STR_STRIPTRAILING)
	ConsoleWrite("X" & $result & "X")
	Return $result
EndFunc   ;==>GetBaseFile

Func ParseDSTFile($FilePath, ByRef $dLabel, ByRef $dColorCount, ByRef $dMinusX, ByRef $dPlusX, ByRef $dMinusY, ByRef $dPlusY, ByRef $dXsize, ByRef $dYsize, ByRef $dStitchCount)
	; Open the file for reading and store the handle to a variable.
	;ConsoleWrite($FilePath)
	Local $hFileOpen = FileOpen($FilePath, $FO_UTF8)
	If $hFileOpen = -1 Then
		MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
		Return False
	EndIf

	; Read the contents of the file using the handle returned by FileOpen.
	Local $sDSTheader = FileRead($hFileOpen, 100)

	;ConsoleWrite($sDSTheader)
	;ConsoleWrite("eind")

	$dLabel = StringRegExpReplace($sDSTheader, "(?s).*LA:", "")
	$dLabel = StringRegExpReplace($dLabel, "(?m)\r.*", "")
	$dLabel = StringStripWS($dLabel,$STR_STRIPTRAILING )
	ConsoleWrite("Label=" & $dLabel & @CRLF)

	$dColorCount = StringRegExpReplace($sDSTheader, "(?s).*CO:", "")
	$dColorCount = StringStripWS(StringRegExpReplace($dColorCount, "(?m)\r.*", ""), $STR_STRIPALL )
	ConsoleWrite("Colorcount=" & $dColorCount & @CRLF)


	$dPlusX = StringRegExpReplace($sDSTheader, "(?s).*\+X:", "")
	$dPlusX = StringStripWS(StringRegExpReplace($dPlusX, "(?m)\r.*", ""),$STR_STRIPALL )
	ConsoleWrite("PlusX=" & $PlusX & @CRLF)

	$dPlusY = StringRegExpReplace($sDSTheader, "(?s).*\+Y:", "")
	$dPlusY = StringStripWS(StringRegExpReplace($dPlusY, "(?m)\r.*", ""),$STR_STRIPALL )
	ConsoleWrite("PlusY=" & $dPlusY & @CRLF)

	$dMinusX = StringRegExpReplace($sDSTheader, "(?s).*\-X:", "")
	$dMinusX = StringStripWS(StringRegExpReplace($dMinusX, "(?m)\r.*", ""),$STR_STRIPALL )
	ConsoleWrite("MinusX=" & $dMinusX & @CRLF)


	$dMinusY = StringRegExpReplace($sDSTheader, "(?s).*\-Y:", "")
	$dMinusY = StringStripWS(StringRegExpReplace($dMinusY, "(?m)\r.*", ""),$STR_STRIPALL )
	ConsoleWrite("MinusY=" & $dMinusY & @CRLF)

	$dStitchCount = StringRegExpReplace($sDSTheader, "(?s).*\ST:", "")
	$dStitchCount = StringStripWS(StringRegExpReplace($dStitchCount, "(?m)\r.*", ""),$STR_STRIPALL )
	ConsoleWrite("StitchCount=" & $dStitchCount & @CRLF)

	$dXsize = ($dPlusX + $dMinusX) / 10
	$dYsize = ($dPlusY + $dMinusY) / 10

	ConsoleWrite("Xsize=" & $dXsize & @CRLF)
	ConsoleWrite("Ysize=" & $dYsize & @CRLF)


	; Close the handle returned by FileOpen.
	FileClose($hFileOpen)


EndFunc   ;==>ParseDSTFile



;$NewestFileName =  $aArray[$PATH_FILENAME]

;MsgBox (4096,"",$NewestFileName)

Func FindNewestFile($Folder, $SearchFor)
	Local $x
	Local $newest
	Local $FileList = _FileListToArrayRec($Folder, $SearchFor, 1, 0, 0, 2)

	If IsArray($FileList) Then

		consolewrite("Filelist[0]=" & $FileList[0]&@CRLF)
		;MsgBox(4096,"",$FileList[0])
		For $x = 1 To $FileList[0]
			;MsgBox(4096,"",$FileList[$x])
			consolewrite("Filelist["& $x & "]="& $Filelist[$x] & @crlf)

			If FileGetTime($FileList[$x], $FT_MODIFIED, $FT_STRING) > $newest Then
				$newest = FileGetTime($FileList[$x], $FT_MODIFIED, $FT_STRING)
				$newname = $FileList[$x]
				;MsgBox(64,"Newest", $newest)
			EndIf
		Next
	Else
		$newname = ""
	EndIf

	Return $newname
EndFunc   ;==>FindNewestFile

Func UpdateFromUSB($DesktopPath, $DocumentsPath, $USBDriveLetter)

	Local $IP_Address = @IPAddress1

	Local $MAC_Address = GET_MAC($IP_Address)

	If FileExists($USBDriveLetter & "\" & $DesktopUpdateName) Then
		;$result = DisplayPanel(1, $hGUI1, $hdrStarting, $msgDesktopCopyStart, "", "", "", 1000)

		MsgBox($MB_ICONINFORMATION, $hdrStarting, $msgDesktopCopyStart, 1)
		If DirCopy($USBDriveLetter & "\" & $DesktopUpdateName, $DesktopPath, $FC_OVERWRITE) = 1 Then
			;$result = DisplayPanel(1, $hGUI1, $hdrSucces, $msgDesktopUpdateSuccess, "", "", "", 1000)
			MsgBox($MB_ICONINFORMATION, $hdrSucces, $msgDesktopUpdateSuccess, 1)
		Else
			$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgDesktopUpdateFailed, $mbtnOK, "", "")
			;MsgBox($MB_ICONERROR, $hdrFailure, $msgDesktopUpdateFailed)
		EndIf
	EndIf


	If FileExists($USBDriveLetter & "\" & $DocumentsUpdateName) Then

		;$result = DisplayPanel(1, $hGUI1, $hdrStarting, $msgDocumentsCopyStart, "", "", "", 1000)
		MsgBox($MB_ICONINFORMATION, $hdrStarting, $msgDocumentsCopyStart, 1)
		If DirCopy($USBDriveLetter & "\" & $DocumentsUpdateName, $DocumentsPath, $FC_OVERWRITE) = 1 Then
			;$result = DisplayPanel(1, $hGUI1, $hdrSucces, $msgDocumentsUpdateSuccess, "", "", "", 1000)

			MsgBox($MB_ICONINFORMATION, $hdrSucces, $msgDocumentsUpdateSuccess, 1)
		Else
			$result = DisplayPanel(1, $hGUI1, $hdrFailure, $msgDocumentsUpdateFailed, $mbtnOK, "", "")

			;MsgBox($MB_ICONERROR, "Update van Documents lukt niet", $msgCopyError)
		EndIf
	EndIf

	;$result = DisplayPanel(1, $hGUI1, $hdrStarting, $msgSystemInfoWritten, "", "", "", 1000)
	MsgBox($MB_ICONINFORMATION, $hdrStarting, $msgSystemInfoWritten, 2)
	FileWriteLine($USBDriveLetter & "\SystemMac.txt", @ComputerName & "=" & $MAC_Address)

	$ExitForUpdatePath=$USBDriveLetter & "\" & $ExitForUpdateFileName
	If FileExists($ExitForUpdatePath) Then
		$PathToOpenFolder=IniRead($ExitForUpdatePath, $SectionExitForUpdate, $PathToOpenKW, "")
		ConsoleWrite("Pathtoopenfolder=" & $PathToOpenFolder & @CRLF)
		$PathToOpenMessage=IniRead($ExitForUpdatePath, $SectionExitForUpdate, $PathToOpenMessageKW, "")
		ConsoleWrite("$pathtoopenmessage="&$pathtoopenmessage&@crlf)
		$FiletoExecute=IniRead($ExitForUpdatePath, $SectionExitForUpdate, $FileToExecuteKW, "")
		consolewrite("$FiletoExecute=" & $FiletoExecute & @CRLF)
		ShellExecute($DocumentsPath & "\" & $PathToOpenFolder)
		ConsoleWrite($msgMustExit & @CRLF)
		Local $Message2display=$msgMustExit & $FiletoExecute & ". " & @crlf & $PathToOpenMessage
		$result = DisplayPanel(1, $hGUI1, $hdrMustExit, $Message2display , $mbtnOK, "", "")
		_WinAPI_EjectMedia($USBDriveLetter)
		ConsoleWrite("voor exit na eject"& @CRLF)
		exit
	Else
		_WinAPI_EjectMedia($USBDriveLetter)



	EndIf

$SectionExitForUpdate="ExitForUpdateInfo"
$PathToOpenKW="PathToOpen"
$PathToOpenMessageKW="Message"
$FileToExecuteKW="FileToExecute"


	Return True
EndFunc   ;==>UpdateFromUSB


Func GET_MAC($_MACsIP)
	Local $_MAC, $_MACSize
	Local $_MACi, $_MACs, $_MACr, $_MACiIP
	$_MAC = DllStructCreate("byte[6]")
	$_MACSize = DllStructCreate("int")
	DllStructSetData($_MACSize, 1, 6)
	$_MACr = DllCall("Ws2_32.dll", "int", "inet_addr", "str", $_MACsIP)
	$_MACiIP = $_MACr[0]
	$_MACr = DllCall("iphlpapi.dll", "int", "SendARP", "int", $_MACiIP, "int", 0, "ptr", DllStructGetPtr($_MAC), "ptr", DllStructGetPtr($_MACSize))
	$_MACs = ""
	For $_MACi = 0 To 5
		If $_MACi Then $_MACs = $_MACs & ":"
		$_MACs = $_MACs & Hex(DllStructGetData($_MAC, 1, $_MACi + 1), 2)
	Next
	DllClose($_MAC)
	DllClose($_MACSize)
	Return $_MACs
EndFunc   ;==>GET_MAC


; This function checks whether one of the Shift keys is pressed and returns TRUE if so. False otherwise
Func IsShiftPressed()
	Local $hDLL = DllOpen("user32.dll")
	If _IsPressed("10", $hDLL) Then
		; ConsoleWrite("_IsPressed - Shift Key was pressed. @extended = " & @extended & @CRLF)
		Return True
	Else
		Return False
	EndIf
	DllClose($hDLL)
EndFunc   ;==>IsShiftPressed


Func StripComment($Text)
	Return StringStripWS(StringRegExpReplace($Text, ";.*", ""), $STR_STRIPALL)
EndFunc   ;==>StripComment

Func DisplayPanel($Type, $Window2Disable, ByRef $HeaderText, ByRef $MessageOrFlags, ByRef $Button1, ByRef $Button2, ByRef $Button3, $ExitButtonNr = 0, $TimeOut = 0)
	; The intent of this function is to display a message for the user and also to allow select another language for the interface.
	; It can be called with an optional message text to be displayed and up to 3 buttons. One of the buttons can be defined as an exit
	; button. When that one is pressed, the whole script will exit.
	; $Type					= 1: display the $Message in a simple window
	;						= 2: Display the details panel
	; $Window2Disable 		= when called from another GUI, that GUI must be disabled while this new GUI is displayed
	;						  Fill in the handle of the other GUI. Or an empty string if no window is to be disabled
	; $HeaderText			= Text to display at the top of the Window
	; $MessageOrFlags		= Type=1 : Message that will be displayed. Or empty string if nothing is to be displayed
	;						= Type=2 : Combined message flags so that multiple messages can be displayed. This is done this way
	;							rather than concatenating the messages in the calling function because this allows for translations to be done when the panel is displayed
	; $Button1				= Text on the leftmost button. Or empty string if the button must not be displayed.
	; $Button2				= Text on the middle button. Or empty string if the button must not be displayed.
	; $Button3				= Text on the rightmost button. Or empty string if the button must not be displayed.
	; $ExitButtonNr			= Optional. Which of the buttons (1, 2 or 3) will trigger the script to terminate (after a confirmation)
	;						  Or 0 if none of them will have that behaviour.
	;
	; Return values
	; 						1, 2 or 3 when button1, button2 or button 3 are pressed respectively
	; 						When the button is pressed specified by $ExitButton then nothing is returned: the script is just terminated
	;
	; Side effects: the user can choose another language and that new value will be set in the $Language variable
	;
	; Note that when the language changes, the scripts sets the new language strings and loops to display the panel in the newly selected language.
	; Note that it is essential for most of the parameters to be ByRef, beacuse when the language changes, reference must be made to those updated values.

	Local $Message,  $ID_Button1, $ID_Button2, $ID_Button3

	If $Window2Disable <> "" Then GUISetState(@SW_DISABLE, $Window2Disable)

	Local $vchkIgnoreErrors, $txtPassword

	; make sure that at the while loop is executed at least once
	Local $LanguageChanged = True

	$WhichButtonPressed = 0
	Local $BoxHeight = 22
	Local $LabelYOffset = 4

	While $LanguageChanged = True

		; Set the value to False, since that is the outcome in most cases. It will be set to True when a language has indeed been changed.
		$LanguageChanged = False

		if $Type=1 then

			$Message=$MessageOrFlags

			;Determine whether the textbox should be enlarged
			Local $Offset = 0
			If $Message <> "" Then
				$Offset = Floor(StringLen($Message) / 60) * 30
			EndIf
			ConsoleWrite("$Offset=" & $Offset)






			Local $h_MessageGUI = GUICreate($HeaderText, 620, 120 + $Offset ) ;, $WS_OVERLAPPEDWINDOW)  ;$WS_SIZEBOX)
			; remember the GUI handle so that it can be closed if we want to do a timeout
			$GUIhandle2Close=$h_MessageGUI

			GUICtrlCreateLabel($Message, 10, 13, 400, 20 + $Offset)

			$cmbLanguage = GUICtrlCreateCombo("", 500, 10, 100, 100)

			ConsoleWrite("$cmbLanguage=" & $cmbLanguage & @CRLF)
			ConsoleWrite("Language=" & $Language & @CRLF)
			GUICtrlSetData($cmbLanguage, $SupportedLanguages, $LanguageArray[Language2Index($Language)][$LanguageName])
			;GUICtrlSetFont(-1, 10)

			GUICtrlCreateLabel($lblChooseLanguage, 450, 13 + $LabelYOffset, 50, $BoxHeight)

			GUICtrlCreateLabel($Version, 450, 50, 130,60)




			If $Button1 <> "" Then
				$ID_Button1 = GUICtrlCreateButton($Button1, 10, 80 + $Offset, 100, 30)
				GUICtrlSetState(-1, $GUI_DEFBUTTON)
			EndIf

			If $Button2 <> "" Then $ID_Button2 = GUICtrlCreateButton($Button2, 110, 80 + $Offset, 100, 30)
			If $Button3 <> "" Then $ID_Button3 = GUICtrlCreateButton($Button3, 210, 80 + $Offset, 100, 30)
			GUISetState(@SW_SHOWNORMAL, $h_MessageGUI)

		else


			Local $vtxtXML2DSTdiff
			Local $vtxtXMLtime
			Local $vtxtDSTtime=SplitTimeDateString($NewestDSTFileTime)
			if $StoreLocal="Y" then
				$XMLPath2Show=$NewestXMLFilePath
				$vtxtXMLtime = SplitTimeDateString($NewestXMLFileTime)
				$vtxtXML2DSTdiff=$XML2DSTdiff
			Else
				$XMLPath2Show=""
				$vtxtXMLtime = ""
				$vtxtXML2DSTdiff=""
			EndIf


			$Message=SetDynamicStrings($MessageOrFlags)
			$hDetailsGUI = GUICreate($HeaderText, 723,500, 210, 10, $WS_SIZEBOX )
			GUISetBkColor(0xFFFFFF)
			; remember the GUI handle so that it can be closed if we want to do a timeout
			$GUIhandle2Close=$hDetailsGUI


			ConsoleWrite("$ActColors="& $ActColors & @CRLF)
			$grpDST = GUICtrlCreateGroup($mgrpDST, 25, 68, 351, 161)

			$lblLA = GUICtrlCreateLabel($mlblLA, 40, 93 + $LabelYOffset, 74, $BoxHeight)
			$txtLabel = GUICtrlCreateInput($Name, 160, 93 , 101, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgForbiddenLabelFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf


			$lblCO = GUICtrlCreateLabel($mlblCO, 40, 115 + $LabelYOffset, 74, $BoxHeight)
			$txtColor = GUICtrlCreateInput($ActColors, 160, 115, 51, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgTooManyColorsFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf

			$txtMaxST = GUICtrlCreateInput($MaxStitches, 390, 137, 51, $BoxHeight, $ES_READONLY)
			$lblST = GUICtrlCreateLabel($mlblST, 40, 137 + $LabelYOffset, 74, $BoxHeight)
			$txtST = GUICtrlCreateInput($StitchCount, 160, 137, 51, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgTooManyStitchesFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf


			GUICtrlCreateGroup("", -99, -99, 1, 1)

			;$vlstForbidden = GUICtrlCreateList($ForbiddenNames, 555, 145, 141, 136)

			$lblXMLfile = GUICtrlCreateLabel($mlblXMLfile, 30, 9 + $LabelYOffset, 74, $BoxHeight)

			$lblDSTfile = GUICtrlCreateLabel($mlblDSTfile, 30, 30 + $LabelYOffset, 74, $BoxHeight)
			$txtDSTPath = GUICtrlCreateInput($NewestDSTFilePath, 108, 30, 453, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgForbiddenNameFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf

			$txtMPXpath = GUICtrlCreateInput($XMLPath2Show, 108, 9, 453, $BoxHeight, $ES_READONLY)


			$lblLanguage = GUICtrlCreateLabel($lblChooseLanguage, 552 + $LabelYOffset, 288, 72, $BoxHeight)

			$cmbLanguage = GUICtrlCreateCombo("", 560, 305, 136, 20)
			GUICtrlSetData($cmbLanguage, $SupportedLanguages, $LanguageArray[Language2Index($Language)][$LanguageName])


			$lblVersion = GUICtrlCreateLabel($Version, 550, 390 + $LabelYOffset, 145, $BoxHeight, $SS_RIGHT)
			;$lblForbidden = GUICtrlCreateLabel($mlblForbidden, 560, 125 + $LabelYOffset, 126, $BoxHeight)

			$vchkIgnoreErrors = GUICtrlCreateCheckbox($mchkIgnoreErrors, 30, 392 + $LabelYOffset, 116, $BoxHeight)

			$txtError = GUICtrlCreateLabel($Message, 35, 245, 500, 140, $ES_READONLY)
			GUICtrlSetBkColor(-1, $ErrorBackgroundColor)
			GUICtrlSetColor(-1, $ErrorForegroundColor)
			;GUICtrlSetResizing(-1,$GUI_DOCKAUTO)

			$lblMinX = GUICtrlCreateLabel($mlblMinX, 40, 164 + $LabelYOffset, 25, $BoxHeight)
			$lblMinY = GUICtrlCreateLabel($mlblMinY, 40, 189 + $LabelYOffset, 25, $BoxHeight)
			$lblPlusX = GUICtrlCreateLabel($mlblPlusX, 130, 164 + $LabelYOffset, 25, $BoxHeight)
			$lblPlusY = GUICtrlCreateLabel($mlblPlusY, 130, 189 + $LabelYOffset, 25, $BoxHeight)
			$txtPlusY = GUICtrlCreateInput($PlusY, 160, 189, 51, $BoxHeight, $ES_READONLY)
			$txtMinY = GUICtrlCreateInput($MinY, 70, 189, 51, $BoxHeight, $ES_READONLY)
			$txtMinX = GUICtrlCreateInput($MinX, 70, 164, 51, $BoxHeight, $ES_READONLY)
			$txtPlusX = GUICtrlCreateInput($PlusX, 160, 164, 51, $BoxHeight, $ES_READONLY)


			$lblSizeY = GUICtrlCreateLabel($mlblSizeY, 225, 189 + $LabelYOffset, 76, $BoxHeight)
			$txtSizeY = GUICtrlCreateInput($SizeY, 315, 189, 51, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgYTooLargeFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf

			$lblSizeX = GUICtrlCreateLabel($mlblSizeX, 225, 164 + $LabelYOffset, 76, $BoxHeight)
			$txtSizeX = GUICtrlCreateInput($SizeX, 315, 164, 51, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgXTooLargeFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf




			$grpMax = GUICtrlCreateGroup($mgrpMax, 380, 68, 76, 161)
			$txtMaxX = GUICtrlCreateInput($XMax, 390, 164, 51, $BoxHeight, $ES_READONLY)
			GUICtrlCreateGroup("", -99, -99, 1, 1)

			$txtMaxY = GUICtrlCreateInput($YMax, 390, 189, 51, $BoxHeight, $ES_READONLY)
			$txtMaxColor = GUICtrlCreateInput($MaxColors, 389, 117, 51, $BoxHeight, $ES_READONLY)


			$txtPassword = GUICtrlCreateInput("", 255, 394, 150, $BoxHeight, $ES_PASSWORD)
			GUICtrlSetState(-1, $GUI_HIDE)
			$lblOverridePW = GUICtrlCreateLabel($mlblPassword, 152, 395 + $LabelYOffset, 86, $BoxHeight)
			GUICtrlSetState(-1, $GUI_HIDE)

			;GUICtrlSetState($txtPassword, $GUI_SHOW)
			;GUICtrlSetState($lblOverridePW, $GUI_SHOW)

			$txtXMLtime = GUICtrlCreateInput($vtxtXMLtime, 570, 9, 121, $BoxHeight, $ES_READONLY)
			$txtDSTtime = GUICtrlCreateInput($vtxtDSTtime, 570, 30, 121, $BoxHeight, $ES_READONLY)

			$lblMaxTime = GUICtrlCreateLabel($mlblMaxTime, 635, 69 + $LabelYOffset, 56, $BoxHeight)

			$lblTimeDiff = GUICtrlCreateLabel($mlblTimeDiff, 470, 89 + $LabelYOffset,150, $BoxHeight)
			$txtTimeDiff = GUICtrlCreateInput($vtxtXML2DSTdiff, 580, 89, 46, $BoxHeight, $ES_READONLY)
			if BitAND($MessageOrFlags,$msgTooMuchTimeDiffFlag) <> 0 then
				GUICtrlSetBkColor(-1, 0xFF0000)
				GUICtrlSetColor(-1, 0xFFFFFF)
			EndIf


			;GUICtrlSetFont(-1, 8.5, 100)
			$txtMaxTime = GUICtrlCreateInput($MaxTimeBetweenSavesSec, 635, 89, 46, $BoxHeight, $ES_READONLY)
			;$vchkryLandscape = GUICtrlCreateCheckbox($mchkTryLandscape, 30, 369, 116, 20)





			$lblInitFile = GUICtrlCreateLabel($mlblInitFile, 420, 390 + $LabelYOffset, 130, $BoxHeight)
			$txtInitFile = GUICtrlCreateInput($vtxtInitFile, 420,425, 280, $BoxHeight, $ES_READONLY)

			If $Button1 <> "" Then $ID_Button1  = GUICtrlCreateButton($Button1, 30, 420, 111, 31)
			GUICtrlSetState(-1, $GUI_DISABLE)
			If $Button2 <> "" Then $ID_Button2  = GUICtrlCreateButton($Button2, 155, 420, 121, 31)
			If $Button3 <> "" Then $ID_Button3  = GUICtrlCreateButton($Button3, 285, 420, 111, 31)


			GUISetState(@SW_SHOWNORMAL, $hDetailsGUI)			; this must be done before resizing, otherwise it does not resize well.
			Local $WinX= $LanguageArray[Language2Index($Language)][$LanguageDetailWindowX]
			Local $WinY= $LanguageArray[Language2Index($Language)][$LanguageDetailWindowY]
			ConsoleWrite ("WinX=" & $WinX & " WinY=" & $WinY & @CRLF)
			if  $WinX <> 0 And $WinY<> 0 Then
				WinMove($hDetailsGUI,"", Default, Default, $WinX, $WinY)
			EndIf







		EndIf


		; sleep(500)
		; Make the window visible
		;GUISetState(@SW_SHOWNORMAL, $h_MessageGUI)
		ConsoleWrite("na GUISetState" & @CRLF)
		ConsoleWrite("Timeout=" & $TimeOut)
		If $Timeout<> 0 then AdlibRegister("CloseGUI") ;, $TimeOut)

		;sleep(500)
		While 1
			Switch GUIGetMsg()
				Case $GUI_EVENT_NONE
					;ConsoleWrite("voor continueloop"&@CRLF)
					Sleep(100)         ; this is essential to make sure that the window responds
					ContinueLoop
				Case $GUI_EVENT_CLOSE    ;this is when closing the window
					$WhichButtonPressed = 0
					ExitLoop
				Case $ID_Button1
					If $ExitButtonNr = 1 And DisplayPanel(1, $h_MessageGUI, $hdrReallyStop, $msgSure2StopTheScript, $mbtnOK, $mbtnCancel, "") = 1 Then Exit

					$WhichButtonPressed = 1
					ExitLoop
				Case $ID_Button2
					ConsoleWrite("exit button pressed" & @CRLF)
					$WhichButtonPressed = 2
					If $ExitButtonNr = 2 And DisplayPanel(1, $h_MessageGUI, $hdrReallyStop, $msgSure2StopTheScript, $mbtnOK, $mbtnCancel, "") = 1 Then Exit

					;if (msgbox($MB_OKCANCEL+$MB_ICONQUESTION,$hdrAbort,$msgSure2StopTheScript)) = $IDOK then
					;	Exit
					;endif
					ExitLoop


				Case $ID_Button3
					If $ExitButtonNr = 3 And DisplayPanel(1, $h_MessageGUI, $hdrReallyStop, $msgSure2StopTheScript, $mbtnOK, $btnCancel, "") = 1 Then Exit

					$WhichButtonPressed = 3

					ExitLoop

				Case $vchkIgnoreErrors
					ConsoleWrite("Ignore Errors pressed" & @CRLF)
					GUICtrlSetState($txtPassword, $GUI_SHOW)
					GUICtrlSetState($txtPassword, $GUI_FOCUS)
					GUICtrlSetState($lblOverridePW, $GUI_SHOW)
					ContinueLoop

				case $txtPassword
					local $pw = GUICtrlRead ($txtPassword)
					ConsoleWrite("$pw=" & $pw & @CRLF)
					if $pw=$Password then GUICtrlSetState($ID_Button1, $GUI_ENABLE)
					if $pw=$Password then GUICtrlSetState($ID_Button1, $GUI_DEFBUTTON)


					ContinueLoop


				Case $cmbLanguage
					$sComboRead = GUICtrlRead($cmbLanguage)
					; test that indeed a new language has been set
					if $type=2 Then
						Local $CurrentSize = WinGetClientSize($hDetailsGUI)
						ConsoleWrite("Language WindowSizeX=" & $CurrentSize[0] & " WindowSizeY=" & $CurrentSize[1] & @CRLF)

						;save the window sizes for this language
						Local $index = Language2Index($Language)
						$LanguageArray[$index][$LanguageDetailWindowX]=$CurrentSize[0]
						$LanguageArray[$index][$LanguageDetailWindowY]=$CurrentSize[1]
					EndIf


					If $sComboRead <> "" And $sComboRead <> $LanguageArray[Language2Index($Language)][$LanguageName] Then
						; a new language was chosen
						$Language = LanguageName2Language($sComboRead)  ;set the new language
						$LanguageChanged = True  ;make sure we make a next round with the strings in the new language

						SetMessagesInLanguage()    ;update all the message strings to the correct language
						ExitLoop

					EndIf
			EndSwitch

		WEnd


		GUIDelete($GUIhandle2Close)


	WEnd

	consolewrite ("before reenabling the disabled window" & @CRLF)
	If $Window2Disable <> "" Then GUISetState(@SW_ENABLE, $Window2Disable)

	#EndRegion GUI MESSAGE LOOP

	ConsoleWrite("hier" & @CRLF)
	Return $WhichButtonPressed

EndFunc   ;==>DisplayPanel

Func CloseGUI()
	ConsoleWrite("CloseGui is called " & @crlf)
	WinClose($GUIhandle2Close)
	AdlibUnRegister("CloseGUI")
endFunc

Func IsNameForbidden($Filename)

	Local $arr = StringSplit($ForbiddenNames, "|")



	ConsoleWrite("forbidden test $Filename=" & $Filename & @CRLF)

	If IsArray($arr) Then
		For $i = 1 To $arr[0]
			If $arr[$i] = $Filename Then Return True
		Next
	EndIf
	Return False
EndFunc   ;==>IsNameForbidden

Func SplitTimeDateString($TimeDateString)
	; split YYYMMDDHHMMSS string into YYYY-MM-DD HH:MM:SS
	Local $SplittedString = StringLeft($TimeDateString, 4) & "-" & StringMid($TimeDateString, 5, 2) & "-" & StringMid($TimeDateString, 7, 2)
	$SplittedString = $SplittedString & " " & StringMid($TimeDateString, 9, 2) & ":" & StringMid($TimeDateString, 11, 2) & ":" & StringRight($TimeDateString, 2)
	ConsoleWrite($SplittedString & @CRLF)
	Return $SplittedString
EndFunc   ;==>SplitTimeDateString
