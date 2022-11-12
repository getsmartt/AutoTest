Scriptname AutoTest_Suite_NPCsHead extends AutoTest_Suite_NPCs
{
  Collection of script functions testing NPCs head (using screenshots of naked actors).
  This helps in finding issues with neck seams
  Dependencies:
  * ConsoleUtil (https://www.nexusmods.com/skyrimspecialedition/mods/24858)
  * SKSE for StringUtil (https://skse.silverlock.org/)
}
string gModName = ""
string gModName2 = ""
string gFormID
string gPluginID
string BatchCommand = ""
string BatchPath = ""
float gPreviousFov = 65.0
float gPreviousScale = 1.0
string gScreenShotBaseName
int gPrintScreenKey = 183
; Initialize the script
; [API] This function is mandatory and has to use SetTestType
function InitTests()
  SetTestType("NPCsHead")
endFunction

; Prepare the runs of tests
; [API] This function is optional
function BeforeTestsRun()
  gPrintScreenKey = Input.GetMappedKey("Screenshot")
  ; Get the fov value so that we can reset it at the end of the tests run
  gScreenShotBaseName = Utility.GetINIString("sScreenShotBaseName:Display")
  gPreviousFov = Utility.GetINIFloat("fDefault1stPersonFOV:Display")
  gPreviousScale = Game.GetPlayer().GetScale()
  utility.SetINIString ("sScreenShotBaseName:Display","./data/skse/plugins/StorageUtilData/")
  ConsoleUtil.ExecuteCommand("tgm")
  ConsoleUtil.ExecuteCommand("tcai")
  ConsoleUtil.ExecuteCommand("tai")
  ConsoleUtil.ExecuteCommand("fov 20")
  ; Disable UI
  ConsoleUtil.ExecuteCommand("tm")

  BatchCommand = "SETLOCAL EnableExtensions\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPChead.bat", BatchCommand, false, false)

  BatchCommand = ""
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPChead_Custom.bat", BatchCommand, false, false)
endFunction

; Parameters::
; * *testName* (string): The test name to run
; NOTE: This is probably redundant, should inherit from NPC test, but having isues with the Global Variables populating correctly, need to investigate further.
function RunTest(string testName)
  string[] fields = StringUtil.Split(testName, "/")
  gPluginID = fields[0]
  if fields.length == 3
    gModName = fields[2] + "/"
    gModName2 = fields[2]
  else 
    gModName = gPluginID + "/"
    gModName2 = gPluginID
  endIf
  Log("[ " + gPluginID + "/" + gFormID + " ]")
  int formId = 0
  if (StringUtil.SubString(fields[1], 0, 2) == "0x")
    formId = HexToInt(StringUtil.SubString(fields[1], 2))
    gFormID = StringUtil.SubString(fields[1], 2)
  else
    formId = fields[1] as int
      gFormID = IntToHex(formID)
  endIf
  
  if (StringUtil.GetLength(gFormID)) == 8
    if (StringUtil.SubString(gFormID, 0, 2) == "FE")
      gFormID = "0000" + StringUtil.SubString(gFormID, 4)
    else
      gFormID = "00" + StringUtil.SubString(gFormID, 2)
    endIf
  else
    ; need a pad string function
    int s = (StringUtil.GetLength(gFormID))
    if s == 1 
      gFormID = "0000000" + gFormID
    endif
    if s == 2 
      gFormID = "000000" + gFormID
    endif
    if s == 3
      gFormID = "00000" + gFormID
    endif
    if s == 4 
      gFormID = "0000" + gFormID
    endif
    if s == 5 
      gFormID = "000" + gFormID
    endif
    if s == 6 
      gFormID = "00" + gFormID
    endif
    if s == 7 
      gFormID = "0" + gFormID
    endif

  endIf
  Log("[ " + gPluginID + "/" + gFormID + " ]")
  ScreenshotOf(formId, fields[0])
  SetTestStatus(testName, "ok")
 

endFunction

; Finalize the runs of tests
; [API] This function is optional
function AfterTestsRun()
  ConsoleUtil.ExecuteCommand("fov " + gPreviousFov)
  ConsoleUtil.ExecuteCommand("player.setscale " + gPreviousScale)
  ConsoleUtil.ExecuteCommand("tai")
  ConsoleUtil.ExecuteCommand("tcai")
  ConsoleUtil.ExecuteCommand("tgm")
  ; Enable UI
  ConsoleUtil.ExecuteCommand("tm")
  utility.SetINIString ("sScreenShotBaseName:Display",gScreenShotBaseName)
endFunction

; Register a screenshot test of a given BaseID
;
; Parameters:
; * *baseId* (Integer): The BaseID to clone and take screenshot
; * *espName* (String): The name of the ESP containing this base ID
function RegisterScreenshotOf(int baseId, string espName)
  RegisterNewTest(espName + "/" + baseId)
endFunction

; Customize ScreenShot function for better child handling.
function ScreenshotOf(int baseId, string espName)

  float NPCScale = 1.0
  float PlayerScale = 1.0
  float PlayerFOV = 10
  string[] aScreenShots

  int formId = baseId + Game.GetModByName(espName) * 16777216
  Form formToSpawn = Game.GetFormFromFile(formId, espName)
  string formName = formToSpawn.GetName()
  Log("[ " + espName + "/" + baseId + " ] - [ Start ] - Take screenshot of FormID 0x" + formId + " (" + formName + ")")
  Game.GetPlayer().MoveTo(ViewPointAnchor)
  ObjectReference newRef = TeleportAnchor.PlaceAtMe(formToSpawn)
  
  newRef.RemoveAllItems()
  ; Wait for the 3D model to be loaded
 
  while (!newRef.Is3DLoaded())
    Utility.wait(0.2)
  endWhile
  Utility.wait(1.0)

  ; get NPC Scale
  NPCScale = newRef.GetScale()
  ; Log("NPC Scale " + NPCScale)
  ; set PC Scale
  ConsoleUtil.ExecuteCommand("player.setscale " + (NPCScale - 0.02))
  PlayerScale = Game.GetPlayer().GetScale()
  ; Log("Player Scale " + PlayerScale)
  ; Set FOV based on scale. Note: may still need tweaking
  if PlayerScale >= 0.7 
    PlayerFOV = 15
  endIf
  if PlayerScale >= 1 
    PlayerFOV = 20
  endIf
  ConsoleUtil.ExecuteCommand("fov " + PlayerFOV)
  ; ensure PC 1st party view
  Game.ForceFirstPerson()
  

  ; Print Screen
  

  Input.TapKey(gPrintScreenKey)
  
  Utility.wait(1.0)
  ; Rename/Relocate Screenshots
  ; Option 1: mugshots/modname/plugin name/npc formid.png (EasyNPC format)
  ; Option 2: NPC Name (formid) - Modname - Plugin.png
  aScreenShots = MiscUtil.FilesInFolder("./data/skse/plugins/StorageUtilData/", "png")
  int s 
  s = aScreenShots.Length
  s = (s - 1)

  BatchCommand = "Rename " +  aScreenShots[s] + " \"" + formName + " (" + gFormID + ") - " + gModName2 + " - " + gPluginID  + ".png\"\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPChead_Custom.bat", BatchCommand, true, false)

  BatchCommand = "if not exist " + " \"mugshots/" + gModName  + gPluginID  + "\"/ " + "md " + " \"mugshots/" + gModName  + gPluginID  + "\"\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPChead.bat", BatchCommand, true, false)
  ; Log("[Batch Command - " + BatchCommand + "]")
  BatchCommand = "Move " +  aScreenShots[s] + " \"./mugshots/" + gModName  + gPluginID  + "/" + gFormID  + ".png\"\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPChead.bat", BatchCommand, true, false)
  ; Log("[Batch Command - " + BatchCommand + "]")

  ; Remove the reference
  newRef.DisableNoWait()
  newRef.Delete()
  newRef = None
  Log("[ " + espName + "/" + baseId + " ] - [ OK ] - Take screenshot of FormID 0x" + formId + " (" + formName + ")")
endFunction
