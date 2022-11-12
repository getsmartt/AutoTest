Scriptname AutoTest_Suite_NPCs extends AutoTest_Suite
{
  Collection of script functions testing NPCs (using screenshots of naked actors).
  This helps in finding issues with missing textures, not fitting body types...
  Dependencies:
  * ConsoleUtil (https://www.nexusmods.com/skyrimspecialedition/mods/24858)
  * SKSE for StringUtil (https://skse.silverlock.org/)
}

; Marker where the player is teleported for screenshots
ObjectReference Property ViewPointAnchor Auto

; Marker where the NPCs are teleported for screenshots
ObjectReference Property TeleportAnchor Auto

string gModName = ""
string gModName2 = ""
string gScreenShotBaseName
string gFormID
string gPluginID
string BatchCommand = ""
string BatchPath = ""
int gPrintScreenKey = 183

; Initialize the script
; [API] This function is mandatory and has to use SetTestType
function InitTests()
  SetTestType("NPCs")
endFunction

; Register tests
; [API] This function is mandatory
function RegisterTests()
  RegisterAllSkyrimSSENPCs()
endFunction

; Prepare the runs of tests
; [API] This function is optional
function BeforeTestsRun()
  ; TODO: get PC Scale
  gPrintScreenKey = Input.GetMappedKey("Screenshot")
  gScreenShotBaseName = Utility.GetINIString("sScreenShotBaseName:Display")
  ; Log("[User ScreenShot Folder - " + gScreenShotBaseName + "]")
  utility.SetINIString ("sScreenShotBaseName:Display","./data/skse/plugins/StorageUtilData/")
  ConsoleUtil.ExecuteCommand("tgm")
  ConsoleUtil.ExecuteCommand("tcai")
  ConsoleUtil.ExecuteCommand("tai")
  
  ConsoleUtil.ExecuteCommand("tm")
  BatchCommand = "SETLOCAL EnableExtensions\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPC.bat", BatchCommand, false, false)

  BatchCommand = ""
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPC_Custom.bat", BatchCommand, false, false)
; todo delete old png files

endFunction

; Run a given registered test.
; Set the status in this method.
; [API] This function is mandatory
;
; Parameters::
; * *testName* (string): The test name to run
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
  ; TODO: set PC Scale
  ConsoleUtil.ExecuteCommand("tai")
  ConsoleUtil.ExecuteCommand("tcai")
  ConsoleUtil.ExecuteCommand("tgm")
  
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

; Take a screenshot of a given BaseID
;
; Parameters:
; * *baseId* (Integer): The BaseID to clone and take screenshot
; * *espName* (String): The name of the ESP containing this base ID
function ScreenshotOf(int baseId, string espName)
  
  string[] aScreenShots
  int formId = baseId + Game.GetModByName(espName) * 16777216
  Form formToSpawn = Game.GetFormFromFile(formId, espName)
  string formName = formToSpawn.GetName()
  Log("[ " + espName + "/" + baseId + " ] - [ Start ] - Take screenshot of FormID 0x" + formId + " (" + formName + ")")
  Game.GetPlayer().MoveTo(ViewPointAnchor)
  ObjectReference newRef = TeleportAnchor.PlaceAtMe(formToSpawn)
  

  string nonNudeNPC = GetConfig("non_nude")
  if nonNudeNPC != "true"
    nonNudeNPC = "false"
  endIf

  if nonNudeNPC == "false"
    newRef.RemoveAllItems()
  endIf
  
  ; Wait for the 3D model to be loaded
  while (!newRef.Is3DLoaded())
    Utility.wait(0.2)
  endWhile
  Utility.wait(1.0)

  ; ensure PC 1st party view (summoning some NPCs seem to change POV)
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
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPC_Custom.bat", BatchCommand, true, false)

  BatchCommand = "if not exist " + " \"mugshots/" + gModName  + gPluginID  + "/body\"/ " + "md " + " \"mugshots/" + gModName  + gPluginID  + "/body\"\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPC.bat", BatchCommand, true, false)
  ; Log("[Batch Command - " + BatchCommand + "]")
  BatchCommand = "Move " +  aScreenShots[s] + " \"./mugshots/" + gModName  + gPluginID  + "/body/" + gFormID  + ".png\"\n"
  MiscUtil.WriteToFile("./data/skse/plugins/StorageUtilData/renameNPC.bat", BatchCommand, true, false)
  ; Log("[Batch Command - " + BatchCommand + "]")
  ; Remove the reference
  newRef.DisableNoWait()
  newRef.Delete()
  newRef = None
  Log("[ " + espName + "/" + baseId + " ] - [ OK ] - Take screenshot of FormID 0x" + formId + " (" + formName + ")")
endFunction

; Register Screenshot tests of all NPCs from Skyrim SSE Vanilla + DLC that are having a name
; To get this list (and to get a similar list for NPCs of other mods):
; 1. Download "Automation Tools for TES5Edit" from https://www.nexusmods.com/skyrim/mods/49373/ and install it in SSEEdit
; 2. Launch SSEEdit, and select only the ESP from which we extract NPCs
; 3. "Apply Filter" only on records of type NPC_
; 4. "Apply Script" named "AT - QuickDisplay", and export the path "FULL" as a string in CSV.
; 5. Open the exported.csv (from "SSEEdit/Edit Scripts" folder), select FormIDs of only rows having a name in the column FULL, and having a FormID greater than 16777216 * <nbrMasters>
function RegisterAllSkyrimSSENPCs()
  RegisterScreenshotOf(554831, "Skyrim.esm")
  RegisterScreenshotOf(867961, "Skyrim.esm")
  RegisterScreenshotOf(78725, "Skyrim.esm")
  RegisterScreenshotOf(78421, "Skyrim.esm")
  RegisterScreenshotOf(105927, "Skyrim.esm")
  RegisterScreenshotOf(418221, "Skyrim.esm")
  RegisterScreenshotOf(82205, "Skyrim.esm")
  RegisterScreenshotOf(82206, "Skyrim.esm")
  RegisterScreenshotOf(82236, "Skyrim.esm")
  RegisterScreenshotOf(80825, "Skyrim.esm")
  RegisterScreenshotOf(105471, "Skyrim.esm")
  RegisterScreenshotOf(521874, "Skyrim.esm")
  RegisterScreenshotOf(1070399, "Skyrim.esm")
  RegisterScreenshotOf(972149, "Skyrim.esm")
  RegisterScreenshotOf(937261, "Skyrim.esm")
  RegisterScreenshotOf(792427, "Skyrim.esm")
  RegisterScreenshotOf(674997, "Skyrim.esm")
  RegisterScreenshotOf(549063, "Skyrim.esm")
  RegisterScreenshotOf(549062, "Skyrim.esm")
  RegisterScreenshotOf(549061, "Skyrim.esm")
  RegisterScreenshotOf(549060, "Skyrim.esm")
  RegisterScreenshotOf(549059, "Skyrim.esm")
  RegisterScreenshotOf(537209, "Skyrim.esm")
  RegisterScreenshotOf(478144, "Skyrim.esm")
  RegisterScreenshotOf(351143, "Skyrim.esm")
  RegisterScreenshotOf(108182, "Skyrim.esm")
  RegisterScreenshotOf(79371, "Skyrim.esm")
  RegisterScreenshotOf(78662, "Skyrim.esm")
  RegisterScreenshotOf(1032600, "Skyrim.esm")
  RegisterScreenshotOf(412226, "Skyrim.esm")
  RegisterScreenshotOf(277176, "Skyrim.esm")
  RegisterScreenshotOf(781797, "Skyrim.esm")
  RegisterScreenshotOf(781796, "Skyrim.esm")
  RegisterScreenshotOf(781795, "Skyrim.esm")
  RegisterScreenshotOf(907678, "Skyrim.esm")
  RegisterScreenshotOf(693657, "Skyrim.esm")
  RegisterScreenshotOf(79333, "Skyrim.esm")
  RegisterScreenshotOf(131140, "Skyrim.esm")
  RegisterScreenshotOf(539417, "Skyrim.esm")
  RegisterScreenshotOf(843910, "Skyrim.esm")
  RegisterScreenshotOf(111062, "Skyrim.esm")
  RegisterScreenshotOf(80830, "Skyrim.esm")
  RegisterScreenshotOf(78431, "Skyrim.esm")
  RegisterScreenshotOf(78428, "Skyrim.esm")
  RegisterScreenshotOf(81966, "Skyrim.esm")
  RegisterScreenshotOf(380726, "Skyrim.esm")
  RegisterScreenshotOf(80745, "Skyrim.esm")
  RegisterScreenshotOf(110708, "Skyrim.esm")
  RegisterScreenshotOf(628741, "Skyrim.esm")
  RegisterScreenshotOf(336488, "Skyrim.esm")
  RegisterScreenshotOf(582897, "Skyrim.esm")
  RegisterScreenshotOf(207764, "Skyrim.esm")
  RegisterScreenshotOf(189423, "Skyrim.esm")
  RegisterScreenshotOf(78663, "Skyrim.esm")
  RegisterScreenshotOf(800524, "Skyrim.esm")
  RegisterScreenshotOf(396073, "Skyrim.esm")
  RegisterScreenshotOf(636843, "Skyrim.esm")
  RegisterScreenshotOf(80816, "Skyrim.esm")
  RegisterScreenshotOf(136693, "Skyrim.esm")
  RegisterScreenshotOf(1111466, "Skyrim.esm")
  RegisterScreenshotOf(1111457, "Skyrim.esm")
  RegisterScreenshotOf(1084661, "Skyrim.esm")
  RegisterScreenshotOf(423470, "Skyrim.esm")
  RegisterScreenshotOf(363327, "Skyrim.esm")
  RegisterScreenshotOf(352178, "Skyrim.esm")
  RegisterScreenshotOf(131185, "Skyrim.esm")
  RegisterScreenshotOf(627482, "Skyrim.esm")
  RegisterScreenshotOf(79334, "Skyrim.esm")
  RegisterScreenshotOf(78965, "Skyrim.esm")
  RegisterScreenshotOf(321103, "Skyrim.esm")
  RegisterScreenshotOf(242746, "Skyrim.esm")
  RegisterScreenshotOf(82238, "Skyrim.esm")
  RegisterScreenshotOf(80810, "Skyrim.esm")
  RegisterScreenshotOf(124887, "Skyrim.esm")
  RegisterScreenshotOf(1016094, "Skyrim.esm")
  RegisterScreenshotOf(1016092, "Skyrim.esm")
  RegisterScreenshotOf(211025, "Skyrim.esm")
  RegisterScreenshotOf(1045028, "Skyrim.esm")
  RegisterScreenshotOf(80808, "Skyrim.esm")
  RegisterScreenshotOf(78432, "Skyrim.esm")
  RegisterScreenshotOf(653393, "Skyrim.esm")
  RegisterScreenshotOf(830255, "Skyrim.esm")
  RegisterScreenshotOf(82231, "Skyrim.esm")
  RegisterScreenshotOf(714621, "Skyrim.esm")
  RegisterScreenshotOf(909190, "Skyrim.esm")
  RegisterScreenshotOf(79462, "Skyrim.esm")
  RegisterScreenshotOf(80791, "Skyrim.esm")
  RegisterScreenshotOf(279539, "Skyrim.esm")
  RegisterScreenshotOf(78727, "Skyrim.esm")
  RegisterScreenshotOf(78665, "Skyrim.esm")
  RegisterScreenshotOf(78726, "Skyrim.esm")
  RegisterScreenshotOf(921534, "Skyrim.esm")
  RegisterScreenshotOf(447023, "Skyrim.esm")
  RegisterScreenshotOf(921535, "Skyrim.esm")
  RegisterScreenshotOf(285791, "Skyrim.esm")
  RegisterScreenshotOf(921536, "Skyrim.esm")
  RegisterScreenshotOf(285792, "Skyrim.esm")
  RegisterScreenshotOf(921537, "Skyrim.esm")
  RegisterScreenshotOf(346367, "Skyrim.esm")
  RegisterScreenshotOf(921538, "Skyrim.esm")
  RegisterScreenshotOf(285793, "Skyrim.esm")
  RegisterScreenshotOf(879320, "Skyrim.esm")
  RegisterScreenshotOf(166608, "Skyrim.esm")
  RegisterScreenshotOf(80804, "Skyrim.esm")
  RegisterScreenshotOf(1085869, "Skyrim.esm")
  RegisterScreenshotOf(1085864, "Skyrim.esm")
  RegisterScreenshotOf(1085871, "Skyrim.esm")
  RegisterScreenshotOf(1085866, "Skyrim.esm")
  RegisterScreenshotOf(1085873, "Skyrim.esm")
  RegisterScreenshotOf(1085868, "Skyrim.esm")
  RegisterScreenshotOf(1085872, "Skyrim.esm")
  RegisterScreenshotOf(1085867, "Skyrim.esm")
  RegisterScreenshotOf(1085870, "Skyrim.esm")
  RegisterScreenshotOf(1085865, "Skyrim.esm")
  RegisterScreenshotOf(317130, "Skyrim.esm")
  RegisterScreenshotOf(781706, "Skyrim.esm")
  RegisterScreenshotOf(79362, "Skyrim.esm")
  RegisterScreenshotOf(666764, "Skyrim.esm")
  RegisterScreenshotOf(1073432, "Skyrim.esm")
  RegisterScreenshotOf(1070433, "Skyrim.esm")
  RegisterScreenshotOf(1070420, "Skyrim.esm")
  RegisterScreenshotOf(1070418, "Skyrim.esm")
  RegisterScreenshotOf(284670, "Skyrim.esm")
  RegisterScreenshotOf(284667, "Skyrim.esm")
  RegisterScreenshotOf(266703, "Skyrim.esm")
  RegisterScreenshotOf(78666, "Skyrim.esm")
  RegisterScreenshotOf(82215, "Skyrim.esm")
  RegisterScreenshotOf(206998, "Skyrim.esm")
  RegisterScreenshotOf(114096, "Skyrim.esm")
  RegisterScreenshotOf(181959, "Skyrim.esm")
  RegisterScreenshotOf(115101, "Skyrim.esm")
  RegisterScreenshotOf(434514, "Skyrim.esm")
  RegisterScreenshotOf(171437, "Skyrim.esm")
  RegisterScreenshotOf(80763, "Skyrim.esm")
  RegisterScreenshotOf(228736, "Skyrim.esm")
  RegisterScreenshotOf(542034, "Skyrim.esm")
  RegisterScreenshotOf(629137, "Skyrim.esm")
  RegisterScreenshotOf(235078, "Skyrim.esm")
  RegisterScreenshotOf(105970, "Skyrim.esm")
  RegisterScreenshotOf(921549, "Skyrim.esm")
  RegisterScreenshotOf(447026, "Skyrim.esm")
  RegisterScreenshotOf(921552, "Skyrim.esm")
  RegisterScreenshotOf(348590, "Skyrim.esm")
  RegisterScreenshotOf(78667, "Skyrim.esm")
  RegisterScreenshotOf(79335, "Skyrim.esm")
  RegisterScreenshotOf(480203, "Skyrim.esm")
  RegisterScreenshotOf(1069563, "Skyrim.esm")
  RegisterScreenshotOf(115082, "Skyrim.esm")
  RegisterScreenshotOf(89387, "Skyrim.esm")
  RegisterScreenshotOf(317136, "Skyrim.esm")
  RegisterScreenshotOf(114100, "Skyrim.esm")
  RegisterScreenshotOf(78485, "Skyrim.esm")
  RegisterScreenshotOf(111066, "Skyrim.esm")
  RegisterScreenshotOf(402149, "Skyrim.esm")
  RegisterScreenshotOf(108245, "Skyrim.esm")
  RegisterScreenshotOf(755590, "Skyrim.esm")
  RegisterScreenshotOf(106008, "Skyrim.esm")
  RegisterScreenshotOf(744834, "Skyrim.esm")
  RegisterScreenshotOf(388463, "Skyrim.esm")
  RegisterScreenshotOf(704312, "Skyrim.esm")
  RegisterScreenshotOf(566210, "Skyrim.esm")
  RegisterScreenshotOf(377605, "Skyrim.esm")
  RegisterScreenshotOf(316072, "Skyrim.esm")
  RegisterScreenshotOf(193264, "Skyrim.esm")
  RegisterScreenshotOf(289667, "Skyrim.esm")
  RegisterScreenshotOf(1113444, "Skyrim.esm")
  RegisterScreenshotOf(783442, "Skyrim.esm")
  RegisterScreenshotOf(577389, "Skyrim.esm")
  RegisterScreenshotOf(445999, "Skyrim.esm")
  RegisterScreenshotOf(519625, "Skyrim.esm")
  RegisterScreenshotOf(1047048, "Skyrim.esm")
  RegisterScreenshotOf(423322, "Skyrim.esm")
  RegisterScreenshotOf(806447, "Skyrim.esm")
  RegisterScreenshotOf(386002, "Skyrim.esm")
  RegisterScreenshotOf(789898, "Skyrim.esm")
  RegisterScreenshotOf(291710, "Skyrim.esm")
  RegisterScreenshotOf(1021508, "Skyrim.esm")
  RegisterScreenshotOf(542596, "Skyrim.esm")
  RegisterScreenshotOf(316098, "Skyrim.esm")
  RegisterScreenshotOf(114784, "Skyrim.esm")
  RegisterScreenshotOf(256161, "Skyrim.esm")
  RegisterScreenshotOf(98105, "Skyrim.esm")
  RegisterScreenshotOf(98106, "Skyrim.esm")
  RegisterScreenshotOf(785194, "Skyrim.esm")
  RegisterScreenshotOf(231987, "Skyrim.esm")
  RegisterScreenshotOf(783708, "Skyrim.esm")
  RegisterScreenshotOf(692735, "Skyrim.esm")
  RegisterScreenshotOf(231985, "Skyrim.esm")
  RegisterScreenshotOf(1015469, "Skyrim.esm")
  RegisterScreenshotOf(867034, "Skyrim.esm")
  RegisterScreenshotOf(867037, "Skyrim.esm")
  RegisterScreenshotOf(689607, "Skyrim.esm")
  RegisterScreenshotOf(179432, "Skyrim.esm")
  RegisterScreenshotOf(82240, "Skyrim.esm")
  RegisterScreenshotOf(82226, "Skyrim.esm")
  RegisterScreenshotOf(105470, "Skyrim.esm")
  RegisterScreenshotOf(80794, "Skyrim.esm")
  RegisterScreenshotOf(166633, "Skyrim.esm")
  RegisterScreenshotOf(105002, "Skyrim.esm")
  RegisterScreenshotOf(736385, "Skyrim.esm")
  RegisterScreenshotOf(119991, "Skyrim.esm")
  RegisterScreenshotOf(714617, "Skyrim.esm")
  RegisterScreenshotOf(104789, "Skyrim.esm")
  RegisterScreenshotOf(232558, "Skyrim.esm")
  RegisterScreenshotOf(744770, "Skyrim.esm")
  RegisterScreenshotOf(80829, "Skyrim.esm")
  RegisterScreenshotOf(78668, "Skyrim.esm")
  RegisterScreenshotOf(236788, "Skyrim.esm")
  RegisterScreenshotOf(923206, "Skyrim.esm")
  RegisterScreenshotOf(786487, "Skyrim.esm")
  RegisterScreenshotOf(253719, "Skyrim.esm")
  RegisterScreenshotOf(110827, "Skyrim.esm")
  RegisterScreenshotOf(110817, "Skyrim.esm")
  RegisterScreenshotOf(110814, "Skyrim.esm")
  RegisterScreenshotOf(110813, "Skyrim.esm")
  RegisterScreenshotOf(110812, "Skyrim.esm")
  RegisterScreenshotOf(110811, "Skyrim.esm")
  RegisterScreenshotOf(110808, "Skyrim.esm")
  RegisterScreenshotOf(236874, "Skyrim.esm")
  RegisterScreenshotOf(228405, "Skyrim.esm")
  RegisterScreenshotOf(124429, "Skyrim.esm")
  RegisterScreenshotOf(591673, "Skyrim.esm")
  RegisterScreenshotOf(236888, "Skyrim.esm")
  RegisterScreenshotOf(228419, "Skyrim.esm")
  RegisterScreenshotOf(124433, "Skyrim.esm")
  RegisterScreenshotOf(236856, "Skyrim.esm")
  RegisterScreenshotOf(228397, "Skyrim.esm")
  RegisterScreenshotOf(113881, "Skyrim.esm")
  RegisterScreenshotOf(236881, "Skyrim.esm")
  RegisterScreenshotOf(228412, "Skyrim.esm")
  RegisterScreenshotOf(124432, "Skyrim.esm")
  RegisterScreenshotOf(236867, "Skyrim.esm")
  RegisterScreenshotOf(228398, "Skyrim.esm")
  RegisterScreenshotOf(113882, "Skyrim.esm")
  RegisterScreenshotOf(632744, "Skyrim.esm")
  RegisterScreenshotOf(948637, "Skyrim.esm")
  RegisterScreenshotOf(114629, "Skyrim.esm")
  RegisterScreenshotOf(885309, "Skyrim.esm")
  RegisterScreenshotOf(770169, "Skyrim.esm")
  RegisterScreenshotOf(79553, "Skyrim.esm")
  RegisterScreenshotOf(843932, "Skyrim.esm")
  RegisterScreenshotOf(146058, "Skyrim.esm")
  RegisterScreenshotOf(555934, "Skyrim.esm")
  RegisterScreenshotOf(445787, "Skyrim.esm")
  RegisterScreenshotOf(78433, "Skyrim.esm")
  RegisterScreenshotOf(79378, "Skyrim.esm")
  RegisterScreenshotOf(80747, "Skyrim.esm")
  RegisterScreenshotOf(80801, "Skyrim.esm")
  RegisterScreenshotOf(760193, "Skyrim.esm")
  RegisterScreenshotOf(82232, "Skyrim.esm")
  RegisterScreenshotOf(948171, "Skyrim.esm")
  RegisterScreenshotOf(125260, "Skyrim.esm")
  RegisterScreenshotOf(79336, "Skyrim.esm")
  RegisterScreenshotOf(80819, "Skyrim.esm")
  RegisterScreenshotOf(848804, "Skyrim.esm")
  RegisterScreenshotOf(78669, "Skyrim.esm")
  RegisterScreenshotOf(78728, "Skyrim.esm")
  RegisterScreenshotOf(555926, "Skyrim.esm")
  RegisterScreenshotOf(115079, "Skyrim.esm")
  RegisterScreenshotOf(78434, "Skyrim.esm")
  RegisterScreenshotOf(79465, "Skyrim.esm")
  RegisterScreenshotOf(708764, "Skyrim.esm")
  RegisterScreenshotOf(290436, "Skyrim.esm")
  RegisterScreenshotOf(903388, "Skyrim.esm")
  RegisterScreenshotOf(903387, "Skyrim.esm")
  RegisterScreenshotOf(903386, "Skyrim.esm")
  RegisterScreenshotOf(903385, "Skyrim.esm")
  RegisterScreenshotOf(903384, "Skyrim.esm")
  RegisterScreenshotOf(555921, "Skyrim.esm")
  RegisterScreenshotOf(1016061, "Skyrim.esm")
  RegisterScreenshotOf(945526, "Skyrim.esm")
  RegisterScreenshotOf(945525, "Skyrim.esm")
  RegisterScreenshotOf(945524, "Skyrim.esm")
  RegisterScreenshotOf(945523, "Skyrim.esm")
  RegisterScreenshotOf(945521, "Skyrim.esm")
  RegisterScreenshotOf(896652, "Skyrim.esm")
  RegisterScreenshotOf(896646, "Skyrim.esm")
  RegisterScreenshotOf(211022, "Skyrim.esm")
  RegisterScreenshotOf(554716, "Skyrim.esm")
  RegisterScreenshotOf(758182, "Skyrim.esm")
  RegisterScreenshotOf(653406, "Skyrim.esm")
  RegisterScreenshotOf(724615, "Skyrim.esm")
  RegisterScreenshotOf(317653, "Skyrim.esm")
  RegisterScreenshotOf(317652, "Skyrim.esm")
  RegisterScreenshotOf(317651, "Skyrim.esm")
  RegisterScreenshotOf(317650, "Skyrim.esm")
  RegisterScreenshotOf(317649, "Skyrim.esm")
  RegisterScreenshotOf(110710, "Skyrim.esm")
  RegisterScreenshotOf(82214, "Skyrim.esm")
  RegisterScreenshotOf(78436, "Skyrim.esm")
  RegisterScreenshotOf(78670, "Skyrim.esm")
  RegisterScreenshotOf(79441, "Skyrim.esm")
  RegisterScreenshotOf(817377, "Skyrim.esm")
  RegisterScreenshotOf(104793, "Skyrim.esm")
  RegisterScreenshotOf(554930, "Skyrim.esm")
  RegisterScreenshotOf(78730, "Skyrim.esm")
  RegisterScreenshotOf(181966, "Skyrim.esm")
  RegisterScreenshotOf(80834, "Skyrim.esm")
  RegisterScreenshotOf(78731, "Skyrim.esm")
  RegisterScreenshotOf(79550, "Skyrim.esm")
  RegisterScreenshotOf(758953, "Skyrim.esm")
  RegisterScreenshotOf(1016106, "Skyrim.esm")
  RegisterScreenshotOf(770209, "Skyrim.esm")
  RegisterScreenshotOf(770208, "Skyrim.esm")
  RegisterScreenshotOf(770207, "Skyrim.esm")
  RegisterScreenshotOf(78729, "Skyrim.esm")
  RegisterScreenshotOf(80809, "Skyrim.esm")
  RegisterScreenshotOf(78671, "Skyrim.esm")
  RegisterScreenshotOf(841292, "Skyrim.esm")
  RegisterScreenshotOf(433976, "Skyrim.esm")
  RegisterScreenshotOf(115094, "Skyrim.esm")
  RegisterScreenshotOf(80807, "Skyrim.esm")
  RegisterScreenshotOf(1062140, "Skyrim.esm")
  RegisterScreenshotOf(1062139, "Skyrim.esm")
  RegisterScreenshotOf(1062131, "Skyrim.esm")
  RegisterScreenshotOf(284671, "Skyrim.esm")
  RegisterScreenshotOf(284662, "Skyrim.esm")
  RegisterScreenshotOf(313172, "Skyrim.esm")
  RegisterScreenshotOf(313124, "Skyrim.esm")
  RegisterScreenshotOf(361979, "Skyrim.esm")
  RegisterScreenshotOf(108194, "Skyrim.esm")
  RegisterScreenshotOf(108215, "Skyrim.esm")
  RegisterScreenshotOf(79545, "Skyrim.esm")
  RegisterScreenshotOf(82244, "Skyrim.esm")
  RegisterScreenshotOf(78732, "Skyrim.esm")
  RegisterScreenshotOf(82249, "Skyrim.esm")
  RegisterScreenshotOf(78437, "Skyrim.esm")
  RegisterScreenshotOf(110717, "Skyrim.esm")
  RegisterScreenshotOf(79379, "Skyrim.esm")
  RegisterScreenshotOf(878334, "Skyrim.esm")
  RegisterScreenshotOf(78734, "Skyrim.esm")
  RegisterScreenshotOf(666768, "Skyrim.esm")
  RegisterScreenshotOf(82250, "Skyrim.esm")
  RegisterScreenshotOf(78971, "Skyrim.esm")
  RegisterScreenshotOf(270264, "Skyrim.esm")
  RegisterScreenshotOf(87271, "Skyrim.esm")
  RegisterScreenshotOf(811069, "Skyrim.esm")
  RegisterScreenshotOf(123787, "Skyrim.esm")
  RegisterScreenshotOf(82228, "Skyrim.esm")
  RegisterScreenshotOf(117239, "Skyrim.esm")
  RegisterScreenshotOf(517556, "Skyrim.esm")
  RegisterScreenshotOf(78486, "Skyrim.esm")
  RegisterScreenshotOf(412106, "Skyrim.esm")
  RegisterScreenshotOf(80793, "Skyrim.esm")
  RegisterScreenshotOf(271660, "Skyrim.esm")
  RegisterScreenshotOf(271534, "Skyrim.esm")
  RegisterScreenshotOf(135687, "Skyrim.esm")
  RegisterScreenshotOf(1011443, "Skyrim.esm")
  RegisterScreenshotOf(630905, "Skyrim.esm")
  RegisterScreenshotOf(146059, "Skyrim.esm")
  RegisterScreenshotOf(78735, "Skyrim.esm")
  RegisterScreenshotOf(450604, "Skyrim.esm")
  RegisterScreenshotOf(537854, "Skyrim.esm")
  RegisterScreenshotOf(677376, "Skyrim.esm")
  RegisterScreenshotOf(146063, "Skyrim.esm")
  RegisterScreenshotOf(692640, "Skyrim.esm")
  RegisterScreenshotOf(80761, "Skyrim.esm")
  RegisterScreenshotOf(104785, "Skyrim.esm")
  RegisterScreenshotOf(110709, "Skyrim.esm")
  RegisterScreenshotOf(244774, "Skyrim.esm")
  RegisterScreenshotOf(591672, "Skyrim.esm")
  RegisterScreenshotOf(638127, "Skyrim.esm")
  RegisterScreenshotOf(348400, "Skyrim.esm")
  RegisterScreenshotOf(114097, "Skyrim.esm")
  RegisterScreenshotOf(115940, "Skyrim.esm")
  RegisterScreenshotOf(105004, "Skyrim.esm")
  RegisterScreenshotOf(555933, "Skyrim.esm")
  RegisterScreenshotOf(115098, "Skyrim.esm")
  RegisterScreenshotOf(1072315, "Skyrim.esm")
  RegisterScreenshotOf(229975, "Skyrim.esm")
  RegisterScreenshotOf(119989, "Skyrim.esm")
  RegisterScreenshotOf(253004, "Skyrim.esm")
  RegisterScreenshotOf(910617, "Skyrim.esm")
  RegisterScreenshotOf(910616, "Skyrim.esm")
  RegisterScreenshotOf(910615, "Skyrim.esm")
  RegisterScreenshotOf(910614, "Skyrim.esm")
  RegisterScreenshotOf(700676, "Skyrim.esm")
  RegisterScreenshotOf(700674, "Skyrim.esm")
  RegisterScreenshotOf(653380, "Skyrim.esm")
  RegisterScreenshotOf(921544, "Skyrim.esm")
  RegisterScreenshotOf(447025, "Skyrim.esm")
  RegisterScreenshotOf(921539, "Skyrim.esm")
  RegisterScreenshotOf(447024, "Skyrim.esm")
  RegisterScreenshotOf(78672, "Skyrim.esm")
  RegisterScreenshotOf(567455, "Skyrim.esm")
  RegisterScreenshotOf(567454, "Skyrim.esm")
  RegisterScreenshotOf(567453, "Skyrim.esm")
  RegisterScreenshotOf(567452, "Skyrim.esm")
  RegisterScreenshotOf(78438, "Skyrim.esm")
  RegisterScreenshotOf(555916, "Skyrim.esm")
  RegisterScreenshotOf(1006523, "Skyrim.esm")
  RegisterScreenshotOf(1006522, "Skyrim.esm")
  RegisterScreenshotOf(1006521, "Skyrim.esm")
  RegisterScreenshotOf(965125, "Skyrim.esm")
  RegisterScreenshotOf(964726, "Skyrim.esm")
  RegisterScreenshotOf(964720, "Skyrim.esm")
  RegisterScreenshotOf(1049959, "Skyrim.esm")
  RegisterScreenshotOf(1049958, "Skyrim.esm")
  RegisterScreenshotOf(941880, "Skyrim.esm")
  RegisterScreenshotOf(374293, "Skyrim.esm")
  RegisterScreenshotOf(78736, "Skyrim.esm")
  RegisterScreenshotOf(1074672, "Skyrim.esm")
  RegisterScreenshotOf(1074671, "Skyrim.esm")
  RegisterScreenshotOf(1074670, "Skyrim.esm")
  RegisterScreenshotOf(434458, "Skyrim.esm")
  RegisterScreenshotOf(237443, "Skyrim.esm")
  RegisterScreenshotOf(801265, "Skyrim.esm")
  RegisterScreenshotOf(419870, "Skyrim.esm")
  RegisterScreenshotOf(146064, "Skyrim.esm")
  RegisterScreenshotOf(331970, "Skyrim.esm")
  RegisterScreenshotOf(921556, "Skyrim.esm")
  RegisterScreenshotOf(285887, "Skyrim.esm")
  RegisterScreenshotOf(297813, "Skyrim.esm")
  RegisterScreenshotOf(521258, "Skyrim.esm")
  RegisterScreenshotOf(108211, "Skyrim.esm")
  RegisterScreenshotOf(872408, "Skyrim.esm")
  RegisterScreenshotOf(82763, "Skyrim.esm")
  RegisterScreenshotOf(115075, "Skyrim.esm")
  RegisterScreenshotOf(78737, "Skyrim.esm")
  RegisterScreenshotOf(78500, "Skyrim.esm")
  RegisterScreenshotOf(80805, "Skyrim.esm")
  RegisterScreenshotOf(644961, "Skyrim.esm")
  RegisterScreenshotOf(89342, "Skyrim.esm")
  RegisterScreenshotOf(89338, "Skyrim.esm")
  RegisterScreenshotOf(1062143, "Skyrim.esm")
  RegisterScreenshotOf(1062142, "Skyrim.esm")
  RegisterScreenshotOf(284672, "Skyrim.esm")
  RegisterScreenshotOf(284663, "Skyrim.esm")
  RegisterScreenshotOf(554365, "Skyrim.esm")
  RegisterScreenshotOf(554238, "Skyrim.esm")
  RegisterScreenshotOf(554237, "Skyrim.esm")
  RegisterScreenshotOf(554236, "Skyrim.esm")
  RegisterScreenshotOf(554235, "Skyrim.esm")
  RegisterScreenshotOf(186261, "Skyrim.esm")
  RegisterScreenshotOf(186260, "Skyrim.esm")
  RegisterScreenshotOf(315103, "Skyrim.esm")
  RegisterScreenshotOf(746533, "Skyrim.esm")
  RegisterScreenshotOf(78440, "Skyrim.esm")
  RegisterScreenshotOf(131136, "Skyrim.esm")
  RegisterScreenshotOf(769440, "Skyrim.esm")
  RegisterScreenshotOf(861338, "Skyrim.esm")
  RegisterScreenshotOf(850077, "Skyrim.esm")
  RegisterScreenshotOf(78738, "Skyrim.esm")
  RegisterScreenshotOf(468579, "Skyrim.esm")
  RegisterScreenshotOf(78968, "Skyrim.esm")
  RegisterScreenshotOf(117624, "Skyrim.esm")
  RegisterScreenshotOf(79450, "Skyrim.esm")
  RegisterScreenshotOf(81982, "Skyrim.esm")
  RegisterScreenshotOf(78460, "Skyrim.esm")
  RegisterScreenshotOf(555918, "Skyrim.esm")
  RegisterScreenshotOf(78674, "Skyrim.esm")
  RegisterScreenshotOf(78701, "Skyrim.esm")
  RegisterScreenshotOf(555922, "Skyrim.esm")
  RegisterScreenshotOf(146066, "Skyrim.esm")
  RegisterScreenshotOf(364471, "Skyrim.esm")
  RegisterScreenshotOf(878394, "Skyrim.esm")
  RegisterScreenshotOf(718116, "Skyrim.esm")
  RegisterScreenshotOf(78967, "Skyrim.esm")
  RegisterScreenshotOf(962484, "Skyrim.esm")
  RegisterScreenshotOf(618056, "Skyrim.esm")
  RegisterScreenshotOf(218314, "Skyrim.esm")
  RegisterScreenshotOf(117251, "Skyrim.esm")
  RegisterScreenshotOf(841278, "Skyrim.esm")
  RegisterScreenshotOf(1113109, "Skyrim.esm")
  RegisterScreenshotOf(146067, "Skyrim.esm")
  RegisterScreenshotOf(614270, "Skyrim.esm")
  RegisterScreenshotOf(147671, "Skyrim.esm")
  RegisterScreenshotOf(243015, "Skyrim.esm")
  RegisterScreenshotOf(271487, "Skyrim.esm")
  RegisterScreenshotOf(271486, "Skyrim.esm")
  RegisterScreenshotOf(281691, "Skyrim.esm")
  RegisterScreenshotOf(243019, "Skyrim.esm")
  RegisterScreenshotOf(271483, "Skyrim.esm")
  RegisterScreenshotOf(243018, "Skyrim.esm")
  RegisterScreenshotOf(271485, "Skyrim.esm")
  RegisterScreenshotOf(703138, "Skyrim.esm")
  RegisterScreenshotOf(703137, "Skyrim.esm")
  RegisterScreenshotOf(703136, "Skyrim.esm")
  RegisterScreenshotOf(703132, "Skyrim.esm")
  RegisterScreenshotOf(243017, "Skyrim.esm")
  RegisterScreenshotOf(271484, "Skyrim.esm")
  RegisterScreenshotOf(78675, "Skyrim.esm")
  RegisterScreenshotOf(79455, "Skyrim.esm")
  RegisterScreenshotOf(947913, "Skyrim.esm")
  RegisterScreenshotOf(127914, "Skyrim.esm")
  RegisterScreenshotOf(93956, "Skyrim.esm")
  RegisterScreenshotOf(93942, "Skyrim.esm")
  RegisterScreenshotOf(93936, "Skyrim.esm")
  RegisterScreenshotOf(154909, "Skyrim.esm")
  RegisterScreenshotOf(154908, "Skyrim.esm")
  RegisterScreenshotOf(146069, "Skyrim.esm")
  RegisterScreenshotOf(94195, "Skyrim.esm")
  RegisterScreenshotOf(94178, "Skyrim.esm")
  RegisterScreenshotOf(94058, "Skyrim.esm")
  RegisterScreenshotOf(94057, "Skyrim.esm")
  RegisterScreenshotOf(94022, "Skyrim.esm")
  RegisterScreenshotOf(94016, "Skyrim.esm")
  RegisterScreenshotOf(1105390, "Skyrim.esm")
  RegisterScreenshotOf(94199, "Skyrim.esm")
  RegisterScreenshotOf(94198, "Skyrim.esm")
  RegisterScreenshotOf(94196, "Skyrim.esm")
  RegisterScreenshotOf(98007, "Skyrim.esm")
  RegisterScreenshotOf(94202, "Skyrim.esm")
  RegisterScreenshotOf(94201, "Skyrim.esm")
  RegisterScreenshotOf(94200, "Skyrim.esm")
  RegisterScreenshotOf(313169, "Skyrim.esm")
  RegisterScreenshotOf(313140, "Skyrim.esm")
  RegisterScreenshotOf(115096, "Skyrim.esm")
  RegisterScreenshotOf(78676, "Skyrim.esm")
  RegisterScreenshotOf(111055, "Skyrim.esm")
  RegisterScreenshotOf(159216, "Skyrim.esm")
  RegisterScreenshotOf(117550, "Skyrim.esm")
  RegisterScreenshotOf(878353, "Skyrim.esm")
  RegisterScreenshotOf(78739, "Skyrim.esm")
  RegisterScreenshotOf(817344, "Skyrim.esm")
  RegisterScreenshotOf(544021, "Skyrim.esm")
  RegisterScreenshotOf(110713, "Skyrim.esm")
  RegisterScreenshotOf(1112505, "Skyrim.esm")
  RegisterScreenshotOf(801977, "Skyrim.esm")
  RegisterScreenshotOf(1107795, "Skyrim.esm")
  RegisterScreenshotOf(146070, "Skyrim.esm")
  RegisterScreenshotOf(1109129, "Skyrim.esm")
  RegisterScreenshotOf(978213, "Skyrim.esm")
  RegisterScreenshotOf(796461, "Skyrim.esm")
  RegisterScreenshotOf(146071, "Skyrim.esm")
  RegisterScreenshotOf(1109134, "Skyrim.esm")
  RegisterScreenshotOf(146072, "Skyrim.esm")
  RegisterScreenshotOf(1109127, "Skyrim.esm")
  RegisterScreenshotOf(1109126, "Skyrim.esm")
  RegisterScreenshotOf(78496, "Skyrim.esm")
  RegisterScreenshotOf(517611, "Skyrim.esm")
  RegisterScreenshotOf(517610, "Skyrim.esm")
  RegisterScreenshotOf(355069, "Skyrim.esm")
  RegisterScreenshotOf(829137, "Skyrim.esm")
  RegisterScreenshotOf(78678, "Skyrim.esm")
  RegisterScreenshotOf(554927, "Skyrim.esm")
  RegisterScreenshotOf(125271, "Skyrim.esm")
  RegisterScreenshotOf(731511, "Skyrim.esm")
  RegisterScreenshotOf(181964, "Skyrim.esm")
  RegisterScreenshotOf(115077, "Skyrim.esm")
  RegisterScreenshotOf(851994, "Skyrim.esm")
  RegisterScreenshotOf(82218, "Skyrim.esm")
  RegisterScreenshotOf(1016091, "Skyrim.esm")
  RegisterScreenshotOf(1016090, "Skyrim.esm")
  RegisterScreenshotOf(921558, "Skyrim.esm")
  RegisterScreenshotOf(285888, "Skyrim.esm")
  RegisterScreenshotOf(78441, "Skyrim.esm")
  RegisterScreenshotOf(78679, "Skyrim.esm")
  RegisterScreenshotOf(78442, "Skyrim.esm")
  RegisterScreenshotOf(146065, "Skyrim.esm")
  RegisterScreenshotOf(80798, "Skyrim.esm")
  RegisterScreenshotOf(78740, "Skyrim.esm")
  RegisterScreenshotOf(755595, "Skyrim.esm")
  RegisterScreenshotOf(218379, "Skyrim.esm")
  RegisterScreenshotOf(119994, "Skyrim.esm")
  RegisterScreenshotOf(119993, "Skyrim.esm")
  RegisterScreenshotOf(78447, "Skyrim.esm")
  RegisterScreenshotOf(78741, "Skyrim.esm")
  RegisterScreenshotOf(241892, "Skyrim.esm")
  RegisterScreenshotOf(80748, "Skyrim.esm")
  RegisterScreenshotOf(111541, "Skyrim.esm")
  RegisterScreenshotOf(78742, "Skyrim.esm")
  RegisterScreenshotOf(79372, "Skyrim.esm")
  RegisterScreenshotOf(115100, "Skyrim.esm")
  RegisterScreenshotOf(1012613, "Skyrim.esm")
  RegisterScreenshotOf(1012604, "Skyrim.esm")
  RegisterScreenshotOf(1001766, "Skyrim.esm")
  RegisterScreenshotOf(104719, "Skyrim.esm")
  RegisterScreenshotOf(80797, "Skyrim.esm")
  RegisterScreenshotOf(148093, "Skyrim.esm")
  RegisterScreenshotOf(78449, "Skyrim.esm")
  RegisterScreenshotOf(175044, "Skyrim.esm")
  RegisterScreenshotOf(217255, "Skyrim.esm")
  RegisterScreenshotOf(415319, "Skyrim.esm")
  RegisterScreenshotOf(78450, "Skyrim.esm")
  RegisterScreenshotOf(718114, "Skyrim.esm")
  RegisterScreenshotOf(78763, "Skyrim.esm")
  RegisterScreenshotOf(604248, "Skyrim.esm")
  RegisterScreenshotOf(960287, "Skyrim.esm")
  RegisterScreenshotOf(78680, "Skyrim.esm")
  RegisterScreenshotOf(785220, "Skyrim.esm")
  RegisterScreenshotOf(464691, "Skyrim.esm")
  RegisterScreenshotOf(216471, "Skyrim.esm")
  RegisterScreenshotOf(238035, "Skyrim.esm")
  RegisterScreenshotOf(78451, "Skyrim.esm")
  RegisterScreenshotOf(80759, "Skyrim.esm")
  RegisterScreenshotOf(78976, "Skyrim.esm")
  RegisterScreenshotOf(105000, "Skyrim.esm")
  RegisterScreenshotOf(755129, "Skyrim.esm")
  RegisterScreenshotOf(78743, "Skyrim.esm")
  RegisterScreenshotOf(79337, "Skyrim.esm")
  RegisterScreenshotOf(78452, "Skyrim.esm")
  RegisterScreenshotOf(1063266, "Skyrim.esm")
  RegisterScreenshotOf(1052795, "Skyrim.esm")
  RegisterScreenshotOf(243020, "Skyrim.esm")
  RegisterScreenshotOf(170368, "Skyrim.esm")
  RegisterScreenshotOf(243022, "Skyrim.esm")
  RegisterScreenshotOf(732469, "Skyrim.esm")
  RegisterScreenshotOf(243023, "Skyrim.esm")
  RegisterScreenshotOf(243021, "Skyrim.esm")
  RegisterScreenshotOf(409781, "Skyrim.esm")
  RegisterScreenshotOf(115095, "Skyrim.esm")
  RegisterScreenshotOf(80827, "Skyrim.esm")
  RegisterScreenshotOf(108178, "Skyrim.esm")
  RegisterScreenshotOf(1007751, "Skyrim.esm")
  RegisterScreenshotOf(1075809, "Skyrim.esm")
  RegisterScreenshotOf(1062118, "Skyrim.esm")
  RegisterScreenshotOf(1062116, "Skyrim.esm")
  RegisterScreenshotOf(776030, "Skyrim.esm")
  RegisterScreenshotOf(776025, "Skyrim.esm")
  RegisterScreenshotOf(82225, "Skyrim.esm")
  RegisterScreenshotOf(79551, "Skyrim.esm")
  RegisterScreenshotOf(842240, "Skyrim.esm")
  RegisterScreenshotOf(599033, "Skyrim.esm")
  RegisterScreenshotOf(279095, "Skyrim.esm")
  RegisterScreenshotOf(616414, "Skyrim.esm")
  RegisterScreenshotOf(230023, "Skyrim.esm")
  RegisterScreenshotOf(920943, "Skyrim.esm")
  RegisterScreenshotOf(114098, "Skyrim.esm")
  RegisterScreenshotOf(857821, "Skyrim.esm")
  RegisterScreenshotOf(78453, "Skyrim.esm")
  RegisterScreenshotOf(79555, "Skyrim.esm")
  RegisterScreenshotOf(921545, "Skyrim.esm")
  RegisterScreenshotOf(285856, "Skyrim.esm")
  RegisterScreenshotOf(921540, "Skyrim.esm")
  RegisterScreenshotOf(285818, "Skyrim.esm")
  RegisterScreenshotOf(1016508, "Skyrim.esm")
  RegisterScreenshotOf(554987, "Skyrim.esm")
  RegisterScreenshotOf(921550, "Skyrim.esm")
  RegisterScreenshotOf(285883, "Skyrim.esm")
  RegisterScreenshotOf(620283, "Skyrim.esm")
  RegisterScreenshotOf(941879, "Skyrim.esm")
  RegisterScreenshotOf(620918, "Skyrim.esm")
  RegisterScreenshotOf(664107, "Skyrim.esm")
  RegisterScreenshotOf(251685, "Skyrim.esm")
  RegisterScreenshotOf(124972, "Skyrim.esm")
  RegisterScreenshotOf(1018641, "Skyrim.esm")
  RegisterScreenshotOf(146086, "Skyrim.esm")
  RegisterScreenshotOf(132288, "Skyrim.esm")
  RegisterScreenshotOf(843468, "Skyrim.esm")
  RegisterScreenshotOf(635566, "Skyrim.esm")
  RegisterScreenshotOf(518269, "Skyrim.esm")
  RegisterScreenshotOf(642600, "Skyrim.esm")
  RegisterScreenshotOf(277468, "Skyrim.esm")
  RegisterScreenshotOf(279315, "Skyrim.esm")
  RegisterScreenshotOf(279314, "Skyrim.esm")
  RegisterScreenshotOf(279313, "Skyrim.esm")
  RegisterScreenshotOf(279312, "Skyrim.esm")
  RegisterScreenshotOf(279311, "Skyrim.esm")
  RegisterScreenshotOf(279310, "Skyrim.esm")
  RegisterScreenshotOf(279309, "Skyrim.esm")
  RegisterScreenshotOf(279308, "Skyrim.esm")
  RegisterScreenshotOf(279307, "Skyrim.esm")
  RegisterScreenshotOf(279306, "Skyrim.esm")
  RegisterScreenshotOf(277488, "Skyrim.esm")
  RegisterScreenshotOf(277487, "Skyrim.esm")
  RegisterScreenshotOf(277486, "Skyrim.esm")
  RegisterScreenshotOf(279140, "Skyrim.esm")
  RegisterScreenshotOf(279139, "Skyrim.esm")
  RegisterScreenshotOf(279138, "Skyrim.esm")
  RegisterScreenshotOf(279158, "Skyrim.esm")
  RegisterScreenshotOf(279157, "Skyrim.esm")
  RegisterScreenshotOf(279156, "Skyrim.esm")
  RegisterScreenshotOf(279176, "Skyrim.esm")
  RegisterScreenshotOf(279175, "Skyrim.esm")
  RegisterScreenshotOf(279174, "Skyrim.esm")
  RegisterScreenshotOf(277482, "Skyrim.esm")
  RegisterScreenshotOf(279194, "Skyrim.esm")
  RegisterScreenshotOf(279193, "Skyrim.esm")
  RegisterScreenshotOf(279192, "Skyrim.esm")
  RegisterScreenshotOf(959273, "Skyrim.esm")
  RegisterScreenshotOf(334667, "Skyrim.esm")
  RegisterScreenshotOf(632644, "Skyrim.esm")
  RegisterScreenshotOf(534963, "Skyrim.esm")
  RegisterScreenshotOf(78744, "Skyrim.esm")
  RegisterScreenshotOf(80796, "Skyrim.esm")
  RegisterScreenshotOf(78681, "Skyrim.esm")
  RegisterScreenshotOf(78455, "Skyrim.esm")
  RegisterScreenshotOf(79380, "Skyrim.esm")
  RegisterScreenshotOf(78456, "Skyrim.esm")
  RegisterScreenshotOf(728319, "Skyrim.esm")
  RegisterScreenshotOf(78974, "Skyrim.esm")
  RegisterScreenshotOf(256173, "Skyrim.esm")
  RegisterScreenshotOf(99830, "Skyrim.esm")
  RegisterScreenshotOf(78682, "Skyrim.esm")
  RegisterScreenshotOf(542035, "Skyrim.esm")
  RegisterScreenshotOf(622110, "Skyrim.esm")
  RegisterScreenshotOf(1109571, "Skyrim.esm")
  RegisterScreenshotOf(146087, "Skyrim.esm")
  RegisterScreenshotOf(132289, "Skyrim.esm")
  RegisterScreenshotOf(217539, "Skyrim.esm")
  RegisterScreenshotOf(1016506, "Skyrim.esm")
  RegisterScreenshotOf(843469, "Skyrim.esm")
  RegisterScreenshotOf(635563, "Skyrim.esm")
  RegisterScreenshotOf(518270, "Skyrim.esm")
  RegisterScreenshotOf(965678, "Skyrim.esm")
  RegisterScreenshotOf(146107, "Skyrim.esm")
  RegisterScreenshotOf(270399, "Skyrim.esm")
  RegisterScreenshotOf(270260, "Skyrim.esm")
  RegisterScreenshotOf(146092, "Skyrim.esm")
  RegisterScreenshotOf(146090, "Skyrim.esm")
  RegisterScreenshotOf(82764, "Skyrim.esm")
  RegisterScreenshotOf(79381, "Skyrim.esm")
  RegisterScreenshotOf(401752, "Skyrim.esm")
  RegisterScreenshotOf(894602, "Skyrim.esm")
  RegisterScreenshotOf(189416, "Skyrim.esm")
  RegisterScreenshotOf(195354, "Skyrim.esm")
  RegisterScreenshotOf(114104, "Skyrim.esm")
  RegisterScreenshotOf(110746, "Skyrim.esm")
  RegisterScreenshotOf(191320, "Skyrim.esm")
  RegisterScreenshotOf(278608, "Skyrim.esm")
  RegisterScreenshotOf(853360, "Skyrim.esm")
  RegisterScreenshotOf(82216, "Skyrim.esm")
  RegisterScreenshotOf(885235, "Skyrim.esm")
  RegisterScreenshotOf(79453, "Skyrim.esm")
  RegisterScreenshotOf(106012, "Skyrim.esm")
  RegisterScreenshotOf(721827, "Skyrim.esm")
  RegisterScreenshotOf(878339, "Skyrim.esm")
  RegisterScreenshotOf(992184, "Skyrim.esm")
  RegisterScreenshotOf(104887, "Skyrim.esm")
  RegisterScreenshotOf(973627, "Skyrim.esm")
  RegisterScreenshotOf(970458, "Skyrim.esm")
  RegisterScreenshotOf(216248, "Skyrim.esm")
  RegisterScreenshotOf(78461, "Skyrim.esm")
  RegisterScreenshotOf(803849, "Skyrim.esm")
  RegisterScreenshotOf(235582, "Skyrim.esm")
  RegisterScreenshotOf(81984, "Skyrim.esm")
  RegisterScreenshotOf(853367, "Skyrim.esm")
  RegisterScreenshotOf(78462, "Skyrim.esm")
  RegisterScreenshotOf(795774, "Skyrim.esm")
  RegisterScreenshotOf(78972, "Skyrim.esm")
  RegisterScreenshotOf(79363, "Skyrim.esm")
  RegisterScreenshotOf(817346, "Skyrim.esm")
  RegisterScreenshotOf(817356, "Skyrim.esm")
  RegisterScreenshotOf(80764, "Skyrim.esm")
  RegisterScreenshotOf(80769, "Skyrim.esm")
  RegisterScreenshotOf(78746, "Skyrim.esm")
  RegisterScreenshotOf(1067873, "Skyrim.esm")
  RegisterScreenshotOf(1067872, "Skyrim.esm")
  RegisterScreenshotOf(1067871, "Skyrim.esm")
  RegisterScreenshotOf(1067870, "Skyrim.esm")
  RegisterScreenshotOf(1067869, "Skyrim.esm")
  RegisterScreenshotOf(1067868, "Skyrim.esm")
  RegisterScreenshotOf(1067867, "Skyrim.esm")
  RegisterScreenshotOf(889767, "Skyrim.esm")
  RegisterScreenshotOf(889766, "Skyrim.esm")
  RegisterScreenshotOf(889765, "Skyrim.esm")
  RegisterScreenshotOf(889764, "Skyrim.esm")
  RegisterScreenshotOf(889763, "Skyrim.esm")
  RegisterScreenshotOf(889762, "Skyrim.esm")
  RegisterScreenshotOf(793079, "Skyrim.esm")
  RegisterScreenshotOf(728987, "Skyrim.esm")
  RegisterScreenshotOf(728986, "Skyrim.esm")
  RegisterScreenshotOf(728985, "Skyrim.esm")
  RegisterScreenshotOf(728984, "Skyrim.esm")
  RegisterScreenshotOf(728983, "Skyrim.esm")
  RegisterScreenshotOf(728982, "Skyrim.esm")
  RegisterScreenshotOf(725374, "Skyrim.esm")
  RegisterScreenshotOf(468470, "Skyrim.esm")
  RegisterScreenshotOf(333301, "Skyrim.esm")
  RegisterScreenshotOf(466539, "Skyrim.esm")
  RegisterScreenshotOf(426402, "Skyrim.esm")
  RegisterScreenshotOf(79481, "Skyrim.esm")
  RegisterScreenshotOf(1089634, "Skyrim.esm")
  RegisterScreenshotOf(310467, "Skyrim.esm")
  RegisterScreenshotOf(825297, "Skyrim.esm")
  RegisterScreenshotOf(146094, "Skyrim.esm")
  RegisterScreenshotOf(146093, "Skyrim.esm")
  RegisterScreenshotOf(146091, "Skyrim.esm")
  RegisterScreenshotOf(79482, "Skyrim.esm")
  RegisterScreenshotOf(78465, "Skyrim.esm")
  RegisterScreenshotOf(755594, "Skyrim.esm")
  RegisterScreenshotOf(78466, "Skyrim.esm")
  RegisterScreenshotOf(237347, "Skyrim.esm")
  RegisterScreenshotOf(554714, "Skyrim.esm")
  RegisterScreenshotOf(336489, "Skyrim.esm")
  RegisterScreenshotOf(117548, "Skyrim.esm")
  RegisterScreenshotOf(1073769, "Skyrim.esm")
  RegisterScreenshotOf(668938, "Skyrim.esm")
  RegisterScreenshotOf(167382, "Skyrim.esm")
  RegisterScreenshotOf(860270, "Skyrim.esm")
  RegisterScreenshotOf(346238, "Skyrim.esm")
  RegisterScreenshotOf(275868, "Skyrim.esm")
  RegisterScreenshotOf(191458, "Skyrim.esm")
  RegisterScreenshotOf(106472, "Skyrim.esm")
  RegisterScreenshotOf(542043, "Skyrim.esm")
  RegisterScreenshotOf(79338, "Skyrim.esm")
  RegisterScreenshotOf(842231, "Skyrim.esm")
  RegisterScreenshotOf(599034, "Skyrim.esm")
  RegisterScreenshotOf(279094, "Skyrim.esm")
  RegisterScreenshotOf(105473, "Skyrim.esm")
  RegisterScreenshotOf(79557, "Skyrim.esm")
  RegisterScreenshotOf(78686, "Skyrim.esm")
  RegisterScreenshotOf(78467, "Skyrim.esm")
  RegisterScreenshotOf(788539, "Skyrim.esm")
  RegisterScreenshotOf(555920, "Skyrim.esm")
  RegisterScreenshotOf(555931, "Skyrim.esm")
  RegisterScreenshotOf(82227, "Skyrim.esm")
  RegisterScreenshotOf(78747, "Skyrim.esm")
  RegisterScreenshotOf(79558, "Skyrim.esm")
  RegisterScreenshotOf(127931, "Skyrim.esm")
  RegisterScreenshotOf(105472, "Skyrim.esm")
  RegisterScreenshotOf(111053, "Skyrim.esm")
  RegisterScreenshotOf(113441, "Skyrim.esm")
  RegisterScreenshotOf(225886, "Skyrim.esm")
  RegisterScreenshotOf(225841, "Skyrim.esm")
  RegisterScreenshotOf(949938, "Skyrim.esm")
  RegisterScreenshotOf(817354, "Skyrim.esm")
  RegisterScreenshotOf(106016, "Skyrim.esm")
  RegisterScreenshotOf(78468, "Skyrim.esm")
  RegisterScreenshotOf(714619, "Skyrim.esm")
  RegisterScreenshotOf(635053, "Skyrim.esm")
  RegisterScreenshotOf(79427, "Skyrim.esm")
  RegisterScreenshotOf(78469, "Skyrim.esm")
  RegisterScreenshotOf(182576, "Skyrim.esm")
  RegisterScreenshotOf(415956, "Skyrim.esm")
  RegisterScreenshotOf(1074030, "Skyrim.esm")
  RegisterScreenshotOf(79399, "Skyrim.esm")
  RegisterScreenshotOf(180127, "Skyrim.esm")
  RegisterScreenshotOf(78687, "Skyrim.esm")
  RegisterScreenshotOf(78688, "Skyrim.esm")
  RegisterScreenshotOf(755589, "Skyrim.esm")
  RegisterScreenshotOf(479109, "Skyrim.esm")
  RegisterScreenshotOf(479108, "Skyrim.esm")
  RegisterScreenshotOf(479107, "Skyrim.esm")
  RegisterScreenshotOf(146096, "Skyrim.esm")
  RegisterScreenshotOf(842241, "Skyrim.esm")
  RegisterScreenshotOf(599035, "Skyrim.esm")
  RegisterScreenshotOf(279096, "Skyrim.esm")
  RegisterScreenshotOf(121860, "Skyrim.esm")
  RegisterScreenshotOf(1012192, "Skyrim.esm")
  RegisterScreenshotOf(124773, "Skyrim.esm")
  RegisterScreenshotOf(1089612, "Skyrim.esm")
  RegisterScreenshotOf(787100, "Skyrim.esm")
  RegisterScreenshotOf(79426, "Skyrim.esm")
  RegisterScreenshotOf(115076, "Skyrim.esm")
  RegisterScreenshotOf(78689, "Skyrim.esm")
  RegisterScreenshotOf(78748, "Skyrim.esm")
  RegisterScreenshotOf(1094402, "Skyrim.esm")
  RegisterScreenshotOf(785248, "Skyrim.esm")
  RegisterScreenshotOf(785219, "Skyrim.esm")
  RegisterScreenshotOf(698326, "Skyrim.esm")
  RegisterScreenshotOf(568726, "Skyrim.esm")
  RegisterScreenshotOf(606222, "Skyrim.esm")
  RegisterScreenshotOf(80812, "Skyrim.esm")
  RegisterScreenshotOf(78470, "Skyrim.esm")
  RegisterScreenshotOf(160933, "Skyrim.esm")
  RegisterScreenshotOf(82212, "Skyrim.esm")
  RegisterScreenshotOf(79447, "Skyrim.esm")
  RegisterScreenshotOf(78690, "Skyrim.esm")
  RegisterScreenshotOf(165113, "Skyrim.esm")
  RegisterScreenshotOf(843913, "Skyrim.esm")
  RegisterScreenshotOf(1021514, "Skyrim.esm")
  RegisterScreenshotOf(171438, "Skyrim.esm")
  RegisterScreenshotOf(82221, "Skyrim.esm")
  RegisterScreenshotOf(79483, "Skyrim.esm")
  RegisterScreenshotOf(1086161, "Skyrim.esm")
  RegisterScreenshotOf(1082418, "Skyrim.esm")
  RegisterScreenshotOf(1082417, "Skyrim.esm")
  RegisterScreenshotOf(1082416, "Skyrim.esm")
  RegisterScreenshotOf(1082401, "Skyrim.esm")
  RegisterScreenshotOf(960288, "Skyrim.esm")
  RegisterScreenshotOf(618491, "Skyrim.esm")
  RegisterScreenshotOf(79484, "Skyrim.esm")
  RegisterScreenshotOf(317159, "Skyrim.esm")
  RegisterScreenshotOf(614357, "Skyrim.esm")
  RegisterScreenshotOf(1073431, "Skyrim.esm")
  RegisterScreenshotOf(1073430, "Skyrim.esm")
  RegisterScreenshotOf(1062130, "Skyrim.esm")
  RegisterScreenshotOf(284673, "Skyrim.esm")
  RegisterScreenshotOf(284665, "Skyrim.esm")
  RegisterScreenshotOf(959864, "Skyrim.esm")
  RegisterScreenshotOf(218419, "Skyrim.esm")
  RegisterScreenshotOf(82207, "Skyrim.esm")
  RegisterScreenshotOf(113558, "Skyrim.esm")
  RegisterScreenshotOf(882748, "Skyrim.esm")
  RegisterScreenshotOf(882747, "Skyrim.esm")
  RegisterScreenshotOf(219998, "Skyrim.esm")
  RegisterScreenshotOf(182299, "Skyrim.esm")
  RegisterScreenshotOf(542045, "Skyrim.esm")
  RegisterScreenshotOf(78471, "Skyrim.esm")
  RegisterScreenshotOf(78973, "Skyrim.esm")
  RegisterScreenshotOf(843933, "Skyrim.esm")
  RegisterScreenshotOf(78673, "Skyrim.esm")
  RegisterScreenshotOf(165036, "Skyrim.esm")
  RegisterScreenshotOf(251684, "Skyrim.esm")
  RegisterScreenshotOf(251682, "Skyrim.esm")
  RegisterScreenshotOf(104989, "Skyrim.esm")
  RegisterScreenshotOf(108217, "Skyrim.esm")
  RegisterScreenshotOf(980487, "Skyrim.esm")
  RegisterScreenshotOf(146097, "Skyrim.esm")
  RegisterScreenshotOf(78472, "Skyrim.esm")
  RegisterScreenshotOf(1112061, "Skyrim.esm")
  RegisterScreenshotOf(542597, "Skyrim.esm")
  RegisterScreenshotOf(469512, "Skyrim.esm")
  RegisterScreenshotOf(429422, "Skyrim.esm")
  RegisterScreenshotOf(429421, "Skyrim.esm")
  RegisterScreenshotOf(429419, "Skyrim.esm")
  RegisterScreenshotOf(429403, "Skyrim.esm")
  RegisterScreenshotOf(429319, "Skyrim.esm")
  RegisterScreenshotOf(429316, "Skyrim.esm")
  RegisterScreenshotOf(429315, "Skyrim.esm")
  RegisterScreenshotOf(429314, "Skyrim.esm")
  RegisterScreenshotOf(429306, "Skyrim.esm")
  RegisterScreenshotOf(146098, "Skyrim.esm")
  RegisterScreenshotOf(79464, "Skyrim.esm")
  RegisterScreenshotOf(78749, "Skyrim.esm")
  RegisterScreenshotOf(78691, "Skyrim.esm")
  RegisterScreenshotOf(79344, "Skyrim.esm")
  RegisterScreenshotOf(78750, "Skyrim.esm")
  RegisterScreenshotOf(1016994, "Skyrim.esm")
  RegisterScreenshotOf(80828, "Skyrim.esm")
  RegisterScreenshotOf(82243, "Skyrim.esm")
  RegisterScreenshotOf(80803, "Skyrim.esm")
  RegisterScreenshotOf(960285, "Skyrim.esm")
  RegisterScreenshotOf(475070, "Skyrim.esm")
  RegisterScreenshotOf(401804, "Skyrim.esm")
  RegisterScreenshotOf(196587, "Skyrim.esm")
  RegisterScreenshotOf(611767, "Skyrim.esm")
  RegisterScreenshotOf(921546, "Skyrim.esm")
  RegisterScreenshotOf(285857, "Skyrim.esm")
  RegisterScreenshotOf(921541, "Skyrim.esm")
  RegisterScreenshotOf(285819, "Skyrim.esm")
  RegisterScreenshotOf(921551, "Skyrim.esm")
  RegisterScreenshotOf(285884, "Skyrim.esm")
  RegisterScreenshotOf(146111, "Skyrim.esm")
  RegisterScreenshotOf(146099, "Skyrim.esm")
  RegisterScreenshotOf(79458, "Skyrim.esm")
  RegisterScreenshotOf(82203, "Skyrim.esm")
  RegisterScreenshotOf(79339, "Skyrim.esm")
  RegisterScreenshotOf(79340, "Skyrim.esm")
  RegisterScreenshotOf(80818, "Skyrim.esm")
  RegisterScreenshotOf(78751, "Skyrim.esm")
  RegisterScreenshotOf(872518, "Skyrim.esm")
  RegisterScreenshotOf(78473, "Skyrim.esm")
  RegisterScreenshotOf(298031, "Skyrim.esm")
  RegisterScreenshotOf(78753, "Skyrim.esm")
  RegisterScreenshotOf(1062145, "Skyrim.esm")
  RegisterScreenshotOf(1062144, "Skyrim.esm")
  RegisterScreenshotOf(284674, "Skyrim.esm")
  RegisterScreenshotOf(284664, "Skyrim.esm")
  RegisterScreenshotOf(285664, "Skyrim.esm")
  RegisterScreenshotOf(700332, "Skyrim.esm")
  RegisterScreenshotOf(244934, "Skyrim.esm")
  RegisterScreenshotOf(132553, "Skyrim.esm")
  RegisterScreenshotOf(350688, "Skyrim.esm")
  RegisterScreenshotOf(284755, "Skyrim.esm")
  RegisterScreenshotOf(173015, "Skyrim.esm")
  RegisterScreenshotOf(135743, "Skyrim.esm")
  RegisterScreenshotOf(284796, "Skyrim.esm")
  RegisterScreenshotOf(999031, "Skyrim.esm")
  RegisterScreenshotOf(999030, "Skyrim.esm")
  RegisterScreenshotOf(110148, "Skyrim.esm")
  RegisterScreenshotOf(92531, "Skyrim.esm")
  RegisterScreenshotOf(1089963, "Skyrim.esm")
  RegisterScreenshotOf(1089962, "Skyrim.esm")
  RegisterScreenshotOf(1089954, "Skyrim.esm")
  RegisterScreenshotOf(1089953, "Skyrim.esm")
  RegisterScreenshotOf(1089952, "Skyrim.esm")
  RegisterScreenshotOf(1089951, "Skyrim.esm")
  RegisterScreenshotOf(1072866, "Skyrim.esm")
  RegisterScreenshotOf(1041680, "Skyrim.esm")
  RegisterScreenshotOf(1021109, "Skyrim.esm")
  RegisterScreenshotOf(1021102, "Skyrim.esm")
  RegisterScreenshotOf(1021097, "Skyrim.esm")
  RegisterScreenshotOf(999023, "Skyrim.esm")
  RegisterScreenshotOf(999022, "Skyrim.esm")
  RegisterScreenshotOf(999021, "Skyrim.esm")
  RegisterScreenshotOf(948221, "Skyrim.esm")
  RegisterScreenshotOf(948217, "Skyrim.esm")
  RegisterScreenshotOf(946875, "Skyrim.esm")
  RegisterScreenshotOf(945500, "Skyrim.esm")
  RegisterScreenshotOf(936224, "Skyrim.esm")
  RegisterScreenshotOf(936219, "Skyrim.esm")
  RegisterScreenshotOf(925333, "Skyrim.esm")
  RegisterScreenshotOf(884110, "Skyrim.esm")
  RegisterScreenshotOf(884093, "Skyrim.esm")
  RegisterScreenshotOf(878520, "Skyrim.esm")
  RegisterScreenshotOf(698643, "Skyrim.esm")
  RegisterScreenshotOf(698625, "Skyrim.esm")
  RegisterScreenshotOf(698621, "Skyrim.esm")
  RegisterScreenshotOf(698620, "Skyrim.esm")
  RegisterScreenshotOf(698584, "Skyrim.esm")
  RegisterScreenshotOf(698583, "Skyrim.esm")
  RegisterScreenshotOf(698582, "Skyrim.esm")
  RegisterScreenshotOf(698581, "Skyrim.esm")
  RegisterScreenshotOf(698580, "Skyrim.esm")
  RegisterScreenshotOf(581213, "Skyrim.esm")
  RegisterScreenshotOf(451100, "Skyrim.esm")
  RegisterScreenshotOf(288660, "Skyrim.esm")
  RegisterScreenshotOf(130141, "Skyrim.esm")
  RegisterScreenshotOf(287274, "Skyrim.esm")
  RegisterScreenshotOf(79439, "Skyrim.esm")
  RegisterScreenshotOf(78704, "Skyrim.esm")
  RegisterScreenshotOf(555923, "Skyrim.esm")
  RegisterScreenshotOf(78474, "Skyrim.esm")
  RegisterScreenshotOf(79423, "Skyrim.esm")
  RegisterScreenshotOf(78692, "Skyrim.esm")
  RegisterScreenshotOf(372369, "Skyrim.esm")
  RegisterScreenshotOf(666769, "Skyrim.esm")
  RegisterScreenshotOf(79383, "Skyrim.esm")
  RegisterScreenshotOf(80824, "Skyrim.esm")
  RegisterScreenshotOf(336487, "Skyrim.esm")
  RegisterScreenshotOf(78475, "Skyrim.esm")
  RegisterScreenshotOf(235584, "Skyrim.esm")
  RegisterScreenshotOf(542032, "Skyrim.esm")
  RegisterScreenshotOf(555927, "Skyrim.esm")
  RegisterScreenshotOf(135744, "Skyrim.esm")
  RegisterScreenshotOf(241895, "Skyrim.esm")
  RegisterScreenshotOf(315691, "Skyrim.esm")
  RegisterScreenshotOf(175043, "Skyrim.esm")
  RegisterScreenshotOf(115093, "Skyrim.esm")
  RegisterScreenshotOf(241894, "Skyrim.esm")
  RegisterScreenshotOf(78476, "Skyrim.esm")
  RegisterScreenshotOf(943062, "Skyrim.esm")
  RegisterScreenshotOf(78477, "Skyrim.esm")
  RegisterScreenshotOf(78478, "Skyrim.esm")
  RegisterScreenshotOf(760194, "Skyrim.esm")
  RegisterScreenshotOf(108189, "Skyrim.esm")
  RegisterScreenshotOf(79364, "Skyrim.esm")
  RegisterScreenshotOf(79384, "Skyrim.esm")
  RegisterScreenshotOf(79549, "Skyrim.esm")
  RegisterScreenshotOf(717706, "Skyrim.esm")
  RegisterScreenshotOf(80817, "Skyrim.esm")
  RegisterScreenshotOf(79341, "Skyrim.esm")
  RegisterScreenshotOf(82208, "Skyrim.esm")
  RegisterScreenshotOf(666767, "Skyrim.esm")
  RegisterScreenshotOf(80054, "Skyrim.esm")
  RegisterScreenshotOf(79342, "Skyrim.esm")
  RegisterScreenshotOf(82229, "Skyrim.esm")
  RegisterScreenshotOf(78479, "Skyrim.esm")
  RegisterScreenshotOf(79539, "Skyrim.esm")
  RegisterScreenshotOf(159503, "Skyrim.esm")
  RegisterScreenshotOf(989769, "Skyrim.esm")
  RegisterScreenshotOf(113448, "Skyrim.esm")
  RegisterScreenshotOf(542056, "Skyrim.esm")
  RegisterScreenshotOf(346242, "Skyrim.esm")
  RegisterScreenshotOf(391269, "Skyrim.esm")
  RegisterScreenshotOf(770172, "Skyrim.esm")
  RegisterScreenshotOf(79386, "Skyrim.esm")
  RegisterScreenshotOf(79385, "Skyrim.esm")
  RegisterScreenshotOf(110719, "Skyrim.esm")
  RegisterScreenshotOf(78480, "Skyrim.esm")
  RegisterScreenshotOf(78482, "Skyrim.esm")
  RegisterScreenshotOf(785237, "Skyrim.esm")
  RegisterScreenshotOf(78693, "Skyrim.esm")
  RegisterScreenshotOf(136705, "Skyrim.esm")
  RegisterScreenshotOf(78754, "Skyrim.esm")
  RegisterScreenshotOf(563590, "Skyrim.esm")
  RegisterScreenshotOf(1088127, "Skyrim.esm")
  RegisterScreenshotOf(1070419, "Skyrim.esm")
  RegisterScreenshotOf(1070417, "Skyrim.esm")
  RegisterScreenshotOf(1062121, "Skyrim.esm")
  RegisterScreenshotOf(621993, "Skyrim.esm")
  RegisterScreenshotOf(284675, "Skyrim.esm")
  RegisterScreenshotOf(284666, "Skyrim.esm")
  RegisterScreenshotOf(78481, "Skyrim.esm")
  RegisterScreenshotOf(111058, "Skyrim.esm")
  RegisterScreenshotOf(111065, "Skyrim.esm")
  RegisterScreenshotOf(258590, "Skyrim.esm")
  RegisterScreenshotOf(78483, "Skyrim.esm")
  RegisterScreenshotOf(79459, "Skyrim.esm")
  RegisterScreenshotOf(79457, "Skyrim.esm")
  RegisterScreenshotOf(78755, "Skyrim.esm")
  RegisterScreenshotOf(79554, "Skyrim.esm")
  RegisterScreenshotOf(606208, "Skyrim.esm")
  RegisterScreenshotOf(78484, "Skyrim.esm")
  RegisterScreenshotOf(618510, "Skyrim.esm")
  RegisterScreenshotOf(108174, "Skyrim.esm")
  RegisterScreenshotOf(361219, "Skyrim.esm")
  RegisterScreenshotOf(79373, "Skyrim.esm")
  RegisterScreenshotOf(115080, "Skyrim.esm")
  RegisterScreenshotOf(236471, "Skyrim.esm")
  RegisterScreenshotOf(542038, "Skyrim.esm")
  RegisterScreenshotOf(788558, "Skyrim.esm")
  RegisterScreenshotOf(115072, "Skyrim.esm")
  RegisterScreenshotOf(1050471, "Skyrim.esm")
  RegisterScreenshotOf(79436, "Skyrim.esm")
  RegisterScreenshotOf(866257, "Skyrim.esm")
  RegisterScreenshotOf(160928, "Skyrim.esm")
  RegisterScreenshotOf(78694, "Skyrim.esm")
  RegisterScreenshotOf(79343, "Skyrim.esm")
  RegisterScreenshotOf(900369, "Skyrim.esm")
  RegisterScreenshotOf(80815, "Skyrim.esm")
  RegisterScreenshotOf(80750, "Skyrim.esm")
  RegisterScreenshotOf(541873, "Skyrim.esm")
  RegisterScreenshotOf(542009, "Skyrim.esm")
  RegisterScreenshotOf(541904, "Skyrim.esm")
  RegisterScreenshotOf(542031, "Skyrim.esm")
  RegisterScreenshotOf(542030, "Skyrim.esm")
  RegisterScreenshotOf(541905, "Skyrim.esm")
  RegisterScreenshotOf(853363, "Skyrim.esm")
  RegisterScreenshotOf(78497, "Skyrim.esm")
  RegisterScreenshotOf(542010, "Skyrim.esm")
  RegisterScreenshotOf(542046, "Skyrim.esm")
  RegisterScreenshotOf(541874, "Skyrim.esm")
  RegisterScreenshotOf(79376, "Skyrim.esm")
  RegisterScreenshotOf(79387, "Skyrim.esm")
  RegisterScreenshotOf(79544, "Skyrim.esm")
  RegisterScreenshotOf(228868, "Skyrim.esm")
  RegisterScreenshotOf(80758, "Skyrim.esm")
  RegisterScreenshotOf(125270, "Skyrim.esm")
  RegisterScreenshotOf(804095, "Skyrim.esm")
  RegisterScreenshotOf(80832, "Skyrim.esm")
  RegisterScreenshotOf(513657, "Skyrim.esm")
  RegisterScreenshotOf(662015, "Skyrim.esm")
  RegisterScreenshotOf(662014, "Skyrim.esm")
  RegisterScreenshotOf(78757, "Skyrim.esm")
  RegisterScreenshotOf(78487, "Skyrim.esm")
  RegisterScreenshotOf(653369, "Skyrim.esm")
  RegisterScreenshotOf(106014, "Skyrim.esm")
  RegisterScreenshotOf(79440, "Skyrim.esm")
  RegisterScreenshotOf(874038, "Skyrim.esm")
  RegisterScreenshotOf(104994, "Skyrim.esm")
  RegisterScreenshotOf(78758, "Skyrim.esm")
  RegisterScreenshotOf(288666, "Skyrim.esm")
  RegisterScreenshotOf(79388, "Skyrim.esm")
  RegisterScreenshotOf(82245, "Skyrim.esm")
  RegisterScreenshotOf(78696, "Skyrim.esm")
  RegisterScreenshotOf(379881, "Skyrim.esm")
  RegisterScreenshotOf(144186, "Skyrim.esm")
  RegisterScreenshotOf(294061, "Skyrim.esm")
  RegisterScreenshotOf(78970, "Skyrim.esm")
  RegisterScreenshotOf(175038, "Skyrim.esm")
  RegisterScreenshotOf(970629, "Skyrim.esm")
  RegisterScreenshotOf(947914, "Skyrim.esm")
  RegisterScreenshotOf(109155, "Skyrim.esm")
  RegisterScreenshotOf(666766, "Skyrim.esm")
  RegisterScreenshotOf(79548, "Skyrim.esm")
  RegisterScreenshotOf(611519, "Skyrim.esm")
  RegisterScreenshotOf(111057, "Skyrim.esm")
  RegisterScreenshotOf(111061, "Skyrim.esm")
  RegisterScreenshotOf(111063, "Skyrim.esm")
  RegisterScreenshotOf(843931, "Skyrim.esm")
  RegisterScreenshotOf(78488, "Skyrim.esm")
  RegisterScreenshotOf(78759, "Skyrim.esm")
  RegisterScreenshotOf(79389, "Skyrim.esm")
  RegisterScreenshotOf(110706, "Skyrim.esm")
  RegisterScreenshotOf(762341, "Skyrim.esm")
  RegisterScreenshotOf(1086945, "Skyrim.esm")
  RegisterScreenshotOf(749460, "Skyrim.esm")
  RegisterScreenshotOf(497941, "Skyrim.esm")
  RegisterScreenshotOf(817342, "Skyrim.esm")
  RegisterScreenshotOf(586586, "Skyrim.esm")
  RegisterScreenshotOf(106006, "Skyrim.esm")
  RegisterScreenshotOf(545536, "Skyrim.esm")
  RegisterScreenshotOf(221588, "Skyrim.esm")
  RegisterScreenshotOf(1107794, "Skyrim.esm")
  RegisterScreenshotOf(641894, "Skyrim.esm")
  RegisterScreenshotOf(966190, "Skyrim.esm")
  RegisterScreenshotOf(178830, "Skyrim.esm")
  RegisterScreenshotOf(82254, "Skyrim.esm")
  RegisterScreenshotOf(115074, "Skyrim.esm")
  RegisterScreenshotOf(131142, "Skyrim.esm")
  RegisterScreenshotOf(166611, "Skyrim.esm")
  RegisterScreenshotOf(166610, "Skyrim.esm")
  RegisterScreenshotOf(146100, "Skyrim.esm")
  RegisterScreenshotOf(949935, "Skyrim.esm")
  RegisterScreenshotOf(295260, "Skyrim.esm")
  RegisterScreenshotOf(78683, "Skyrim.esm")
  RegisterScreenshotOf(955947, "Skyrim.esm")
  RegisterScreenshotOf(955944, "Skyrim.esm")
  RegisterScreenshotOf(760192, "Skyrim.esm")
  RegisterScreenshotOf(641192, "Skyrim.esm")
  RegisterScreenshotOf(78697, "Skyrim.esm")
  RegisterScreenshotOf(707018, "Skyrim.esm")
  RegisterScreenshotOf(648319, "Skyrim.esm")
  RegisterScreenshotOf(570137, "Skyrim.esm")
  RegisterScreenshotOf(553274, "Skyrim.esm")
  RegisterScreenshotOf(380735, "Skyrim.esm")
  RegisterScreenshotOf(342002, "Skyrim.esm")
  RegisterScreenshotOf(225029, "Skyrim.esm")
  RegisterScreenshotOf(135374, "Skyrim.esm")
  RegisterScreenshotOf(921555, "Skyrim.esm")
  RegisterScreenshotOf(447027, "Skyrim.esm")
  RegisterScreenshotOf(921557, "Skyrim.esm")
  RegisterScreenshotOf(348591, "Skyrim.esm")
  RegisterScreenshotOf(188856, "Skyrim.esm")
  RegisterScreenshotOf(188849, "Skyrim.esm")
  RegisterScreenshotOf(188714, "Skyrim.esm")
  RegisterScreenshotOf(188568, "Skyrim.esm")
  RegisterScreenshotOf(79438, "Skyrim.esm")
  RegisterScreenshotOf(79424, "Skyrim.esm")
  RegisterScreenshotOf(225750, "Skyrim.esm")
  RegisterScreenshotOf(116229, "Skyrim.esm")
  RegisterScreenshotOf(78698, "Skyrim.esm")
  RegisterScreenshotOf(843906, "Skyrim.esm")
  RegisterScreenshotOf(243122, "Skyrim.esm")
  RegisterScreenshotOf(890345, "Skyrim.esm")
  RegisterScreenshotOf(152234, "Skyrim.esm")
  RegisterScreenshotOf(78489, "Skyrim.esm")
  RegisterScreenshotOf(236350, "Skyrim.esm")
  RegisterScreenshotOf(80749, "Skyrim.esm")
  RegisterScreenshotOf(376637, "Skyrim.esm")
  RegisterScreenshotOf(518968, "Skyrim.esm")
  RegisterScreenshotOf(110716, "Skyrim.esm")
  RegisterScreenshotOf(320735, "Skyrim.esm")
  RegisterScreenshotOf(105006, "Skyrim.esm")
  RegisterScreenshotOf(108144, "Skyrim.esm")
  RegisterScreenshotOf(702207, "Skyrim.esm")
  RegisterScreenshotOf(80813, "Skyrim.esm")
  RegisterScreenshotOf(78491, "Skyrim.esm")
  RegisterScreenshotOf(115104, "Skyrim.esm")
  RegisterScreenshotOf(117253, "Skyrim.esm")
  RegisterScreenshotOf(867295, "Skyrim.esm")
  RegisterScreenshotOf(786726, "Skyrim.esm")
  RegisterScreenshotOf(786725, "Skyrim.esm")
  RegisterScreenshotOf(786724, "Skyrim.esm")
  RegisterScreenshotOf(786710, "Skyrim.esm")
  RegisterScreenshotOf(786709, "Skyrim.esm")
  RegisterScreenshotOf(786708, "Skyrim.esm")
  RegisterScreenshotOf(786707, "Skyrim.esm")
  RegisterScreenshotOf(108207, "Skyrim.esm")
  RegisterScreenshotOf(78699, "Skyrim.esm")
  RegisterScreenshotOf(817375, "Skyrim.esm")
  RegisterScreenshotOf(117555, "Skyrim.esm")
  RegisterScreenshotOf(143126, "Skyrim.esm")
  RegisterScreenshotOf(78700, "Skyrim.esm")
  RegisterScreenshotOf(1001836, "Skyrim.esm")
  RegisterScreenshotOf(1088172, "Skyrim.esm")
  RegisterScreenshotOf(394496, "Skyrim.esm")
  RegisterScreenshotOf(394495, "Skyrim.esm")
  RegisterScreenshotOf(394494, "Skyrim.esm")
  RegisterScreenshotOf(394484, "Skyrim.esm")
  RegisterScreenshotOf(878361, "Skyrim.esm")
  RegisterScreenshotOf(350814, "Skyrim.esm")
  RegisterScreenshotOf(79542, "Skyrim.esm")
  RegisterScreenshotOf(933905, "Skyrim.esm")
  RegisterScreenshotOf(933904, "Skyrim.esm")
  RegisterScreenshotOf(137333, "Skyrim.esm")
  RegisterScreenshotOf(943659, "Skyrim.esm")
  RegisterScreenshotOf(82027, "Skyrim.esm")
  RegisterScreenshotOf(110714, "Skyrim.esm")
  RegisterScreenshotOf(78761, "Skyrim.esm")
  RegisterScreenshotOf(80762, "Skyrim.esm")
  RegisterScreenshotOf(216473, "Skyrim.esm")
  RegisterScreenshotOf(80767, "Skyrim.esm")
  RegisterScreenshotOf(1041457, "Skyrim.esm")
  RegisterScreenshotOf(1016987, "Skyrim.esm")
  RegisterScreenshotOf(78752, "Skyrim.esm")
  RegisterScreenshotOf(79552, "Skyrim.esm")
  RegisterScreenshotOf(272294, "Skyrim.esm")
  RegisterScreenshotOf(79444, "Skyrim.esm")
  RegisterScreenshotOf(80831, "Skyrim.esm")
  RegisterScreenshotOf(318880, "Skyrim.esm")
  RegisterScreenshotOf(115627, "Skyrim.esm")
  RegisterScreenshotOf(921547, "Skyrim.esm")
  RegisterScreenshotOf(348589, "Skyrim.esm")
  RegisterScreenshotOf(165122, "Skyrim.esm")
  RegisterScreenshotOf(921542, "Skyrim.esm")
  RegisterScreenshotOf(348588, "Skyrim.esm")
  RegisterScreenshotOf(82223, "Skyrim.esm")
  RegisterScreenshotOf(124885, "Skyrim.esm")
  RegisterScreenshotOf(82765, "Skyrim.esm")
  RegisterScreenshotOf(79449, "Skyrim.esm")
  RegisterScreenshotOf(78762, "Skyrim.esm")
  RegisterScreenshotOf(675461, "Skyrim.esm")
  RegisterScreenshotOf(144338, "Skyrim.esm")
  RegisterScreenshotOf(555915, "Skyrim.esm")
  RegisterScreenshotOf(266704, "Skyrim.esm")
  RegisterScreenshotOf(244613, "Skyrim.esm")
  RegisterScreenshotOf(920797, "Skyrim.esm")
  RegisterScreenshotOf(913119, "Skyrim.esm")
  RegisterScreenshotOf(113501, "Skyrim.esm")
  RegisterScreenshotOf(960286, "Skyrim.esm")
  RegisterScreenshotOf(82251, "Skyrim.esm")
  RegisterScreenshotOf(82220, "Skyrim.esm")
  RegisterScreenshotOf(78702, "Skyrim.esm")
  RegisterScreenshotOf(637765, "Skyrim.esm")
  RegisterScreenshotOf(182566, "Skyrim.esm")
  RegisterScreenshotOf(82211, "Skyrim.esm")
  RegisterScreenshotOf(118161, "Skyrim.esm")
  RegisterScreenshotOf(115099, "Skyrim.esm")
  RegisterScreenshotOf(78703, "Skyrim.esm")
  RegisterScreenshotOf(108249, "Skyrim.esm")
  RegisterScreenshotOf(1060195, "Skyrim.esm")
  RegisterScreenshotOf(1060194, "Skyrim.esm")
  RegisterScreenshotOf(370991, "Skyrim.esm")
  RegisterScreenshotOf(370989, "Skyrim.esm")
  RegisterScreenshotOf(370992, "Skyrim.esm")
  RegisterScreenshotOf(107215, "Skyrim.esm")
  RegisterScreenshotOf(1062147, "Skyrim.esm")
  RegisterScreenshotOf(1062146, "Skyrim.esm")
  RegisterScreenshotOf(933549, "Skyrim.esm")
  RegisterScreenshotOf(284676, "Skyrim.esm")
  RegisterScreenshotOf(284661, "Skyrim.esm")
  RegisterScreenshotOf(652127, "Skyrim.esm")
  RegisterScreenshotOf(788418, "Skyrim.esm")
  RegisterScreenshotOf(163704, "Skyrim.esm")
  RegisterScreenshotOf(652128, "Skyrim.esm")
  RegisterScreenshotOf(806577, "Skyrim.esm")
  RegisterScreenshotOf(793251, "Skyrim.esm")
  RegisterScreenshotOf(793247, "Skyrim.esm")
  RegisterScreenshotOf(793246, "Skyrim.esm")
  RegisterScreenshotOf(78492, "Skyrim.esm")
  RegisterScreenshotOf(447022, "Skyrim.esm")
  RegisterScreenshotOf(281815, "Skyrim.esm")
  RegisterScreenshotOf(281816, "Skyrim.esm")
  RegisterScreenshotOf(1086197, "Skyrim.esm")
  RegisterScreenshotOf(346366, "Skyrim.esm")
  RegisterScreenshotOf(281817, "Skyrim.esm")
  RegisterScreenshotOf(78706, "Skyrim.esm")
  RegisterScreenshotOf(82248, "Skyrim.esm")
  RegisterScreenshotOf(1045000, "Skyrim.esm")
  RegisterScreenshotOf(78493, "Skyrim.esm")
  RegisterScreenshotOf(284960, "Skyrim.esm")
  RegisterScreenshotOf(78494, "Skyrim.esm")
  RegisterScreenshotOf(79556, "Skyrim.esm")
  RegisterScreenshotOf(78764, "Skyrim.esm")
  RegisterScreenshotOf(82242, "Skyrim.esm")
  RegisterScreenshotOf(80768, "Skyrim.esm")
  RegisterScreenshotOf(78765, "Skyrim.esm")
  RegisterScreenshotOf(106018, "Skyrim.esm")
  RegisterScreenshotOf(989770, "Skyrim.esm")
  RegisterScreenshotOf(80814, "Skyrim.esm")
  RegisterScreenshotOf(401704, "Skyrim.esm")
  RegisterScreenshotOf(104992, "Skyrim.esm")
  RegisterScreenshotOf(80795, "Skyrim.esm")
  RegisterScreenshotOf(80820, "Skyrim.esm")
  RegisterScreenshotOf(104795, "Skyrim.esm")
  RegisterScreenshotOf(78766, "Skyrim.esm")
  RegisterScreenshotOf(78767, "Skyrim.esm")
  RegisterScreenshotOf(115092, "Skyrim.esm")
  RegisterScreenshotOf(1088128, "Skyrim.esm")
  RegisterScreenshotOf(1088126, "Skyrim.esm")
  RegisterScreenshotOf(1070434, "Skyrim.esm")
  RegisterScreenshotOf(1070422, "Skyrim.esm")
  RegisterScreenshotOf(1070421, "Skyrim.esm")
  RegisterScreenshotOf(576930, "Skyrim.esm")
  RegisterScreenshotOf(284678, "Skyrim.esm")
  RegisterScreenshotOf(284669, "Skyrim.esm")
  RegisterScreenshotOf(124859, "Skyrim.esm")
  RegisterScreenshotOf(889927, "Skyrim.esm")
  RegisterScreenshotOf(632132, "Skyrim.esm")
  RegisterScreenshotOf(286584, "Skyrim.esm")
  RegisterScreenshotOf(647516, "Skyrim.esm")
  RegisterScreenshotOf(646606, "Skyrim.esm")
  RegisterScreenshotOf(78969, "Skyrim.esm")
  RegisterScreenshotOf(548164, "Skyrim.esm")
  RegisterScreenshotOf(78768, "Skyrim.esm")
  RegisterScreenshotOf(172936, "Skyrim.esm")
  RegisterScreenshotOf(82235, "Skyrim.esm")
  RegisterScreenshotOf(226874, "Skyrim.esm")
  RegisterScreenshotOf(247164, "Skyrim.esm")
  RegisterScreenshotOf(849822, "Skyrim.esm")
  RegisterScreenshotOf(79365, "Skyrim.esm")
  RegisterScreenshotOf(277794, "Skyrim.esm")
  RegisterScreenshotOf(78495, "Skyrim.esm")
  RegisterScreenshotOf(216250, "Skyrim.esm")
  RegisterScreenshotOf(78769, "Skyrim.esm")
  RegisterScreenshotOf(769234, "Skyrim.esm")
  RegisterScreenshotOf(744794, "Skyrim.esm")
  RegisterScreenshotOf(175210, "Skyrim.esm")
  RegisterScreenshotOf(635527, "Skyrim.esm")
  RegisterScreenshotOf(653357, "Skyrim.esm")
  RegisterScreenshotOf(635565, "Skyrim.esm")
  RegisterScreenshotOf(635564, "Skyrim.esm")
  RegisterScreenshotOf(635561, "Skyrim.esm")
  RegisterScreenshotOf(514444, "Skyrim.esm")
  RegisterScreenshotOf(104812, "Skyrim.esm")
  RegisterScreenshotOf(467728, "Skyrim.esm")
  RegisterScreenshotOf(115097, "Skyrim.esm")
  RegisterScreenshotOf(351554, "Skyrim.esm")
  RegisterScreenshotOf(351514, "Skyrim.esm")
  RegisterScreenshotOf(351466, "Skyrim.esm")
  RegisterScreenshotOf(351040, "Skyrim.esm")
  RegisterScreenshotOf(350748, "Skyrim.esm")
  RegisterScreenshotOf(350464, "Skyrim.esm")
  RegisterScreenshotOf(350455, "Skyrim.esm")
  RegisterScreenshotOf(350453, "Skyrim.esm")
  RegisterScreenshotOf(350451, "Skyrim.esm")
  RegisterScreenshotOf(350449, "Skyrim.esm")
  RegisterScreenshotOf(350447, "Skyrim.esm")
  RegisterScreenshotOf(350445, "Skyrim.esm")
  RegisterScreenshotOf(923149, "Skyrim.esm")
  RegisterScreenshotOf(908496, "Skyrim.esm")
  RegisterScreenshotOf(787454, "Skyrim.esm")
  RegisterScreenshotOf(753992, "Skyrim.esm")
  RegisterScreenshotOf(131103, "Skyrim.esm")
  RegisterScreenshotOf(890579, "Skyrim.esm")
  RegisterScreenshotOf(890578, "Skyrim.esm")
  RegisterScreenshotOf(555930, "Skyrim.esm")
  RegisterScreenshotOf(1062043, "Skyrim.esm")
  RegisterScreenshotOf(321856, "Skyrim.esm")
  RegisterScreenshotOf(1109574, "Skyrim.esm")
  RegisterScreenshotOf(321859, "Skyrim.esm")
  RegisterScreenshotOf(1109575, "Skyrim.esm")
  RegisterScreenshotOf(321860, "Skyrim.esm")
  RegisterScreenshotOf(1078642, "Skyrim.esm")
  RegisterScreenshotOf(1092524, "Skyrim.esm")
  RegisterScreenshotOf(1092523, "Skyrim.esm")
  RegisterScreenshotOf(1092522, "Skyrim.esm")
  RegisterScreenshotOf(1092521, "Skyrim.esm")
  RegisterScreenshotOf(1092520, "Skyrim.esm")
  RegisterScreenshotOf(1092519, "Skyrim.esm")
  RegisterScreenshotOf(1092518, "Skyrim.esm")
  RegisterScreenshotOf(1092517, "Skyrim.esm")
  RegisterScreenshotOf(1092516, "Skyrim.esm")
  RegisterScreenshotOf(1092515, "Skyrim.esm")
  RegisterScreenshotOf(1092514, "Skyrim.esm")
  RegisterScreenshotOf(1092513, "Skyrim.esm")
  RegisterScreenshotOf(1092512, "Skyrim.esm")
  RegisterScreenshotOf(1092511, "Skyrim.esm")
  RegisterScreenshotOf(1092510, "Skyrim.esm")
  RegisterScreenshotOf(1092509, "Skyrim.esm")
  RegisterScreenshotOf(1092508, "Skyrim.esm")
  RegisterScreenshotOf(1092507, "Skyrim.esm")
  RegisterScreenshotOf(1092506, "Skyrim.esm")
  RegisterScreenshotOf(1092505, "Skyrim.esm")
  RegisterScreenshotOf(1092504, "Skyrim.esm")
  RegisterScreenshotOf(1092503, "Skyrim.esm")
  RegisterScreenshotOf(1092502, "Skyrim.esm")
  RegisterScreenshotOf(1092501, "Skyrim.esm")
  RegisterScreenshotOf(1092500, "Skyrim.esm")
  RegisterScreenshotOf(1092499, "Skyrim.esm")
  RegisterScreenshotOf(1092498, "Skyrim.esm")
  RegisterScreenshotOf(1092497, "Skyrim.esm")
  RegisterScreenshotOf(1092496, "Skyrim.esm")
  RegisterScreenshotOf(1092495, "Skyrim.esm")
  RegisterScreenshotOf(1092494, "Skyrim.esm")
  RegisterScreenshotOf(1092493, "Skyrim.esm")
  RegisterScreenshotOf(1092492, "Skyrim.esm")
  RegisterScreenshotOf(1092491, "Skyrim.esm")
  RegisterScreenshotOf(1092490, "Skyrim.esm")
  RegisterScreenshotOf(1092489, "Skyrim.esm")
  RegisterScreenshotOf(1092488, "Skyrim.esm")
  RegisterScreenshotOf(1092487, "Skyrim.esm")
  RegisterScreenshotOf(1092486, "Skyrim.esm")
  RegisterScreenshotOf(1092485, "Skyrim.esm")
  RegisterScreenshotOf(1092484, "Skyrim.esm")
  RegisterScreenshotOf(1092483, "Skyrim.esm")
  RegisterScreenshotOf(1092482, "Skyrim.esm")
  RegisterScreenshotOf(1092481, "Skyrim.esm")
  RegisterScreenshotOf(1092480, "Skyrim.esm")
  RegisterScreenshotOf(1092479, "Skyrim.esm")
  RegisterScreenshotOf(1092478, "Skyrim.esm")
  RegisterScreenshotOf(1092477, "Skyrim.esm")
  RegisterScreenshotOf(1092476, "Skyrim.esm")
  RegisterScreenshotOf(1092475, "Skyrim.esm")
  RegisterScreenshotOf(1092474, "Skyrim.esm")
  RegisterScreenshotOf(1092473, "Skyrim.esm")
  RegisterScreenshotOf(1092472, "Skyrim.esm")
  RegisterScreenshotOf(1092471, "Skyrim.esm")
  RegisterScreenshotOf(1092470, "Skyrim.esm")
  RegisterScreenshotOf(1092469, "Skyrim.esm")
  RegisterScreenshotOf(1092468, "Skyrim.esm")
  RegisterScreenshotOf(1092467, "Skyrim.esm")
  RegisterScreenshotOf(1092466, "Skyrim.esm")
  RegisterScreenshotOf(1092465, "Skyrim.esm")
  RegisterScreenshotOf(1092464, "Skyrim.esm")
  RegisterScreenshotOf(1092463, "Skyrim.esm")
  RegisterScreenshotOf(1092462, "Skyrim.esm")
  RegisterScreenshotOf(1092461, "Skyrim.esm")
  RegisterScreenshotOf(1092460, "Skyrim.esm")
  RegisterScreenshotOf(1092459, "Skyrim.esm")
  RegisterScreenshotOf(1092458, "Skyrim.esm")
  RegisterScreenshotOf(1092457, "Skyrim.esm")
  RegisterScreenshotOf(1092456, "Skyrim.esm")
  RegisterScreenshotOf(1092455, "Skyrim.esm")
  RegisterScreenshotOf(1092454, "Skyrim.esm")
  RegisterScreenshotOf(1092453, "Skyrim.esm")
  RegisterScreenshotOf(1092452, "Skyrim.esm")
  RegisterScreenshotOf(1092451, "Skyrim.esm")
  RegisterScreenshotOf(1092450, "Skyrim.esm")
  RegisterScreenshotOf(1092449, "Skyrim.esm")
  RegisterScreenshotOf(1092448, "Skyrim.esm")
  RegisterScreenshotOf(1092447, "Skyrim.esm")
  RegisterScreenshotOf(1092446, "Skyrim.esm")
  RegisterScreenshotOf(1092445, "Skyrim.esm")
  RegisterScreenshotOf(980199, "Skyrim.esm")
  RegisterScreenshotOf(630111, "Skyrim.esm")
  RegisterScreenshotOf(630110, "Skyrim.esm")
  RegisterScreenshotOf(630109, "Skyrim.esm")
  RegisterScreenshotOf(630104, "Skyrim.esm")
  RegisterScreenshotOf(630099, "Skyrim.esm")
  RegisterScreenshotOf(630098, "Skyrim.esm")
  RegisterScreenshotOf(630097, "Skyrim.esm")
  RegisterScreenshotOf(630096, "Skyrim.esm")
  RegisterScreenshotOf(630095, "Skyrim.esm")
  RegisterScreenshotOf(630094, "Skyrim.esm")
  RegisterScreenshotOf(630093, "Skyrim.esm")
  RegisterScreenshotOf(630092, "Skyrim.esm")
  RegisterScreenshotOf(630050, "Skyrim.esm")
  RegisterScreenshotOf(630049, "Skyrim.esm")
  RegisterScreenshotOf(499562, "Skyrim.esm")
  RegisterScreenshotOf(499561, "Skyrim.esm")
  RegisterScreenshotOf(499560, "Skyrim.esm")
  RegisterScreenshotOf(499559, "Skyrim.esm")
  RegisterScreenshotOf(499558, "Skyrim.esm")
  RegisterScreenshotOf(499557, "Skyrim.esm")
  RegisterScreenshotOf(499556, "Skyrim.esm")
  RegisterScreenshotOf(499555, "Skyrim.esm")
  RegisterScreenshotOf(499554, "Skyrim.esm")
  RegisterScreenshotOf(499553, "Skyrim.esm")
  RegisterScreenshotOf(499552, "Skyrim.esm")
  RegisterScreenshotOf(499551, "Skyrim.esm")
  RegisterScreenshotOf(499550, "Skyrim.esm")
  RegisterScreenshotOf(499549, "Skyrim.esm")
  RegisterScreenshotOf(499548, "Skyrim.esm")
  RegisterScreenshotOf(499547, "Skyrim.esm")
  RegisterScreenshotOf(499546, "Skyrim.esm")
  RegisterScreenshotOf(499545, "Skyrim.esm")
  RegisterScreenshotOf(499544, "Skyrim.esm")
  RegisterScreenshotOf(499543, "Skyrim.esm")
  RegisterScreenshotOf(499542, "Skyrim.esm")
  RegisterScreenshotOf(499541, "Skyrim.esm")
  RegisterScreenshotOf(499540, "Skyrim.esm")
  RegisterScreenshotOf(499539, "Skyrim.esm")
  RegisterScreenshotOf(499538, "Skyrim.esm")
  RegisterScreenshotOf(499537, "Skyrim.esm")
  RegisterScreenshotOf(499536, "Skyrim.esm")
  RegisterScreenshotOf(499535, "Skyrim.esm")
  RegisterScreenshotOf(499534, "Skyrim.esm")
  RegisterScreenshotOf(499493, "Skyrim.esm")
  RegisterScreenshotOf(499432, "Skyrim.esm")
  RegisterScreenshotOf(499430, "Skyrim.esm")
  RegisterScreenshotOf(499425, "Skyrim.esm")
  RegisterScreenshotOf(499247, "Skyrim.esm")
  RegisterScreenshotOf(499244, "Skyrim.esm")
  RegisterScreenshotOf(499157, "Skyrim.esm")
  RegisterScreenshotOf(498901, "Skyrim.esm")
  RegisterScreenshotOf(498900, "Skyrim.esm")
  RegisterScreenshotOf(498899, "Skyrim.esm")
  RegisterScreenshotOf(498894, "Skyrim.esm")
  RegisterScreenshotOf(498893, "Skyrim.esm")
  RegisterScreenshotOf(498840, "Skyrim.esm")
  RegisterScreenshotOf(498838, "Skyrim.esm")
  RegisterScreenshotOf(498772, "Skyrim.esm")
  RegisterScreenshotOf(498670, "Skyrim.esm")
  RegisterScreenshotOf(498669, "Skyrim.esm")
  RegisterScreenshotOf(498668, "Skyrim.esm")
  RegisterScreenshotOf(498667, "Skyrim.esm")
  RegisterScreenshotOf(498662, "Skyrim.esm")
  RegisterScreenshotOf(479582, "Skyrim.esm")
  RegisterScreenshotOf(479570, "Skyrim.esm")
  RegisterScreenshotOf(479566, "Skyrim.esm")
  RegisterScreenshotOf(478170, "Skyrim.esm")
  RegisterScreenshotOf(478169, "Skyrim.esm")
  RegisterScreenshotOf(478168, "Skyrim.esm")
  RegisterScreenshotOf(477976, "Skyrim.esm")
  RegisterScreenshotOf(477973, "Skyrim.esm")
  RegisterScreenshotOf(389031, "Skyrim.esm")
  RegisterScreenshotOf(389020, "Skyrim.esm")
  RegisterScreenshotOf(389018, "Skyrim.esm")
  RegisterScreenshotOf(374008, "Skyrim.esm")
  RegisterScreenshotOf(221683, "Skyrim.esm")
  RegisterScreenshotOf(158036, "Skyrim.esm")
  RegisterScreenshotOf(158030, "Skyrim.esm")
  RegisterScreenshotOf(157991, "Skyrim.esm")
  RegisterScreenshotOf(157985, "Skyrim.esm")
  RegisterScreenshotOf(157973, "Skyrim.esm")
  RegisterScreenshotOf(157956, "Skyrim.esm")
  RegisterScreenshotOf(157948, "Skyrim.esm")
  RegisterScreenshotOf(148065, "Skyrim.esm")
  RegisterScreenshotOf(148063, "Skyrim.esm")
  RegisterScreenshotOf(95503, "Skyrim.esm")
  RegisterScreenshotOf(95502, "Skyrim.esm")
  RegisterScreenshotOf(95501, "Skyrim.esm")
  RegisterScreenshotOf(95500, "Skyrim.esm")
  RegisterScreenshotOf(7, "Skyrim.esm")
  RegisterScreenshotOf(80826, "Skyrim.esm")
  RegisterScreenshotOf(725415, "Skyrim.esm")
  RegisterScreenshotOf(921554, "Skyrim.esm")
  RegisterScreenshotOf(285886, "Skyrim.esm")
  RegisterScreenshotOf(178748, "Skyrim.esm")
  RegisterScreenshotOf(158802, "Skyrim.esm")
  RegisterScreenshotOf(82252, "Skyrim.esm")
  RegisterScreenshotOf(866255, "Skyrim.esm")
  RegisterScreenshotOf(175042, "Skyrim.esm")
  RegisterScreenshotOf(111059, "Skyrim.esm")
  RegisterScreenshotOf(449693, "Skyrim.esm")
  RegisterScreenshotOf(539415, "Skyrim.esm")
  RegisterScreenshotOf(78770, "Skyrim.esm")
  RegisterScreenshotOf(80746, "Skyrim.esm")
  RegisterScreenshotOf(705144, "Skyrim.esm")
  RegisterScreenshotOf(217937, "Skyrim.esm")
  RegisterScreenshotOf(180125, "Skyrim.esm")
  RegisterScreenshotOf(295262, "Skyrim.esm")
  RegisterScreenshotOf(115078, "Skyrim.esm")
  RegisterScreenshotOf(82237, "Skyrim.esm")
  RegisterScreenshotOf(721828, "Skyrim.esm")
  RegisterScreenshotOf(223432, "Skyrim.esm")
  RegisterScreenshotOf(648321, "Skyrim.esm")
  RegisterScreenshotOf(398183, "Skyrim.esm")
  RegisterScreenshotOf(148122, "Skyrim.esm")
  RegisterScreenshotOf(130409, "Skyrim.esm")
  RegisterScreenshotOf(78771, "Skyrim.esm")
  RegisterScreenshotOf(555928, "Skyrim.esm")
  RegisterScreenshotOf(792840, "Skyrim.esm")
  RegisterScreenshotOf(1062149, "Skyrim.esm")
  RegisterScreenshotOf(1062148, "Skyrim.esm")
  RegisterScreenshotOf(1062133, "Skyrim.esm")
  RegisterScreenshotOf(295192, "Skyrim.esm")
  RegisterScreenshotOf(295191, "Skyrim.esm")
  RegisterScreenshotOf(755115, "Skyrim.esm")
  RegisterScreenshotOf(476621, "Skyrim.esm")
  RegisterScreenshotOf(476619, "Skyrim.esm")
  RegisterScreenshotOf(476615, "Skyrim.esm")
  RegisterScreenshotOf(79540, "Skyrim.esm")
  RegisterScreenshotOf(243016, "Skyrim.esm")
  RegisterScreenshotOf(951343, "Skyrim.esm")
  RegisterScreenshotOf(774491, "Skyrim.esm")
  RegisterScreenshotOf(774490, "Skyrim.esm")
  RegisterScreenshotOf(1016996, "Skyrim.esm")
  RegisterScreenshotOf(82234, "Skyrim.esm")
  RegisterScreenshotOf(376619, "Skyrim.esm")
  RegisterScreenshotOf(78772, "Skyrim.esm")
  RegisterScreenshotOf(498148, "Skyrim.esm")
  RegisterScreenshotOf(111067, "Skyrim.esm")
  RegisterScreenshotOf(108247, "Skyrim.esm")
  RegisterScreenshotOf(606559, "Skyrim.esm")
  RegisterScreenshotOf(197613, "Skyrim.esm")
  RegisterScreenshotOf(197237, "Skyrim.esm")
  RegisterScreenshotOf(1008368, "Skyrim.esm")
  RegisterScreenshotOf(1008367, "Skyrim.esm")
  RegisterScreenshotOf(284756, "Skyrim.esm")
  RegisterScreenshotOf(196772, "Skyrim.esm")
  RegisterScreenshotOf(284839, "Skyrim.esm")
  RegisterScreenshotOf(175040, "Skyrim.esm")
  RegisterScreenshotOf(165106, "Skyrim.esm")
  RegisterScreenshotOf(277793, "Skyrim.esm")
  RegisterScreenshotOf(78773, "Skyrim.esm")
  RegisterScreenshotOf(81983, "Skyrim.esm")
  RegisterScreenshotOf(670683, "Skyrim.esm")
  RegisterScreenshotOf(258025, "Skyrim.esm")
  RegisterScreenshotOf(78711, "Skyrim.esm")
  RegisterScreenshotOf(78774, "Skyrim.esm")
  RegisterScreenshotOf(79538, "Skyrim.esm")
  RegisterScreenshotOf(78498, "Skyrim.esm")
  RegisterScreenshotOf(230025, "Skyrim.esm")
  RegisterScreenshotOf(237343, "Skyrim.esm")
  RegisterScreenshotOf(78712, "Skyrim.esm")
  RegisterScreenshotOf(80833, "Skyrim.esm")
  RegisterScreenshotOf(872414, "Skyrim.esm")
  RegisterScreenshotOf(79437, "Skyrim.esm")
  RegisterScreenshotOf(79390, "Skyrim.esm")
  RegisterScreenshotOf(80802, "Skyrim.esm")
  RegisterScreenshotOf(1062199, "Skyrim.esm")
  RegisterScreenshotOf(1062198, "Skyrim.esm")
  RegisterScreenshotOf(1062197, "Skyrim.esm")
  RegisterScreenshotOf(1062196, "Skyrim.esm")
  RegisterScreenshotOf(1062195, "Skyrim.esm")
  RegisterScreenshotOf(1062194, "Skyrim.esm")
  RegisterScreenshotOf(78499, "Skyrim.esm")
  RegisterScreenshotOf(178828, "Skyrim.esm")
  RegisterScreenshotOf(146101, "Skyrim.esm")
  RegisterScreenshotOf(949933, "Skyrim.esm")
  RegisterScreenshotOf(78713, "Skyrim.esm")
  RegisterScreenshotOf(80792, "Skyrim.esm")
  RegisterScreenshotOf(78439, "Skyrim.esm")
  RegisterScreenshotOf(208283, "Skyrim.esm")
  RegisterScreenshotOf(811025, "Skyrim.esm")
  RegisterScreenshotOf(445786, "Skyrim.esm")
  RegisterScreenshotOf(787457, "Skyrim.esm")
  RegisterScreenshotOf(753993, "Skyrim.esm")
  RegisterScreenshotOf(606226, "Skyrim.esm")
  RegisterScreenshotOf(113564, "Skyrim.esm")
  RegisterScreenshotOf(78714, "Skyrim.esm")
  RegisterScreenshotOf(873553, "Skyrim.esm")
  RegisterScreenshotOf(606924, "Skyrim.esm")
  RegisterScreenshotOf(188914, "Skyrim.esm")
  RegisterScreenshotOf(637767, "Skyrim.esm")
  RegisterScreenshotOf(792995, "Skyrim.esm")
  RegisterScreenshotOf(548161, "Skyrim.esm")
  RegisterScreenshotOf(853979, "Skyrim.esm")
  RegisterScreenshotOf(115103, "Skyrim.esm")
  RegisterScreenshotOf(78490, "Skyrim.esm")
  RegisterScreenshotOf(401669, "Skyrim.esm")
  RegisterScreenshotOf(555919, "Skyrim.esm")
  RegisterScreenshotOf(82222, "Skyrim.esm")
  RegisterScreenshotOf(555929, "Skyrim.esm")
  RegisterScreenshotOf(653383, "Skyrim.esm")
  RegisterScreenshotOf(239429, "Skyrim.esm")
  RegisterScreenshotOf(78775, "Skyrim.esm")
  RegisterScreenshotOf(185620, "Skyrim.esm")
  RegisterScreenshotOf(79391, "Skyrim.esm")
  RegisterScreenshotOf(115262, "Skyrim.esm")
  RegisterScreenshotOf(182565, "Skyrim.esm")
  RegisterScreenshotOf(987521, "Skyrim.esm")
  RegisterScreenshotOf(642263, "Skyrim.esm")
  RegisterScreenshotOf(78705, "Skyrim.esm")
  RegisterScreenshotOf(82202, "Skyrim.esm")
  RegisterScreenshotOf(104787, "Skyrim.esm")
  RegisterScreenshotOf(444520, "Skyrim.esm")
  RegisterScreenshotOf(80765, "Skyrim.esm")
  RegisterScreenshotOf(175209, "Skyrim.esm")
  RegisterScreenshotOf(173016, "Skyrim.esm")
  RegisterScreenshotOf(104791, "Skyrim.esm")
  RegisterScreenshotOf(78715, "Skyrim.esm")
  RegisterScreenshotOf(881912, "Skyrim.esm")
  RegisterScreenshotOf(79443, "Skyrim.esm")
  RegisterScreenshotOf(171414, "Skyrim.esm")
  RegisterScreenshotOf(636842, "Skyrim.esm")
  RegisterScreenshotOf(755134, "Skyrim.esm")
  RegisterScreenshotOf(970515, "Skyrim.esm")
  RegisterScreenshotOf(682056, "Skyrim.esm")
  RegisterScreenshotOf(682050, "Skyrim.esm")
  RegisterScreenshotOf(78966, "Skyrim.esm")
  RegisterScreenshotOf(843122, "Skyrim.esm")
  RegisterScreenshotOf(78501, "Skyrim.esm")
  RegisterScreenshotOf(334207, "Skyrim.esm")
  RegisterScreenshotOf(334220, "Skyrim.esm")
  RegisterScreenshotOf(82209, "Skyrim.esm")
  RegisterScreenshotOf(147660, "Skyrim.esm")
  RegisterScreenshotOf(1084351, "Skyrim.esm")
  RegisterScreenshotOf(1084350, "Skyrim.esm")
  RegisterScreenshotOf(1084349, "Skyrim.esm")
  RegisterScreenshotOf(1084348, "Skyrim.esm")
  RegisterScreenshotOf(1084347, "Skyrim.esm")
  RegisterScreenshotOf(816144, "Skyrim.esm")
  RegisterScreenshotOf(696458, "Skyrim.esm")
  RegisterScreenshotOf(693576, "Skyrim.esm")
  RegisterScreenshotOf(411244, "Skyrim.esm")
  RegisterScreenshotOf(280991, "Skyrim.esm")
  RegisterScreenshotOf(174985, "Skyrim.esm")
  RegisterScreenshotOf(174984, "Skyrim.esm")
  RegisterScreenshotOf(174983, "Skyrim.esm")
  RegisterScreenshotOf(755306, "Skyrim.esm")
  RegisterScreenshotOf(755305, "Skyrim.esm")
  RegisterScreenshotOf(223242, "Skyrim.esm")
  RegisterScreenshotOf(402145, "Skyrim.esm")
  RegisterScreenshotOf(307374, "Skyrim.esm")
  RegisterScreenshotOf(978417, "Skyrim.esm")
  RegisterScreenshotOf(442807, "Skyrim.esm")
  RegisterScreenshotOf(79532, "Skyrim.esm")
  RegisterScreenshotOf(529333, "Skyrim.esm")
  RegisterScreenshotOf(79367, "Skyrim.esm")
  RegisterScreenshotOf(79546, "Skyrim.esm")
  RegisterScreenshotOf(78776, "Skyrim.esm")
  RegisterScreenshotOf(79392, "Skyrim.esm")
  RegisterScreenshotOf(1055067, "Skyrim.esm")
  RegisterScreenshotOf(980496, "Skyrim.esm")
  RegisterScreenshotOf(295328, "Skyrim.esm")
  RegisterScreenshotOf(146103, "Skyrim.esm")
  RegisterScreenshotOf(943662, "Skyrim.esm")
  RegisterScreenshotOf(1016995, "Skyrim.esm")
  RegisterScreenshotOf(521881, "Skyrim.esm")
  RegisterScreenshotOf(596268, "Skyrim.esm")
  RegisterScreenshotOf(1065334, "Skyrim.esm")
  RegisterScreenshotOf(761816, "Skyrim.esm")
  RegisterScreenshotOf(603691, "Skyrim.esm")
  RegisterScreenshotOf(184829, "Skyrim.esm")
  RegisterScreenshotOf(184828, "Skyrim.esm")
  RegisterScreenshotOf(184800, "Skyrim.esm")
  RegisterScreenshotOf(184798, "Skyrim.esm")
  RegisterScreenshotOf(108176, "Skyrim.esm")
  RegisterScreenshotOf(80760, "Skyrim.esm")
  RegisterScreenshotOf(80823, "Skyrim.esm")
  RegisterScreenshotOf(146104, "Skyrim.esm")
  RegisterScreenshotOf(902374, "Skyrim.esm")
  RegisterScreenshotOf(110705, "Skyrim.esm")
  RegisterScreenshotOf(78502, "Skyrim.esm")
  RegisterScreenshotOf(517612, "Skyrim.esm")
  RegisterScreenshotOf(146060, "Skyrim.esm")
  RegisterScreenshotOf(534966, "Skyrim.esm")
  RegisterScreenshotOf(146102, "Skyrim.esm")
  RegisterScreenshotOf(79442, "Skyrim.esm")
  RegisterScreenshotOf(653298, "Skyrim.esm")
  RegisterScreenshotOf(653297, "Skyrim.esm")
  RegisterScreenshotOf(653290, "Skyrim.esm")
  RegisterScreenshotOf(1097832, "Skyrim.esm")
  RegisterScreenshotOf(736847, "Skyrim.esm")
  RegisterScreenshotOf(545732, "Skyrim.esm")
  RegisterScreenshotOf(758947, "Skyrim.esm")
  RegisterScreenshotOf(89284, "Skyrim.esm")
  RegisterScreenshotOf(79467, "Skyrim.esm")
  RegisterScreenshotOf(78503, "Skyrim.esm")
  RegisterScreenshotOf(79366, "Skyrim.esm")
  RegisterScreenshotOf(78777, "Skyrim.esm")
  RegisterScreenshotOf(659017, "Skyrim.esm")
  RegisterScreenshotOf(1020000, "Skyrim.esm")
  RegisterScreenshotOf(725487, "Skyrim.esm")
  RegisterScreenshotOf(1009512, "Skyrim.esm")
  RegisterScreenshotOf(645787, "Skyrim.esm")
  RegisterScreenshotOf(146105, "Skyrim.esm")
  RegisterScreenshotOf(997637, "Skyrim.esm")
  RegisterScreenshotOf(633403, "Skyrim.esm")
  RegisterScreenshotOf(308399, "Skyrim.esm")
  RegisterScreenshotOf(604790, "Skyrim.esm")
  RegisterScreenshotOf(308401, "Skyrim.esm")
  RegisterScreenshotOf(82224, "Skyrim.esm")
  RegisterScreenshotOf(604193, "Skyrim.esm")
  RegisterScreenshotOf(104985, "Skyrim.esm")
  RegisterScreenshotOf(760195, "Skyrim.esm")
  RegisterScreenshotOf(121856, "Skyrim.esm")
  RegisterScreenshotOf(1109573, "Skyrim.esm")
  RegisterScreenshotOf(146088, "Skyrim.esm")
  RegisterScreenshotOf(132290, "Skyrim.esm")
  RegisterScreenshotOf(921548, "Skyrim.esm")
  RegisterScreenshotOf(285858, "Skyrim.esm")
  RegisterScreenshotOf(921543, "Skyrim.esm")
  RegisterScreenshotOf(285820, "Skyrim.esm")
  RegisterScreenshotOf(843470, "Skyrim.esm")
  RegisterScreenshotOf(635562, "Skyrim.esm")
  RegisterScreenshotOf(518271, "Skyrim.esm")
  RegisterScreenshotOf(921553, "Skyrim.esm")
  RegisterScreenshotOf(285885, "Skyrim.esm")
  RegisterScreenshotOf(285668, "Skyrim.esm")
  RegisterScreenshotOf(244935, "Skyrim.esm")
  RegisterScreenshotOf(132552, "Skyrim.esm")
  RegisterScreenshotOf(350687, "Skyrim.esm")
  RegisterScreenshotOf(1050448, "Skyrim.esm")
  RegisterScreenshotOf(182300, "Skyrim.esm")
  RegisterScreenshotOf(287275, "Skyrim.esm")
  RegisterScreenshotOf(92878, "Skyrim.esm")
  RegisterScreenshotOf(1089960, "Skyrim.esm")
  RegisterScreenshotOf(1089959, "Skyrim.esm")
  RegisterScreenshotOf(1089958, "Skyrim.esm")
  RegisterScreenshotOf(1089957, "Skyrim.esm")
  RegisterScreenshotOf(1089956, "Skyrim.esm")
  RegisterScreenshotOf(1087649, "Skyrim.esm")
  RegisterScreenshotOf(1021106, "Skyrim.esm")
  RegisterScreenshotOf(1021105, "Skyrim.esm")
  RegisterScreenshotOf(1016586, "Skyrim.esm")
  RegisterScreenshotOf(1013647, "Skyrim.esm")
  RegisterScreenshotOf(955948, "Skyrim.esm")
  RegisterScreenshotOf(841405, "Skyrim.esm")
  RegisterScreenshotOf(841404, "Skyrim.esm")
  RegisterScreenshotOf(752060, "Skyrim.esm")
  RegisterScreenshotOf(726675, "Skyrim.esm")
  RegisterScreenshotOf(698691, "Skyrim.esm")
  RegisterScreenshotOf(698690, "Skyrim.esm")
  RegisterScreenshotOf(698678, "Skyrim.esm")
  RegisterScreenshotOf(698677, "Skyrim.esm")
  RegisterScreenshotOf(698675, "Skyrim.esm")
  RegisterScreenshotOf(698674, "Skyrim.esm")
  RegisterScreenshotOf(698673, "Skyrim.esm")
  RegisterScreenshotOf(698660, "Skyrim.esm")
  RegisterScreenshotOf(698658, "Skyrim.esm")
  RegisterScreenshotOf(373253, "Skyrim.esm")
  RegisterScreenshotOf(316262, "Skyrim.esm")
  RegisterScreenshotOf(288699, "Skyrim.esm")
  RegisterScreenshotOf(160920, "Skyrim.esm")
  RegisterScreenshotOf(1086599, "Skyrim.esm")
  RegisterScreenshotOf(604241, "Skyrim.esm")
  RegisterScreenshotOf(455188, "Skyrim.esm")
  RegisterScreenshotOf(124458, "Skyrim.esm")
  RegisterScreenshotOf(78504, "Skyrim.esm")
  RegisterScreenshotOf(333302, "Skyrim.esm")
  RegisterScreenshotOf(215066, "Skyrim.esm")
  RegisterScreenshotOf(295263, "Skyrim.esm")
  RegisterScreenshotOf(241890, "Skyrim.esm")
  RegisterScreenshotOf(653370, "Skyrim.esm")
  RegisterScreenshotOf(82247, "Skyrim.esm")
  RegisterScreenshotOf(808566, "Skyrim.esm")
  RegisterScreenshotOf(82219, "Skyrim.esm")
  RegisterScreenshotOf(82210, "Skyrim.esm")
  RegisterScreenshotOf(93319, "Skyrim.esm")
  RegisterScreenshotOf(78716, "Skyrim.esm")
  RegisterScreenshotOf(78505, "Skyrim.esm")
  RegisterScreenshotOf(78975, "Skyrim.esm")
  RegisterScreenshotOf(79368, "Skyrim.esm")
  RegisterScreenshotOf(78506, "Skyrim.esm")
  RegisterScreenshotOf(801343, "Skyrim.esm")
  RegisterScreenshotOf(766656, "Skyrim.esm")
  RegisterScreenshotOf(171434, "Skyrim.esm")
  RegisterScreenshotOf(725327, "Skyrim.esm")
  RegisterScreenshotOf(574410, "Skyrim.esm")
  RegisterScreenshotOf(78507, "Skyrim.esm")
  RegisterScreenshotOf(81965, "Skyrim.esm")
  RegisterScreenshotOf(755596, "Skyrim.esm")
  RegisterScreenshotOf(78707, "Skyrim.esm")
  RegisterScreenshotOf(79369, "Skyrim.esm")
  RegisterScreenshotOf(540057, "Skyrim.esm")
  RegisterScreenshotOf(237968, "Skyrim.esm")
  RegisterScreenshotOf(234064, "Skyrim.esm")
  RegisterScreenshotOf(104996, "Skyrim.esm")
  RegisterScreenshotOf(79370, "Skyrim.esm")
  RegisterScreenshotOf(79446, "Skyrim.esm")
  RegisterScreenshotOf(113160, "Skyrim.esm")
  RegisterScreenshotOf(415954, "Skyrim.esm")
  RegisterScreenshotOf(108147, "Skyrim.esm")
  RegisterScreenshotOf(104120, "Skyrim.esm")
  RegisterScreenshotOf(839169, "Skyrim.esm")
  RegisterScreenshotOf(781522, "Skyrim.esm")
  RegisterScreenshotOf(188703, "Skyrim.esm")
  RegisterScreenshotOf(839164, "Skyrim.esm")
  RegisterScreenshotOf(1102144, "Skyrim.esm")
  RegisterScreenshotOf(1102142, "Skyrim.esm")
  RegisterScreenshotOf(1102143, "Skyrim.esm")
  RegisterScreenshotOf(364961, "Skyrim.esm")
  RegisterScreenshotOf(1070483, "Skyrim.esm")
  RegisterScreenshotOf(321001, "Skyrim.esm")
  RegisterScreenshotOf(115081, "Skyrim.esm")
  RegisterScreenshotOf(636838, "Skyrim.esm")
  RegisterScreenshotOf(1069423, "Skyrim.esm")
  RegisterScreenshotOf(1069422, "Skyrim.esm")
  RegisterScreenshotOf(744977, "Skyrim.esm")
  RegisterScreenshotOf(753919, "Skyrim.esm")
  RegisterScreenshotOf(469164, "Skyrim.esm")
  RegisterScreenshotOf(176420, "Skyrim.esm")
  RegisterScreenshotOf(469165, "Skyrim.esm")
  RegisterScreenshotOf(315974, "Skyrim.esm")
  RegisterScreenshotOf(866292, "Skyrim.esm")
  RegisterScreenshotOf(1086373, "Skyrim.esm")
  RegisterScreenshotOf(1062160, "Skyrim.esm")
  RegisterScreenshotOf(981443, "Skyrim.esm")
  RegisterScreenshotOf(955347, "Skyrim.esm")
  RegisterScreenshotOf(754030, "Skyrim.esm")
  RegisterScreenshotOf(147176, "Skyrim.esm")
  RegisterScreenshotOf(843912, "Skyrim.esm")
  RegisterScreenshotOf(801573, "Skyrim.esm")
  RegisterScreenshotOf(78778, "Skyrim.esm")
  RegisterScreenshotOf(78779, "Skyrim.esm")
  RegisterScreenshotOf(115073, "Skyrim.esm")
  RegisterScreenshotOf(79346, "Skyrim.esm")
  RegisterScreenshotOf(115265, "Skyrim.esm")
  RegisterScreenshotOf(213503, "Skyrim.esm")
  RegisterScreenshotOf(148088, "Skyrim.esm")
  RegisterScreenshotOf(714615, "Skyrim.esm")
  RegisterScreenshotOf(79393, "Skyrim.esm")
  RegisterScreenshotOf(542047, "Skyrim.esm")
  RegisterScreenshotOf(78695, "Skyrim.esm")
  RegisterScreenshotOf(872411, "Skyrim.esm")
  RegisterScreenshotOf(758192, "Skyrim.esm")
  RegisterScreenshotOf(147185, "Skyrim.esm")
  RegisterScreenshotOf(80822, "Skyrim.esm")
  RegisterScreenshotOf(115102, "Skyrim.esm")
  RegisterScreenshotOf(755751, "Skyrim.esm")
  RegisterScreenshotOf(82239, "Skyrim.esm")
  RegisterScreenshotOf(843908, "Skyrim.esm")
  RegisterScreenshotOf(81981, "Skyrim.esm")
  RegisterScreenshotOf(79425, "Skyrim.esm")
  RegisterScreenshotOf(193602, "Skyrim.esm")
  RegisterScreenshotOf(82230, "Skyrim.esm")
  RegisterScreenshotOf(227884, "Skyrim.esm")
  RegisterScreenshotOf(227880, "Skyrim.esm")
  RegisterScreenshotOf(89358, "Skyrim.esm")
  RegisterScreenshotOf(89346, "Skyrim.esm")
  RegisterScreenshotOf(759378, "Skyrim.esm")
  RegisterScreenshotOf(759381, "Skyrim.esm")
  RegisterScreenshotOf(108251, "Skyrim.esm")
  RegisterScreenshotOf(862998, "Skyrim.esm")
  RegisterScreenshotOf(82213, "Skyrim.esm")
  RegisterScreenshotOf(857734, "Skyrim.esm")
  RegisterScreenshotOf(857733, "Skyrim.esm")
  RegisterScreenshotOf(555932, "Skyrim.esm")
  RegisterScreenshotOf(856640, "Skyrim.esm")
  RegisterScreenshotOf(661423, "Skyrim.esm")
  RegisterScreenshotOf(104987, "Skyrim.esm")
  RegisterScreenshotOf(277421, "Skyrim.esm")
  RegisterScreenshotOf(984954, "Skyrim.esm")
  RegisterScreenshotOf(146106, "Skyrim.esm")
  RegisterScreenshotOf(218055, "Skyrim.esm")
  RegisterScreenshotOf(843905, "Skyrim.esm")
  RegisterScreenshotOf(325672, "Skyrim.esm")
  RegisterScreenshotOf(82233, "Skyrim.esm")
  RegisterScreenshotOf(104813, "Skyrim.esm")
  RegisterScreenshotOf(878360, "Skyrim.esm")
  RegisterScreenshotOf(78717, "Skyrim.esm")
  RegisterScreenshotOf(78780, "Skyrim.esm")
  RegisterScreenshotOf(719778, "Skyrim.esm")
  RegisterScreenshotOf(930159, "Skyrim.esm")
  RegisterScreenshotOf(106010, "Skyrim.esm")
  RegisterScreenshotOf(928703, "Skyrim.esm")
  RegisterScreenshotOf(80799, "Skyrim.esm")
  RegisterScreenshotOf(960284, "Skyrim.esm")
  RegisterScreenshotOf(529148, "Skyrim.esm")
  RegisterScreenshotOf(853365, "Skyrim.esm")
  RegisterScreenshotOf(82253, "Skyrim.esm")
  RegisterScreenshotOf(82241, "Skyrim.esm")
  RegisterScreenshotOf(241891, "Skyrim.esm")
  RegisterScreenshotOf(80766, "Skyrim.esm")
  RegisterScreenshotOf(78508, "Skyrim.esm")
  RegisterScreenshotOf(630575, "Skyrim.esm")
  RegisterScreenshotOf(555924, "Skyrim.esm")
  RegisterScreenshotOf(78718, "Skyrim.esm")
  RegisterScreenshotOf(225751, "Skyrim.esm")
  RegisterScreenshotOf(78781, "Skyrim.esm")
  RegisterScreenshotOf(115091, "Skyrim.esm")
  RegisterScreenshotOf(336459, "Skyrim.esm")
  RegisterScreenshotOf(110712, "Skyrim.esm")
  RegisterScreenshotOf(949929, "Skyrim.esm")
  RegisterScreenshotOf(78782, "Skyrim.esm")
  RegisterScreenshotOf(596194, "Skyrim.esm")
  RegisterScreenshotOf(923341, "Skyrim.esm")
  RegisterScreenshotOf(758179, "Skyrim.esm")
  RegisterScreenshotOf(646610, "Skyrim.esm")
  RegisterScreenshotOf(646605, "Skyrim.esm")
  RegisterScreenshotOf(503040, "Skyrim.esm")
  RegisterScreenshotOf(671630, "Skyrim.esm")
  RegisterScreenshotOf(469764, "Skyrim.esm")
  RegisterScreenshotOf(180621, "Skyrim.esm")
  RegisterScreenshotOf(266682, "Skyrim.esm")
  RegisterScreenshotOf(79445, "Skyrim.esm")
  RegisterScreenshotOf(241889, "Skyrim.esm")
  RegisterScreenshotOf(78719, "Skyrim.esm")
  RegisterScreenshotOf(106470, "Skyrim.esm")
  RegisterScreenshotOf(208872, "Skyrim.esm")
  RegisterScreenshotOf(208871, "Skyrim.esm")
  RegisterScreenshotOf(211023, "Skyrim.esm")
  RegisterScreenshotOf(211024, "Skyrim.esm")
  RegisterScreenshotOf(582391, "Skyrim.esm")
  RegisterScreenshotOf(270951, "Skyrim.esm")
  RegisterScreenshotOf(192238, "Skyrim.esm")
  RegisterScreenshotOf(192237, "Skyrim.esm")
  RegisterScreenshotOf(192236, "Skyrim.esm")
  RegisterScreenshotOf(192235, "Skyrim.esm")
  RegisterScreenshotOf(192234, "Skyrim.esm")
  RegisterScreenshotOf(192233, "Skyrim.esm")
  RegisterScreenshotOf(192232, "Skyrim.esm")
  RegisterScreenshotOf(192231, "Skyrim.esm")
  RegisterScreenshotOf(192230, "Skyrim.esm")
  RegisterScreenshotOf(192229, "Skyrim.esm")
  RegisterScreenshotOf(192225, "Skyrim.esm")
  RegisterScreenshotOf(192224, "Skyrim.esm")
  RegisterScreenshotOf(192223, "Skyrim.esm")
  RegisterScreenshotOf(192222, "Skyrim.esm")
  RegisterScreenshotOf(192221, "Skyrim.esm")
  RegisterScreenshotOf(192220, "Skyrim.esm")
  RegisterScreenshotOf(192216, "Skyrim.esm")
  RegisterScreenshotOf(192215, "Skyrim.esm")
  RegisterScreenshotOf(192214, "Skyrim.esm")
  RegisterScreenshotOf(192213, "Skyrim.esm")
  RegisterScreenshotOf(192211, "Skyrim.esm")
  RegisterScreenshotOf(192210, "Skyrim.esm")
  RegisterScreenshotOf(192209, "Skyrim.esm")
  RegisterScreenshotOf(192208, "Skyrim.esm")
  RegisterScreenshotOf(192158, "Skyrim.esm")
  RegisterScreenshotOf(192157, "Skyrim.esm")
  RegisterScreenshotOf(191878, "Skyrim.esm")
  RegisterScreenshotOf(191854, "Skyrim.esm")
  RegisterScreenshotOf(191853, "Skyrim.esm")
  RegisterScreenshotOf(191851, "Skyrim.esm")
  RegisterScreenshotOf(191515, "Skyrim.esm")
  RegisterScreenshotOf(191243, "Skyrim.esm")
  RegisterScreenshotOf(171439, "Skyrim.esm")
  RegisterScreenshotOf(521257, "Skyrim.esm")
  RegisterScreenshotOf(108209, "Skyrim.esm")
  RegisterScreenshotOf(104998, "Skyrim.esm")
  RegisterScreenshotOf(189424, "Skyrim.esm")
  RegisterScreenshotOf(189511, "Skyrim.esm")
  RegisterScreenshotOf(115626, "Skyrim.esm")
  RegisterScreenshotOf(78720, "Skyrim.esm")
  RegisterScreenshotOf(482431, "Skyrim.esm")
  RegisterScreenshotOf(299250, "Skyrim.esm")
  RegisterScreenshotOf(213502, "Skyrim.esm")
  RegisterScreenshotOf(148092, "Skyrim.esm")
  RegisterScreenshotOf(79461, "Skyrim.esm")
  RegisterScreenshotOf(118160, "Skyrim.esm")
  RegisterScreenshotOf(78509, "Skyrim.esm")
  RegisterScreenshotOf(539414, "Skyrim.esm")
  RegisterScreenshotOf(843909, "Skyrim.esm")
  RegisterScreenshotOf(803850, "Skyrim.esm")
  RegisterScreenshotOf(78783, "Skyrim.esm")
  RegisterScreenshotOf(632746, "Skyrim.esm")
  RegisterScreenshotOf(785236, "Skyrim.esm")
  RegisterScreenshotOf(684859, "Skyrim.esm")
  RegisterScreenshotOf(80821, "Skyrim.esm")
  RegisterScreenshotOf(1041458, "Skyrim.esm")
  RegisterScreenshotOf(108180, "Skyrim.esm")
  RegisterScreenshotOf(1007753, "Skyrim.esm")
  RegisterScreenshotOf(79422, "Skyrim.esm")
  RegisterScreenshotOf(82217, "Skyrim.esm")
  RegisterScreenshotOf(118159, "Skyrim.esm")
  RegisterScreenshotOf(79345, "Skyrim.esm")
  RegisterScreenshotOf(555925, "Skyrim.esm")
  RegisterScreenshotOf(78458, "Skyrim.esm")
  RegisterScreenshotOf(78510, "Skyrim.esm")
  RegisterScreenshotOf(78784, "Skyrim.esm")
  RegisterScreenshotOf(317723, "Skyrim.esm")
  RegisterScreenshotOf(555391, "Skyrim.esm")
  RegisterScreenshotOf(206786, "Skyrim.esm")
  RegisterScreenshotOf(82204, "Skyrim.esm")
  RegisterScreenshotOf(188863, "Skyrim.esm")
  RegisterScreenshotOf(211026, "Skyrim.esm")
  RegisterScreenshotOf(268592, "Skyrim.esm")
  RegisterScreenshotOf(760191, "Skyrim.esm")
  RegisterScreenshotOf(1041456, "Skyrim.esm")
  RegisterScreenshotOf(518855, "Skyrim.esm")
  RegisterScreenshotOf(78721, "Skyrim.esm")
  RegisterScreenshotOf(957867, "Skyrim.esm")
  RegisterScreenshotOf(555917, "Skyrim.esm")
  RegisterScreenshotOf(313175, "Skyrim.esm")
  RegisterScreenshotOf(313141, "Skyrim.esm")
  RegisterScreenshotOf(493339, "Skyrim.esm")
  RegisterScreenshotOf(146108, "Skyrim.esm")
  RegisterScreenshotOf(110928, "Skyrim.esm")
  RegisterScreenshotOf(661877, "Skyrim.esm")
  RegisterScreenshotOf(657710, "Skyrim.esm")
  RegisterScreenshotOf(661875, "Skyrim.esm")
  RegisterScreenshotOf(657708, "Skyrim.esm")
  RegisterScreenshotOf(661874, "Skyrim.esm")
  RegisterScreenshotOf(657707, "Skyrim.esm")
  RegisterScreenshotOf(661876, "Skyrim.esm")
  RegisterScreenshotOf(657709, "Skyrim.esm")
  RegisterScreenshotOf(661878, "Skyrim.esm")
  RegisterScreenshotOf(657711, "Skyrim.esm")
  RegisterScreenshotOf(641194, "Skyrim.esm")
  RegisterScreenshotOf(1068870, "Skyrim.esm")
  RegisterScreenshotOf(1084811, "Skyrim.esm")
  RegisterScreenshotOf(1084810, "Skyrim.esm")
  RegisterScreenshotOf(1082008, "Skyrim.esm")
  RegisterScreenshotOf(1082006, "Skyrim.esm")
  RegisterScreenshotOf(1055127, "Skyrim.esm")
  RegisterScreenshotOf(1055126, "Skyrim.esm")
  RegisterScreenshotOf(958626, "Skyrim.esm")
  RegisterScreenshotOf(882553, "Skyrim.esm")
  RegisterScreenshotOf(774236, "Skyrim.esm")
  RegisterScreenshotOf(752029, "Skyrim.esm")
  RegisterScreenshotOf(674363, "Skyrim.esm")
  RegisterScreenshotOf(665548, "Skyrim.esm")
  RegisterScreenshotOf(409397, "Skyrim.esm")
  RegisterScreenshotOf(237527, "Skyrim.esm")
  RegisterScreenshotOf(136661, "Skyrim.esm")
  RegisterScreenshotOf(79547, "Skyrim.esm")
  RegisterScreenshotOf(418223, "Skyrim.esm")
  RegisterScreenshotOf(642265, "Skyrim.esm")
  RegisterScreenshotOf(285745, "Skyrim.esm")
  RegisterScreenshotOf(1036013, "Skyrim.esm")
  RegisterScreenshotOf(1036012, "Skyrim.esm")
  RegisterScreenshotOf(1036011, "Skyrim.esm")
  RegisterScreenshotOf(150371, "Skyrim.esm")
  RegisterScreenshotOf(181191, "Skyrim.esm")
  RegisterScreenshotOf(146109, "Skyrim.esm")
  RegisterScreenshotOf(479094, "Skyrim.esm")
  RegisterScreenshotOf(479093, "Skyrim.esm")
  RegisterScreenshotOf(479092, "Skyrim.esm")
  RegisterScreenshotOf(281804, "Skyrim.esm")
  RegisterScreenshotOf(87242, "Skyrim.esm")
  RegisterScreenshotOf(87241, "Skyrim.esm")
  RegisterScreenshotOf(87240, "Skyrim.esm")
  RegisterScreenshotOf(87239, "Skyrim.esm")
  RegisterScreenshotOf(480206, "Skyrim.esm")
  RegisterScreenshotOf(146110, "Skyrim.esm")
  RegisterScreenshotOf(943661, "Skyrim.esm")
  RegisterScreenshotOf(1007756, "Skyrim.esm")
  RegisterScreenshotOf(845264, "Skyrim.esm")
  RegisterScreenshotOf(140140, "Skyrim.esm")
  RegisterScreenshotOf(1070432, "Skyrim.esm")
  RegisterScreenshotOf(1070416, "Skyrim.esm")
  RegisterScreenshotOf(1070415, "Skyrim.esm")
  RegisterScreenshotOf(284677, "Skyrim.esm")
  RegisterScreenshotOf(284668, "Skyrim.esm")
  RegisterScreenshotOf(375095, "Skyrim.esm")
  RegisterScreenshotOf(375053, "Skyrim.esm")
  RegisterScreenshotOf(375047, "Skyrim.esm")
  RegisterScreenshotOf(238048, "Skyrim.esm")
  RegisterScreenshotOf(881909, "Skyrim.esm")
  RegisterScreenshotOf(78722, "Skyrim.esm")
  RegisterScreenshotOf(181962, "Skyrim.esm")
  RegisterScreenshotOf(82246, "Skyrim.esm")
  RegisterScreenshotOf(105967, "Skyrim.esm")
  RegisterScreenshotOf(393183, "Skyrim.esm")
  RegisterScreenshotOf(718115, "Skyrim.esm")
  RegisterScreenshotOf(241893, "Skyrim.esm")
  RegisterScreenshotOf(843911, "Skyrim.esm")
  RegisterScreenshotOf(110711, "Skyrim.esm")
  RegisterScreenshotOf(872441, "Skyrim.esm")
  RegisterScreenshotOf(78785, "Skyrim.esm")
  RegisterScreenshotOf(476078, "Skyrim.esm")
  RegisterScreenshotOf(476001, "Skyrim.esm")
  RegisterScreenshotOf(476000, "Skyrim.esm")
  RegisterScreenshotOf(542033, "Skyrim.esm")
  RegisterScreenshotOf(625617, "Skyrim.esm")
  RegisterScreenshotOf(147181, "Skyrim.esm")
  RegisterScreenshotOf(80811, "Skyrim.esm")
  RegisterScreenshotOf(237978, "Skyrim.esm")
  RegisterScreenshotOf(111056, "Skyrim.esm")
  RegisterScreenshotOf(16779268, "Update.esm")
  RegisterScreenshotOf(33590650, "Dawnguard.esm")
  RegisterScreenshotOf(33638108, "Dawnguard.esm")
  RegisterScreenshotOf(33638103, "Dawnguard.esm")
  RegisterScreenshotOf(33607613, "Dawnguard.esm")
  RegisterScreenshotOf(33567598, "Dawnguard.esm")
  RegisterScreenshotOf(33577627, "Dawnguard.esm")
  RegisterScreenshotOf(33659062, "Dawnguard.esm")
  RegisterScreenshotOf(33640760, "Dawnguard.esm")
  RegisterScreenshotOf(33568648, "Dawnguard.esm")
  RegisterScreenshotOf(33607865, "Dawnguard.esm")
  RegisterScreenshotOf(33607864, "Dawnguard.esm")
  RegisterScreenshotOf(33603024, "Dawnguard.esm")
  RegisterScreenshotOf(33590841, "Dawnguard.esm")
  RegisterScreenshotOf(33629266, "Dawnguard.esm")
  RegisterScreenshotOf(33564804, "Dawnguard.esm")
  RegisterScreenshotOf(33627349, "Dawnguard.esm")
  RegisterScreenshotOf(33569209, "Dawnguard.esm")
  RegisterScreenshotOf(33627346, "Dawnguard.esm")
  RegisterScreenshotOf(33659060, "Dawnguard.esm")
  RegisterScreenshotOf(33641500, "Dawnguard.esm")
  RegisterScreenshotOf(33640623, "Dawnguard.esm")
  RegisterScreenshotOf(33640622, "Dawnguard.esm")
  RegisterScreenshotOf(33603568, "Dawnguard.esm")
  RegisterScreenshotOf(33603422, "Dawnguard.esm")
  RegisterScreenshotOf(33583530, "Dawnguard.esm")
  RegisterScreenshotOf(33572281, "Dawnguard.esm")
  RegisterScreenshotOf(33663604, "Dawnguard.esm")
  RegisterScreenshotOf(33597786, "Dawnguard.esm")
  RegisterScreenshotOf(33637053, "Dawnguard.esm")
  RegisterScreenshotOf(33637052, "Dawnguard.esm")
  RegisterScreenshotOf(33628585, "Dawnguard.esm")
  RegisterScreenshotOf(33641502, "Dawnguard.esm")
  RegisterScreenshotOf(33633727, "Dawnguard.esm")
  RegisterScreenshotOf(33633724, "Dawnguard.esm")
  RegisterScreenshotOf(33575428, "Dawnguard.esm")
  RegisterScreenshotOf(33565089, "Dawnguard.esm")
  RegisterScreenshotOf(33613753, "Dawnguard.esm")
  RegisterScreenshotOf(33618345, "Dawnguard.esm")
  RegisterScreenshotOf(33663608, "Dawnguard.esm")
  RegisterScreenshotOf(33636886, "Dawnguard.esm")
  RegisterScreenshotOf(33617903, "Dawnguard.esm")
  RegisterScreenshotOf(33568018, "Dawnguard.esm")
  RegisterScreenshotOf(33571284, "Dawnguard.esm")
  RegisterScreenshotOf(33659196, "Dawnguard.esm")
  RegisterScreenshotOf(33661888, "Dawnguard.esm")
  RegisterScreenshotOf(33605103, "Dawnguard.esm")
  RegisterScreenshotOf(33577136, "Dawnguard.esm")
  RegisterScreenshotOf(33655600, "Dawnguard.esm")
  RegisterScreenshotOf(33641501, "Dawnguard.esm")
  RegisterScreenshotOf(33605402, "Dawnguard.esm")
  RegisterScreenshotOf(33566936, "Dawnguard.esm")
  RegisterScreenshotOf(33594690, "Dawnguard.esm")
  RegisterScreenshotOf(33607608, "Dawnguard.esm")
  RegisterScreenshotOf(33607610, "Dawnguard.esm")
  RegisterScreenshotOf(33607612, "Dawnguard.esm")
  RegisterScreenshotOf(33607611, "Dawnguard.esm")
  RegisterScreenshotOf(33643692, "Dawnguard.esm")
  RegisterScreenshotOf(33619072, "Dawnguard.esm")
  RegisterScreenshotOf(33636880, "Dawnguard.esm")
  RegisterScreenshotOf(33610116, "Dawnguard.esm")
  RegisterScreenshotOf(33610115, "Dawnguard.esm")
  RegisterScreenshotOf(33606367, "Dawnguard.esm")
  RegisterScreenshotOf(33567590, "Dawnguard.esm")
  RegisterScreenshotOf(33646668, "Dawnguard.esm")
  RegisterScreenshotOf(33567597, "Dawnguard.esm")
  RegisterScreenshotOf(33612179, "Dawnguard.esm")
  RegisterScreenshotOf(33612378, "Dawnguard.esm")
  RegisterScreenshotOf(33640731, "Dawnguard.esm")
  RegisterScreenshotOf(33582352, "Dawnguard.esm")
  RegisterScreenshotOf(33582353, "Dawnguard.esm")
  RegisterScreenshotOf(33640741, "Dawnguard.esm")
  RegisterScreenshotOf(33640734, "Dawnguard.esm")
  RegisterScreenshotOf(33610114, "Dawnguard.esm")
  RegisterScreenshotOf(33567587, "Dawnguard.esm")
  RegisterScreenshotOf(33581432, "Dawnguard.esm")
  RegisterScreenshotOf(33567588, "Dawnguard.esm")
  RegisterScreenshotOf(33650434, "Dawnguard.esm")
  RegisterScreenshotOf(33646855, "Dawnguard.esm")
  RegisterScreenshotOf(33617110, "Dawnguard.esm")
  RegisterScreenshotOf(33623290, "Dawnguard.esm")
  RegisterScreenshotOf(33596108, "Dawnguard.esm")
  RegisterScreenshotOf(33637511, "Dawnguard.esm")
  RegisterScreenshotOf(33663607, "Dawnguard.esm")
  RegisterScreenshotOf(33646671, "Dawnguard.esm")
  RegisterScreenshotOf(33567596, "Dawnguard.esm")
  RegisterScreenshotOf(33646670, "Dawnguard.esm")
  RegisterScreenshotOf(33567589, "Dawnguard.esm")
  RegisterScreenshotOf(33655604, "Dawnguard.esm")
  RegisterScreenshotOf(33590569, "Dawnguard.esm")
  RegisterScreenshotOf(33641499, "Dawnguard.esm")
  RegisterScreenshotOf(33567594, "Dawnguard.esm")
  RegisterScreenshotOf(33659064, "Dawnguard.esm")
  RegisterScreenshotOf(33592225, "Dawnguard.esm")
  RegisterScreenshotOf(33646669, "Dawnguard.esm")
  RegisterScreenshotOf(33574269, "Dawnguard.esm")
  RegisterScreenshotOf(33574156, "Dawnguard.esm")
  RegisterScreenshotOf(33585935, "Dawnguard.esm")
  RegisterScreenshotOf(33584377, "Dawnguard.esm")
  RegisterScreenshotOf(33584376, "Dawnguard.esm")
  RegisterScreenshotOf(33597559, "Dawnguard.esm")
  RegisterScreenshotOf(33605117, "Dawnguard.esm")
  RegisterScreenshotOf(33605109, "Dawnguard.esm")
  RegisterScreenshotOf(33637797, "Dawnguard.esm")
  RegisterScreenshotOf(33663293, "Dawnguard.esm")
  RegisterScreenshotOf(33569703, "Dawnguard.esm")
  RegisterScreenshotOf(33659198, "Dawnguard.esm")
  RegisterScreenshotOf(33570171, "Dawnguard.esm")
  RegisterScreenshotOf(33570053, "Dawnguard.esm")
  RegisterScreenshotOf(33639422, "Dawnguard.esm")
  RegisterScreenshotOf(33639421, "Dawnguard.esm")
  RegisterScreenshotOf(33639420, "Dawnguard.esm")
  RegisterScreenshotOf(33634339, "Dawnguard.esm")
  RegisterScreenshotOf(33659568, "Dawnguard.esm")
  RegisterScreenshotOf(33603420, "Dawnguard.esm")
  RegisterScreenshotOf(33583535, "Dawnguard.esm")
  RegisterScreenshotOf(33572279, "Dawnguard.esm")
  RegisterScreenshotOf(33627742, "Dawnguard.esm")
  RegisterScreenshotOf(33623533, "Dawnguard.esm")
  RegisterScreenshotOf(33658242, "Dawnguard.esm")
  RegisterScreenshotOf(33583601, "Dawnguard.esm")
  RegisterScreenshotOf(33623708, "Dawnguard.esm")
  RegisterScreenshotOf(33627741, "Dawnguard.esm")
  RegisterScreenshotOf(33564714, "Dawnguard.esm")
  RegisterScreenshotOf(33564715, "Dawnguard.esm")
  RegisterScreenshotOf(33590811, "Dawnguard.esm")
  RegisterScreenshotOf(33623527, "Dawnguard.esm")
  RegisterScreenshotOf(33567585, "Dawnguard.esm")
  RegisterScreenshotOf(33589869, "Dawnguard.esm")
  RegisterScreenshotOf(33589868, "Dawnguard.esm")
  RegisterScreenshotOf(33597612, "Dawnguard.esm")
  RegisterScreenshotOf(33597613, "Dawnguard.esm")
  RegisterScreenshotOf(33597616, "Dawnguard.esm")
  RegisterScreenshotOf(33597614, "Dawnguard.esm")
  RegisterScreenshotOf(33565508, "Dawnguard.esm")
  RegisterScreenshotOf(33567586, "Dawnguard.esm")
  RegisterScreenshotOf(33662782, "Dawnguard.esm")
  RegisterScreenshotOf(33588273, "Dawnguard.esm")
  RegisterScreenshotOf(33589371, "Dawnguard.esm")
  RegisterScreenshotOf(33567591, "Dawnguard.esm")
  RegisterScreenshotOf(33659197, "Dawnguard.esm")
  RegisterScreenshotOf(33567593, "Dawnguard.esm")
  RegisterScreenshotOf(33663606, "Dawnguard.esm")
  RegisterScreenshotOf(33565548, "Dawnguard.esm")
  RegisterScreenshotOf(33659127, "Dawnguard.esm")
  RegisterScreenshotOf(33581809, "Dawnguard.esm")
  RegisterScreenshotOf(33581808, "Dawnguard.esm")
  RegisterScreenshotOf(33659569, "Dawnguard.esm")
  RegisterScreenshotOf(33652374, "Dawnguard.esm")
  RegisterScreenshotOf(33652373, "Dawnguard.esm")
  RegisterScreenshotOf(33652372, "Dawnguard.esm")
  RegisterScreenshotOf(33652370, "Dawnguard.esm")
  RegisterScreenshotOf(33606365, "Dawnguard.esm")
  RegisterScreenshotOf(33606363, "Dawnguard.esm")
  RegisterScreenshotOf(33563619, "Dawnguard.esm")
  RegisterScreenshotOf(33567595, "Dawnguard.esm")
  RegisterScreenshotOf(33662213, "Dawnguard.esm")
  RegisterScreenshotOf(33662212, "Dawnguard.esm")
  RegisterScreenshotOf(33662211, "Dawnguard.esm")
  RegisterScreenshotOf(33662210, "Dawnguard.esm")
  RegisterScreenshotOf(33662207, "Dawnguard.esm")
  RegisterScreenshotOf(33662206, "Dawnguard.esm")
  RegisterScreenshotOf(33662205, "Dawnguard.esm")
  RegisterScreenshotOf(33662204, "Dawnguard.esm")
  RegisterScreenshotOf(33662202, "Dawnguard.esm")
  RegisterScreenshotOf(33662201, "Dawnguard.esm")
  RegisterScreenshotOf(33662200, "Dawnguard.esm")
  RegisterScreenshotOf(33662199, "Dawnguard.esm")
  RegisterScreenshotOf(33644588, "Dawnguard.esm")
  RegisterScreenshotOf(33644020, "Dawnguard.esm")
  RegisterScreenshotOf(33644019, "Dawnguard.esm")
  RegisterScreenshotOf(33640630, "Dawnguard.esm")
  RegisterScreenshotOf(33640629, "Dawnguard.esm")
  RegisterScreenshotOf(33640628, "Dawnguard.esm")
  RegisterScreenshotOf(33640627, "Dawnguard.esm")
  RegisterScreenshotOf(33640626, "Dawnguard.esm")
  RegisterScreenshotOf(33640625, "Dawnguard.esm")
  RegisterScreenshotOf(33597702, "Dawnguard.esm")
  RegisterScreenshotOf(33572697, "Dawnguard.esm")
  RegisterScreenshotOf(33565453, "Dawnguard.esm")
  RegisterScreenshotOf(33635188, "Dawnguard.esm")
  RegisterScreenshotOf(33567592, "Dawnguard.esm")
  RegisterScreenshotOf(33586860, "Dawnguard.esm")
  RegisterScreenshotOf(33639419, "Dawnguard.esm")
  RegisterScreenshotOf(33570807, "Dawnguard.esm")
  RegisterScreenshotOf(33581504, "Dawnguard.esm")
  RegisterScreenshotOf(33641473, "Dawnguard.esm")
  RegisterScreenshotOf(33623525, "Dawnguard.esm")
  RegisterScreenshotOf(33571336, "Dawnguard.esm")
  RegisterScreenshotOf(33578572, "Dawnguard.esm")
  RegisterScreenshotOf(33573925, "Dawnguard.esm")
  RegisterScreenshotOf(33578573, "Dawnguard.esm")
  RegisterScreenshotOf(33573924, "Dawnguard.esm")
  RegisterScreenshotOf(33578574, "Dawnguard.esm")
  RegisterScreenshotOf(33573926, "Dawnguard.esm")
  RegisterScreenshotOf(33617815, "Dawnguard.esm")
  RegisterScreenshotOf(33565698, "Dawnguard.esm")
  RegisterScreenshotOf(33624890, "Dawnguard.esm")
  RegisterScreenshotOf(33621564, "Dawnguard.esm")
  RegisterScreenshotOf(33617816, "Dawnguard.esm")
  RegisterScreenshotOf(33569895, "Dawnguard.esm")
  RegisterScreenshotOf(33569675, "Dawnguard.esm")
  RegisterScreenshotOf(33628735, "Dawnguard.esm")
  RegisterScreenshotOf(33628734, "Dawnguard.esm")
  RegisterScreenshotOf(33567957, "Dawnguard.esm")
  RegisterScreenshotOf(33645305, "Dawnguard.esm")
  RegisterScreenshotOf(33613961, "Dawnguard.esm")
  RegisterScreenshotOf(33567603, "Dawnguard.esm")
  RegisterScreenshotOf(33567599, "Dawnguard.esm")
  RegisterScreenshotOf(33571285, "Dawnguard.esm")
  RegisterScreenshotOf(33653668, "Dawnguard.esm")
  RegisterScreenshotOf(33636465, "Dawnguard.esm")
  RegisterScreenshotOf(33636464, "Dawnguard.esm")
  RegisterScreenshotOf(33590568, "Dawnguard.esm")
  RegisterScreenshotOf(33590567, "Dawnguard.esm")
  RegisterScreenshotOf(33570051, "Dawnguard.esm")
  RegisterScreenshotOf(33618739, "Dawnguard.esm")
  RegisterScreenshotOf(33568045, "Dawnguard.esm")
  RegisterScreenshotOf(33567584, "Dawnguard.esm")
  RegisterScreenshotOf(33586888, "Dawnguard.esm")
  RegisterScreenshotOf(33658240, "Dawnguard.esm")
  RegisterScreenshotOf(33623526, "Dawnguard.esm")
  RegisterScreenshotOf(33623705, "Dawnguard.esm")
  RegisterScreenshotOf(33641283, "Dawnguard.esm")
  RegisterScreenshotOf(33641291, "Dawnguard.esm")
  RegisterScreenshotOf(33661974, "Dawnguard.esm")
  RegisterScreenshotOf(33663215, "Dawnguard.esm")
  RegisterScreenshotOf(33614769, "Dawnguard.esm")
  RegisterScreenshotOf(33662406, "Dawnguard.esm")
  RegisterScreenshotOf(33583533, "Dawnguard.esm")
  RegisterScreenshotOf(33572276, "Dawnguard.esm")
  RegisterScreenshotOf(33572213, "Dawnguard.esm")
  RegisterScreenshotOf(33570876, "HearthFires.esm")
  RegisterScreenshotOf(33634329, "HearthFires.esm")
  RegisterScreenshotOf(33570646, "HearthFires.esm")
  RegisterScreenshotOf(33634327, "HearthFires.esm")
  RegisterScreenshotOf(33603090, "HearthFires.esm")
  RegisterScreenshotOf(33556749, "HearthFires.esm")
  RegisterScreenshotOf(33575454, "HearthFires.esm")
  RegisterScreenshotOf(33567408, "HearthFires.esm")
  RegisterScreenshotOf(33623998, "HearthFires.esm")
  RegisterScreenshotOf(33623995, "HearthFires.esm")
  RegisterScreenshotOf(33618344, "HearthFires.esm")
  RegisterScreenshotOf(33634330, "HearthFires.esm")
  RegisterScreenshotOf(33656288, "HearthFires.esm")
  RegisterScreenshotOf(33570655, "HearthFires.esm")
  RegisterScreenshotOf(33623994, "HearthFires.esm")
  RegisterScreenshotOf(33658417, "HearthFires.esm")
  RegisterScreenshotOf(33634328, "HearthFires.esm")
  RegisterScreenshotOf(33587784, "HearthFires.esm")
  RegisterScreenshotOf(33575445, "HearthFires.esm")
  RegisterScreenshotOf(33570875, "HearthFires.esm")
  RegisterScreenshotOf(33658416, "HearthFires.esm")
  RegisterScreenshotOf(33575451, "HearthFires.esm")
  RegisterScreenshotOf(33634331, "HearthFires.esm")
  RegisterScreenshotOf(33653376, "Dragonborn.esm")
  RegisterScreenshotOf(33656211, "Dragonborn.esm")
  RegisterScreenshotOf(33656778, "Dragonborn.esm")
  RegisterScreenshotOf(33704169, "Dragonborn.esm")
  RegisterScreenshotOf(33683907, "Dragonborn.esm")
  RegisterScreenshotOf(33657452, "Dragonborn.esm")
  RegisterScreenshotOf(33648756, "Dragonborn.esm")
  RegisterScreenshotOf(33637829, "Dragonborn.esm")
  RegisterScreenshotOf(33671923, "Dragonborn.esm")
  RegisterScreenshotOf(33711530, "Dragonborn.esm")
  RegisterScreenshotOf(33653372, "Dragonborn.esm")
  RegisterScreenshotOf(33754326, "Dragonborn.esm")
  RegisterScreenshotOf(33754324, "Dragonborn.esm")
  RegisterScreenshotOf(33676252, "Dragonborn.esm")
  RegisterScreenshotOf(33663663, "Dragonborn.esm")
  RegisterScreenshotOf(33666647, "Dragonborn.esm")
  RegisterScreenshotOf(33659600, "Dragonborn.esm")
  RegisterScreenshotOf(33672696, "Dragonborn.esm")
  RegisterScreenshotOf(33666614, "Dragonborn.esm")
  RegisterScreenshotOf(33662312, "Dragonborn.esm")
  RegisterScreenshotOf(33666618, "Dragonborn.esm")
  RegisterScreenshotOf(33666617, "Dragonborn.esm")
  RegisterScreenshotOf(33684987, "Dragonborn.esm")
  RegisterScreenshotOf(33764955, "Dragonborn.esm")
  RegisterScreenshotOf(33801049, "Dragonborn.esm")
  RegisterScreenshotOf(33681785, "Dragonborn.esm")
  RegisterScreenshotOf(33795023, "Dragonborn.esm")
  RegisterScreenshotOf(33789929, "Dragonborn.esm")
  RegisterScreenshotOf(33712964, "Dragonborn.esm")
  RegisterScreenshotOf(33805704, "Dragonborn.esm")
  RegisterScreenshotOf(33805705, "Dragonborn.esm")
  RegisterScreenshotOf(33771482, "Dragonborn.esm")
  RegisterScreenshotOf(33797477, "Dragonborn.esm")
  RegisterScreenshotOf(33677968, "Dragonborn.esm")
  RegisterScreenshotOf(33656757, "Dragonborn.esm")
  RegisterScreenshotOf(33716265, "Dragonborn.esm")
  RegisterScreenshotOf(33666633, "Dragonborn.esm")
  RegisterScreenshotOf(33681801, "Dragonborn.esm")
  RegisterScreenshotOf(33731126, "Dragonborn.esm")
  RegisterScreenshotOf(33716206, "Dragonborn.esm")
  RegisterScreenshotOf(33656597, "Dragonborn.esm")
  RegisterScreenshotOf(33701947, "Dragonborn.esm")
  RegisterScreenshotOf(33662225, "Dragonborn.esm")
  RegisterScreenshotOf(33719678, "Dragonborn.esm")
  RegisterScreenshotOf(33791962, "Dragonborn.esm")
  RegisterScreenshotOf(33666623, "Dragonborn.esm")
  RegisterScreenshotOf(33653420, "Dragonborn.esm")
  RegisterScreenshotOf(33714536, "Dragonborn.esm")
  RegisterScreenshotOf(33653378, "Dragonborn.esm")
  RegisterScreenshotOf(33710963, "Dragonborn.esm")
  RegisterScreenshotOf(33653368, "Dragonborn.esm")
  RegisterScreenshotOf(33754322, "Dragonborn.esm")
  RegisterScreenshotOf(33754321, "Dragonborn.esm")
  RegisterScreenshotOf(33754323, "Dragonborn.esm")
  RegisterScreenshotOf(33656741, "Dragonborn.esm")
  RegisterScreenshotOf(33658391, "Dragonborn.esm")
  RegisterScreenshotOf(33793151, "Dragonborn.esm")
  RegisterScreenshotOf(33734459, "Dragonborn.esm")
  RegisterScreenshotOf(33651234, "Dragonborn.esm")
  RegisterScreenshotOf(33653831, "Dragonborn.esm")
  RegisterScreenshotOf(33685280, "Dragonborn.esm")
  RegisterScreenshotOf(33681073, "Dragonborn.esm")
  RegisterScreenshotOf(33653396, "Dragonborn.esm")
  RegisterScreenshotOf(33650553, "Dragonborn.esm")
  RegisterScreenshotOf(33704161, "Dragonborn.esm")
  RegisterScreenshotOf(33763920, "Dragonborn.esm")
  RegisterScreenshotOf(33763921, "Dragonborn.esm")
  RegisterScreenshotOf(33763922, "Dragonborn.esm")
  RegisterScreenshotOf(33730585, "Dragonborn.esm")
  RegisterScreenshotOf(33719747, "Dragonborn.esm")
  RegisterScreenshotOf(33656765, "Dragonborn.esm")
  RegisterScreenshotOf(33653386, "Dragonborn.esm")
  RegisterScreenshotOf(33662234, "Dragonborn.esm")
  RegisterScreenshotOf(33650552, "Dragonborn.esm")
  RegisterScreenshotOf(33729840, "Dragonborn.esm")
  RegisterScreenshotOf(33778157, "Dragonborn.esm")
  RegisterScreenshotOf(33791248, "Dragonborn.esm")
  RegisterScreenshotOf(33797440, "Dragonborn.esm")
  RegisterScreenshotOf(33757282, "Dragonborn.esm")
  RegisterScreenshotOf(33778158, "Dragonborn.esm")
  RegisterScreenshotOf(33656773, "Dragonborn.esm")
  RegisterScreenshotOf(33653394, "Dragonborn.esm")
  RegisterScreenshotOf(33656732, "Dragonborn.esm")
  RegisterScreenshotOf(33683856, "Dragonborn.esm")
  RegisterScreenshotOf(33658153, "Dragonborn.esm")
  RegisterScreenshotOf(33648759, "Dragonborn.esm")
  RegisterScreenshotOf(33650996, "Dragonborn.esm")
  RegisterScreenshotOf(33687265, "Dragonborn.esm")
  RegisterScreenshotOf(33687260, "Dragonborn.esm")
  RegisterScreenshotOf(33671894, "Dragonborn.esm")
  RegisterScreenshotOf(33677217, "Dragonborn.esm")
  RegisterScreenshotOf(33653388, "Dragonborn.esm")
  RegisterScreenshotOf(33783779, "Dragonborn.esm")
  RegisterScreenshotOf(33653407, "Dragonborn.esm")
  RegisterScreenshotOf(33653392, "Dragonborn.esm")
  RegisterScreenshotOf(33662308, "Dragonborn.esm")
  RegisterScreenshotOf(33653422, "Dragonborn.esm")
  RegisterScreenshotOf(33653390, "Dragonborn.esm")
  RegisterScreenshotOf(33715349, "Dragonborn.esm")
  RegisterScreenshotOf(33715326, "Dragonborn.esm")
  RegisterScreenshotOf(33688109, "Dragonborn.esm")
  RegisterScreenshotOf(33661811, "Dragonborn.esm")
  RegisterScreenshotOf(33656283, "Dragonborn.esm")
  RegisterScreenshotOf(33783820, "Dragonborn.esm")
  RegisterScreenshotOf(33783819, "Dragonborn.esm")
  RegisterScreenshotOf(33783818, "Dragonborn.esm")
  RegisterScreenshotOf(33783817, "Dragonborn.esm")
  RegisterScreenshotOf(33783816, "Dragonborn.esm")
  RegisterScreenshotOf(33783815, "Dragonborn.esm")
  RegisterScreenshotOf(33783814, "Dragonborn.esm")
  RegisterScreenshotOf(33783813, "Dragonborn.esm")
  RegisterScreenshotOf(33783812, "Dragonborn.esm")
  RegisterScreenshotOf(33783811, "Dragonborn.esm")
  RegisterScreenshotOf(33783810, "Dragonborn.esm")
  RegisterScreenshotOf(33783809, "Dragonborn.esm")
  RegisterScreenshotOf(33783807, "Dragonborn.esm")
  RegisterScreenshotOf(33783806, "Dragonborn.esm")
  RegisterScreenshotOf(33783805, "Dragonborn.esm")
  RegisterScreenshotOf(33783804, "Dragonborn.esm")
  RegisterScreenshotOf(33783803, "Dragonborn.esm")
  RegisterScreenshotOf(33783802, "Dragonborn.esm")
  RegisterScreenshotOf(33783801, "Dragonborn.esm")
  RegisterScreenshotOf(33783800, "Dragonborn.esm")
  RegisterScreenshotOf(33783799, "Dragonborn.esm")
  RegisterScreenshotOf(33783798, "Dragonborn.esm")
  RegisterScreenshotOf(33783797, "Dragonborn.esm")
  RegisterScreenshotOf(33783796, "Dragonborn.esm")
  RegisterScreenshotOf(33662236, "Dragonborn.esm")
  RegisterScreenshotOf(33786221, "Dragonborn.esm")
  RegisterScreenshotOf(33685306, "Dragonborn.esm")
  RegisterScreenshotOf(33754334, "Dragonborn.esm")
  RegisterScreenshotOf(33721987, "Dragonborn.esm")
  RegisterScreenshotOf(33662229, "Dragonborn.esm")
  RegisterScreenshotOf(33714445, "Dragonborn.esm")
  RegisterScreenshotOf(33683908, "Dragonborn.esm")
  RegisterScreenshotOf(33666622, "Dragonborn.esm")
  RegisterScreenshotOf(33785995, "Dragonborn.esm")
  RegisterScreenshotOf(33675653, "Dragonborn.esm")
  RegisterScreenshotOf(33728254, "Dragonborn.esm")
  RegisterScreenshotOf(33770330, "Dragonborn.esm")
  RegisterScreenshotOf(33757253, "Dragonborn.esm")
  RegisterScreenshotOf(33718854, "Dragonborn.esm")
  RegisterScreenshotOf(33650491, "Dragonborn.esm")
  RegisterScreenshotOf(33637520, "Dragonborn.esm")
  RegisterScreenshotOf(33778156, "Dragonborn.esm")
  RegisterScreenshotOf(33637521, "Dragonborn.esm")
  RegisterScreenshotOf(33637498, "Dragonborn.esm")
  RegisterScreenshotOf(33687261, "Dragonborn.esm")
  RegisterScreenshotOf(33677292, "Dragonborn.esm")
  RegisterScreenshotOf(33637515, "Dragonborn.esm")
  RegisterScreenshotOf(33637447, "Dragonborn.esm")
  RegisterScreenshotOf(33687902, "Dragonborn.esm")
  RegisterScreenshotOf(33677293, "Dragonborn.esm")
  RegisterScreenshotOf(33658469, "Dragonborn.esm")
  RegisterScreenshotOf(33716229, "Dragonborn.esm")
  RegisterScreenshotOf(33716228, "Dragonborn.esm")
  RegisterScreenshotOf(33716227, "Dragonborn.esm")
  RegisterScreenshotOf(33716220, "Dragonborn.esm")
  RegisterScreenshotOf(33652615, "Dragonborn.esm")
  RegisterScreenshotOf(33662232, "Dragonborn.esm")
  RegisterScreenshotOf(33716267, "Dragonborn.esm")
  RegisterScreenshotOf(33653374, "Dragonborn.esm")
  RegisterScreenshotOf(33710486, "Dragonborn.esm")
  RegisterScreenshotOf(33666624, "Dragonborn.esm")
  RegisterScreenshotOf(33637524, "Dragonborn.esm")
  RegisterScreenshotOf(33666625, "Dragonborn.esm")
  RegisterScreenshotOf(33666626, "Dragonborn.esm")
  RegisterScreenshotOf(33666629, "Dragonborn.esm")
  RegisterScreenshotOf(33781493, "Dragonborn.esm")
  RegisterScreenshotOf(33781490, "Dragonborn.esm")
  RegisterScreenshotOf(33716757, "Dragonborn.esm")
  RegisterScreenshotOf(33676391, "Dragonborn.esm")
  RegisterScreenshotOf(33754325, "Dragonborn.esm")
  RegisterScreenshotOf(33754270, "Dragonborn.esm")
  RegisterScreenshotOf(33791254, "Dragonborn.esm")
  RegisterScreenshotOf(33671848, "Dragonborn.esm")
  RegisterScreenshotOf(33688135, "Dragonborn.esm")
  RegisterScreenshotOf(33653409, "Dragonborn.esm")
  RegisterScreenshotOf(33716223, "Dragonborn.esm")
  RegisterScreenshotOf(33716222, "Dragonborn.esm")
  RegisterScreenshotOf(33716221, "Dragonborn.esm")
  RegisterScreenshotOf(33716219, "Dragonborn.esm")
  RegisterScreenshotOf(33716218, "Dragonborn.esm")
  RegisterScreenshotOf(33716217, "Dragonborn.esm")
  RegisterScreenshotOf(33716216, "Dragonborn.esm")
  RegisterScreenshotOf(33716204, "Dragonborn.esm")
  RegisterScreenshotOf(33684376, "Dragonborn.esm")
  RegisterScreenshotOf(33652605, "Dragonborn.esm")
  RegisterScreenshotOf(33650998, "Dragonborn.esm")
  RegisterScreenshotOf(33716207, "Dragonborn.esm")
  RegisterScreenshotOf(33653384, "Dragonborn.esm")
  RegisterScreenshotOf(33658266, "Dragonborn.esm")
  RegisterScreenshotOf(33714628, "Dragonborn.esm")
  RegisterScreenshotOf(33714627, "Dragonborn.esm")
  RegisterScreenshotOf(33656745, "Dragonborn.esm")
  RegisterScreenshotOf(33770321, "Dragonborn.esm")
  RegisterScreenshotOf(33651153, "Dragonborn.esm")
  RegisterScreenshotOf(33791252, "Dragonborn.esm")
  RegisterScreenshotOf(33650490, "Dragonborn.esm")
  RegisterScreenshotOf(33691451, "Dragonborn.esm")
  RegisterScreenshotOf(33719679, "Dragonborn.esm")
  RegisterScreenshotOf(33656769, "Dragonborn.esm")
  RegisterScreenshotOf(33717826, "Dragonborn.esm")
  RegisterScreenshotOf(33715354, "Dragonborn.esm")
  RegisterScreenshotOf(33675774, "Dragonborn.esm")
  RegisterScreenshotOf(33675130, "Dragonborn.esm")
  RegisterScreenshotOf(33656729, "Dragonborn.esm")
  RegisterScreenshotOf(33715360, "Dragonborn.esm")
  RegisterScreenshotOf(33715330, "Dragonborn.esm")
  RegisterScreenshotOf(33716269, "Dragonborn.esm")
  RegisterScreenshotOf(33789730, "Dragonborn.esm")
  RegisterScreenshotOf(33701899, "Dragonborn.esm")
  RegisterScreenshotOf(33701898, "Dragonborn.esm")
  RegisterScreenshotOf(33781717, "Dragonborn.esm")
  RegisterScreenshotOf(33671854, "Dragonborn.esm")
  RegisterScreenshotOf(33671853, "Dragonborn.esm")
  RegisterScreenshotOf(33683909, "Dragonborn.esm")
  RegisterScreenshotOf(33773343, "Dragonborn.esm")
  RegisterScreenshotOf(33651143, "Dragonborn.esm")
  RegisterScreenshotOf(33760768, "Dragonborn.esm")
  RegisterScreenshotOf(33679364, "Dragonborn.esm")
  RegisterScreenshotOf(33679415, "Dragonborn.esm")
  RegisterScreenshotOf(33679414, "Dragonborn.esm")
  RegisterScreenshotOf(33679413, "Dragonborn.esm")
  RegisterScreenshotOf(33784172, "Dragonborn.esm")
  RegisterScreenshotOf(33760766, "Dragonborn.esm")
  RegisterScreenshotOf(33663532, "Dragonborn.esm")
  RegisterScreenshotOf(33679421, "Dragonborn.esm")
  RegisterScreenshotOf(33679420, "Dragonborn.esm")
  RegisterScreenshotOf(33679419, "Dragonborn.esm")
  RegisterScreenshotOf(33679391, "Dragonborn.esm")
  RegisterScreenshotOf(33679390, "Dragonborn.esm")
  RegisterScreenshotOf(33679389, "Dragonborn.esm")
  RegisterScreenshotOf(33679418, "Dragonborn.esm")
  RegisterScreenshotOf(33679417, "Dragonborn.esm")
  RegisterScreenshotOf(33679416, "Dragonborn.esm")
  RegisterScreenshotOf(33679412, "Dragonborn.esm")
  RegisterScreenshotOf(33679411, "Dragonborn.esm")
  RegisterScreenshotOf(33679410, "Dragonborn.esm")
  RegisterScreenshotOf(33658287, "Dragonborn.esm")
  RegisterScreenshotOf(33735147, "Dragonborn.esm")
  RegisterScreenshotOf(33652551, "Dragonborn.esm")
  RegisterScreenshotOf(33804263, "Dragonborn.esm")
  RegisterScreenshotOf(33662216, "Dragonborn.esm")
  RegisterScreenshotOf(33804262, "Dragonborn.esm")
  RegisterScreenshotOf(33666639, "Dragonborn.esm")
  RegisterScreenshotOf(33804261, "Dragonborn.esm")
  RegisterScreenshotOf(33666638, "Dragonborn.esm")
  RegisterScreenshotOf(33803171, "Dragonborn.esm")
  RegisterScreenshotOf(33656596, "Dragonborn.esm")
  RegisterScreenshotOf(33777585, "Dragonborn.esm")
  RegisterScreenshotOf(33711289, "Dragonborn.esm")
  RegisterScreenshotOf(33790827, "Dragonborn.esm")
  RegisterScreenshotOf(33701755, "Dragonborn.esm")
  RegisterScreenshotOf(33721983, "Dragonborn.esm")
  RegisterScreenshotOf(33681097, "Dragonborn.esm")
  RegisterScreenshotOf(33676474, "Dragonborn.esm")
  RegisterScreenshotOf(33775924, "Dragonborn.esm")
  RegisterScreenshotOf(33775923, "Dragonborn.esm")
  RegisterScreenshotOf(33775918, "Dragonborn.esm")
  RegisterScreenshotOf(33736842, "Dragonborn.esm")
  RegisterScreenshotOf(33671846, "Dragonborn.esm")
  RegisterScreenshotOf(33687901, "Dragonborn.esm")
  RegisterScreenshotOf(33687900, "Dragonborn.esm")
  RegisterScreenshotOf(33786216, "Dragonborn.esm")
  RegisterScreenshotOf(33658262, "Dragonborn.esm")
  RegisterScreenshotOf(33781494, "Dragonborn.esm")
  RegisterScreenshotOf(33781492, "Dragonborn.esm")
  RegisterScreenshotOf(33708772, "Dragonborn.esm")
  RegisterScreenshotOf(33711537, "Dragonborn.esm")
  RegisterScreenshotOf(33791959, "Dragonborn.esm")
  RegisterScreenshotOf(33758613, "Dragonborn.esm")
  RegisterScreenshotOf(33758612, "Dragonborn.esm")
  RegisterScreenshotOf(33650997, "Dragonborn.esm")
  RegisterScreenshotOf(33650551, "Dragonborn.esm")
  RegisterScreenshotOf(33785184, "Dragonborn.esm")
  RegisterScreenshotOf(33711672, "Dragonborn.esm")
  RegisterScreenshotOf(33711671, "Dragonborn.esm")
  RegisterScreenshotOf(33653548, "Dragonborn.esm")
  RegisterScreenshotOf(33783781, "Dragonborn.esm")
  RegisterScreenshotOf(33656776, "Dragonborn.esm")
  RegisterScreenshotOf(33653382, "Dragonborn.esm")
  RegisterScreenshotOf(33791256, "Dragonborn.esm")
  RegisterScreenshotOf(33767460, "Dragonborn.esm")
  RegisterScreenshotOf(33781724, "Dragonborn.esm")
  RegisterScreenshotOf(33781723, "Dragonborn.esm")
  RegisterScreenshotOf(33650557, "Dragonborn.esm")
  RegisterScreenshotOf(33762543, "Dragonborn.esm")
  RegisterScreenshotOf(33772414, "Dragonborn.esm")
  RegisterScreenshotOf(33671893, "Dragonborn.esm")
  RegisterScreenshotOf(33650556, "Dragonborn.esm")
  RegisterScreenshotOf(33653380, "Dragonborn.esm")
  RegisterScreenshotOf(33805018, "Dragonborn.esm")
  RegisterScreenshotOf(33805017, "Dragonborn.esm")
  RegisterScreenshotOf(33804833, "Dragonborn.esm")
  RegisterScreenshotOf(33804832, "Dragonborn.esm")
  RegisterScreenshotOf(33804831, "Dragonborn.esm")
  RegisterScreenshotOf(33759923, "Dragonborn.esm")
  RegisterScreenshotOf(33759921, "Dragonborn.esm")
  RegisterScreenshotOf(33677692, "Dragonborn.esm")
  RegisterScreenshotOf(33689537, "Dragonborn.esm")
  RegisterScreenshotOf(33656750, "Dragonborn.esm")
  RegisterScreenshotOf(33656761, "Dragonborn.esm")
  RegisterScreenshotOf(33704168, "Dragonborn.esm")
endFunction

; Screenshot various NPCs from Skyrim Vanilla
; This run for about 30 mins
; It is based on the list provided here: https://www.pcgamer.com/skyrim-npc-codes/
function RegisterVariousSkyrimNPCs()
  ; Acolyte Jenssen
  RegisterScreenshotOf(0x000D3E79, "Skyrim.esm")
  ; Adara
  RegisterScreenshotOf(0x00013385, "Skyrim.esm")
  ; Addvar
  RegisterScreenshotOf(0x00013255, "Skyrim.esm")
  ; Addvild
  RegisterScreenshotOf(0x00019DC7, "Skyrim.esm")
  ; Adeber
  RegisterScreenshotOf(0x000661AD, "Skyrim.esm")
  ; Adelaisa Vendicci
  RegisterScreenshotOf(0x0001411D, "Skyrim.esm")
  ; Adisla
  RegisterScreenshotOf(0x0001411E, "Skyrim.esm")
  ; Adonato Leotelli
  RegisterScreenshotOf(0x0001413C, "Skyrim.esm")
  ; Adrianne Avenicci
  RegisterScreenshotOf(0x00013BB9, "Skyrim.esm")
  ; Aduri Sarethi
  RegisterScreenshotOf(0x00019BFF, "Skyrim.esm")
  ; Aela the Huntress
  RegisterScreenshotOf(0x0001A696, "Skyrim.esm")
  ; Aeri
  RegisterScreenshotOf(0x0001360B, "Skyrim.esm")
  ; Aerin
  RegisterScreenshotOf(0x00013346, "Skyrim.esm")
  ; Agni
  RegisterScreenshotOf(0x000135E5, "Skyrim.esm")
  ; Agnis
  RegisterScreenshotOf(0x00020044, "Skyrim.esm")
  ; Ahjisi
  RegisterScreenshotOf(0x000CE086, "Skyrim.esm")
  ; Ahkari
  RegisterScreenshotOf(0x0001B1D6, "Skyrim.esm")
  ; Ahlam
  RegisterScreenshotOf(0x00013BBE, "Skyrim.esm")
  ; Ahtar the Jailor
  RegisterScreenshotOf(0x0001325F, "Skyrim.esm")
  ; Aia Arria
  RegisterScreenshotOf(0x0001325C, "Skyrim.esm")
  ; Aicantar
  RegisterScreenshotOf(0x0001402E, "Skyrim.esm")
  ; Ainethach
  RegisterScreenshotOf(0x00013B69, "Skyrim.esm")
  ; Alain Dufont
  RegisterScreenshotOf(0x0001B074, "Skyrim.esm")
  ; Alduin (As he appears in the quest A Blade in the Dark)
  RegisterScreenshotOf(0x00032D9D, "Skyrim.esm")
  ; Alea Quintus
  RegisterScreenshotOf(0x0002E3EF, "Skyrim.esm")
  ; Alessandra
  RegisterScreenshotOf(0x00013347, "Skyrim.esm")
  ; Alfarinn
  RegisterScreenshotOf(0x0009B7AB, "Skyrim.esm")
  ; Alfhild Battle-Born
  RegisterScreenshotOf(0x00013BB0, "Skyrim.esm")
  ; Alva
  RegisterScreenshotOf(0x000135E6, "Skyrim.esm")
  ; Alvor
  RegisterScreenshotOf(0x00013475, "Skyrim.esm")
  ; Amaund Motierre
  RegisterScreenshotOf(0x0003B43A, "Skyrim.esm")
  ; Ambarys Rendar
  RegisterScreenshotOf(0x0001413E, "Skyrim.esm")
  ; Amren
  RegisterScreenshotOf(0x00013BAA, "Skyrim.esm")
  ; Ancano
  RegisterScreenshotOf(0x0001E7D7, "Skyrim.esm")
  ; Andurs
  RegisterScreenshotOf(0x00013BA8, "Skyrim.esm")
  ; Angeline Morrard
  RegisterScreenshotOf(0x00013260, "Skyrim.esm")
  ; Angi
  RegisterScreenshotOf(0x000CAB2F, "Skyrim.esm")
  ; Angrenor Once-Honored
  RegisterScreenshotOf(0x00014137, "Skyrim.esm")
  ; Anise
  RegisterScreenshotOf(0x000DDF86, "Skyrim.esm")
  ; Annekke Crag-Jumper
  RegisterScreenshotOf(0x00013666, "Skyrim.esm")
  ; Anoriath
  RegisterScreenshotOf(0x00013B97, "Skyrim.esm")
  ; Anska
  RegisterScreenshotOf(0x000443F3, "Skyrim.esm")
  ; Anton Virane
  RegisterScreenshotOf(0x00013387, "Skyrim.esm")
  ; Anuriel
  RegisterScreenshotOf(0x00013349, "Skyrim.esm")
  ; Anwen
  RegisterScreenshotOf(0x00013386, "Skyrim.esm")
  ; Aranea Ienith
  RegisterScreenshotOf(0x00028AD0, "Skyrim.esm")
  ; Arcadia
  RegisterScreenshotOf(0x00013BA4, "Skyrim.esm")
  ; Arcturus
  RegisterScreenshotOf(0x0004D6CA, "Skyrim.esm")
  ; Argis the Bulwark
  RegisterScreenshotOf(0x000A2C8C, "Skyrim.esm")
  ; Ari
  RegisterScreenshotOf(0x000411CF, "Skyrim.esm")
  ; Aringoth
  RegisterScreenshotOf(0x0001334A, "Skyrim.esm")
  ; Arivanya
  RegisterScreenshotOf(0x00014127, "Skyrim.esm")
  ; Arnbjorn
  RegisterScreenshotOf(0x0001BDB0, "Skyrim.esm")
  ; Arngeir
  RegisterScreenshotOf(0x0002C6C7, "Skyrim.esm")
  ; Arniel Gane
  RegisterScreenshotOf(0x0001C19D, "Skyrim.esm")
  ; Arnskar Ember-Master
  RegisterScreenshotOf(0x00029DAD, "Skyrim.esm")
  ; Arob
  RegisterScreenshotOf(0x00013B7B, "Skyrim.esm")
  ; Arondil
  RegisterScreenshotOf(0x00037D80, "Skyrim.esm")
  ; Arvel the Swift
  RegisterScreenshotOf(0x00039646, "Skyrim.esm")
  ; Asbjorn Fire-Tamer#
  RegisterScreenshotOf(0x00019DF2, "Skyrim.esm")
  ; Asgeir Snow-Shod
  RegisterScreenshotOf(0x0001334B, "Skyrim.esm")
  ; Aslfur
  RegisterScreenshotOf(0x000135E7, "Skyrim.esm")
  ; Assur
  RegisterScreenshotOf(0x0001C18A, "Skyrim.esm")
  ; Asta
  RegisterScreenshotOf(0x00015D2B, "Skyrim.esm")
  ; Astrid
  RegisterScreenshotOf(0x0001BDB4, "Skyrim.esm")
  ; Ataf
  RegisterScreenshotOf(0x00013295, "Skyrim.esm")
  ; Atahba
  RegisterScreenshotOf(0x0001B1DA, "Skyrim.esm")
  ; Atar
  RegisterScreenshotOf(0x000622E5, "Skyrim.esm")
  ; Athis
  RegisterScreenshotOf(0x0001A6D5, "Skyrim.esm")
  ; Atub
  RegisterScreenshotOf(0x00019E18, "Skyrim.esm")
  ; Aval Atheron
  RegisterScreenshotOf(0x00014140, "Skyrim.esm")
  ; Aventus Aretino
  RegisterScreenshotOf(0x00014132, "Skyrim.esm")
  ; Avrusa Sarethi
  RegisterScreenshotOf(0x00019BFE, "Skyrim.esm")
  ; Avulstein Gray-Mane
  RegisterScreenshotOf(0x00013B9A, "Skyrim.esm")
  ; Azzada Lylvieve
  RegisterScreenshotOf(0x00019A2A, "Skyrim.esm")
  ; Azzadal
  RegisterScreenshotOf(0x000B3C81, "Skyrim.esm")
  ; Babette
  RegisterScreenshotOf(0x0001D4B7, "Skyrim.esm")
  ; Bagrak
  RegisterScreenshotOf(0x00019955, "Skyrim.esm")
  ; Balagog gro-Nolob
  RegisterScreenshotOf(0x00038C6E, "Skyrim.esm")
  ; Balgruuf the Greater
  RegisterScreenshotOf(0x00013BBD, "Skyrim.esm")
  ; Balimund
  RegisterScreenshotOf(0x0001334C, "Skyrim.esm")
  ; Banning
  RegisterScreenshotOf(0x0009A7A8, "Skyrim.esm")
  ; Barbas
  RegisterScreenshotOf(0x0001BFC5, "Skyrim.esm")
  ; Bashnag
  RegisterScreenshotOf(0x000A33EA, "Skyrim.esm")
  ; Bassianus
  RegisterScreenshotOf(0x000136C1, "Skyrim.esm")
  ; Batum gra-Bar
  RegisterScreenshotOf(0x000CE09C, "Skyrim.esm")
  ; Beirand
  RegisterScreenshotOf(0x00013261, "Skyrim.esm")
  ; Beitild Iron-Breaker
  RegisterScreenshotOf(0x00013612, "Skyrim.esm")
  ; Belchimac
  RegisterScreenshotOf(0x00013B6B, "Skyrim.esm")
  ; Belethor
  RegisterScreenshotOf(0x00013BA1, "Skyrim.esm")
  ; Belrand
  RegisterScreenshotOf(0x000B9981, "Skyrim.esm")
  ; Belyn Hlaalu
  RegisterScreenshotOf(0x00014138, "Skyrim.esm")
  ; Bendt
  RegisterScreenshotOf(0x000E77CB, "Skyrim.esm")
  ; Benor
  RegisterScreenshotOf(0x000135E8, "Skyrim.esm")
  ; Bergritte Battle-Born
  RegisterScreenshotOf(0x00013BB3, "Skyrim.esm")
  ; Bersi Honey-Hand
  RegisterScreenshotOf(0x0001334D, "Skyrim.esm")
  ; Betrid Silver-Blood
  RegisterScreenshotOf(0x00013388, "Skyrim.esm")
  ; Birna
  RegisterScreenshotOf(0x0001C187, "Skyrim.esm")
  ; Bjorlam
  RegisterScreenshotOf(0x00013669, "Skyrim.esm")
  ; Bolar
  RegisterScreenshotOf(0x0001B076, "Skyrim.esm")
  ; Bolfrida
  RegisterScreenshotOf(0x00014126, "Skyrim.esm")
  ; Bolgeir Bearclaw
  RegisterScreenshotOf(0x00013264, "Skyrim.esm")
  ; Bolli
  RegisterScreenshotOf(0x0001334E, "Skyrim.esm")
  ; Bolund
  RegisterScreenshotOf(0x00013651, "Skyrim.esm")
  ; Bor
  RegisterScreenshotOf(0x000C78E1, "Skyrim.esm")
  ; Borgakh the Steel Heart
  RegisterScreenshotOf(0x00019959, "Skyrim.esm")
  ; Borgny
  RegisterScreenshotOf(0x000877B2, "Skyrim.esm")
  ; Borkul the Beast
  RegisterScreenshotOf(0x0001338A, "Skyrim.esm")
  ; Borri
  RegisterScreenshotOf(0x0002C6CE, "Skyrim.esm")
  ; Bothela
  RegisterScreenshotOf(0x0001338B, "Skyrim.esm")
  ; Boti
  RegisterScreenshotOf(0x000136BE, "Skyrim.esm")
  ; Braig
  RegisterScreenshotOf(0x00013389, "Skyrim.esm")
  ; Braith
  RegisterScreenshotOf(0x00013BA9, "Skyrim.esm")
  ; Brand-Shei
  RegisterScreenshotOf(0x0001334F, "Skyrim.esm")
  ; Brandish
  RegisterScreenshotOf(0x000CD64C, "Skyrim.esm")
  ; Brelas
  RegisterScreenshotOf(0x00069F38, "Skyrim.esm")
  ; Brelyna Maryon
  RegisterScreenshotOf(0x0001C196, "Skyrim.esm")
  ; Brill
  RegisterScreenshotOf(0x0001A6A2, "Skyrim.esm")
  ; Brina Merilis
  RegisterScreenshotOf(0x0001A6B7, "Skyrim.esm")
  ; Britte
  RegisterScreenshotOf(0x000136B9, "Skyrim.esm")
  ; Brother Verulus
  RegisterScreenshotOf(0x0001338C, "Skyrim.esm")
  ; Brunwulf Free-Winter
  RegisterScreenshotOf(0x00014149, "Skyrim.esm")
  ; Bryling
  RegisterScreenshotOf(0x00013265, "Skyrim.esm")
  ; Brynjolf
  RegisterScreenshotOf(0x0001B07D, "Skyrim.esm")
  ; Bulfrek
  RegisterScreenshotOf(0x00013613, "Skyrim.esm")
  ; Burguk
  RegisterScreenshotOf(0x00013B79, "Skyrim.esm")
  ; Cairine
  RegisterScreenshotOf(0x000D66FE, "Skyrim.esm")
  ; Calcelmo
  RegisterScreenshotOf(0x0001338E, "Skyrim.esm")
  ; Calder
  RegisterScreenshotOf(0x000A2C90, "Skyrim.esm")
  ; Calixto Corrium
  RegisterScreenshotOf(0x0001414A, "Skyrim.esm")
  ; Camilla Valerius
  RegisterScreenshotOf(0x0001347B, "Skyrim.esm")
  ; Captain Aldis
  RegisterScreenshotOf(0x00041FB8, "Skyrim.esm")
  ; Captain Avidius
  RegisterScreenshotOf(0x000C603D, "Skyrim.esm")
  ; Captain Hargar
  RegisterScreenshotOf(0x0001E38B, "Skyrim.esm")
  ; Captain Lief Wayfinder
  RegisterScreenshotOf(0x00013296, "Skyrim.esm")
  ; Captain Lonely-Gale
  RegisterScreenshotOf(0x00014134, "Skyrim.esm")
  ; Carlotta Valentia
  RegisterScreenshotOf(0x00013B99, "Skyrim.esm")
  ; Chief Larak
  RegisterScreenshotOf(0x00019951, "Skyrim.esm")
  ; Chief Mauhulakh
  RegisterScreenshotOf(0x0001B075, "Skyrim.esm")
  ; Chief Yamarz
  RegisterScreenshotOf(0x0003BC26, "Skyrim.esm")
  ; Christer
  RegisterScreenshotOf(0x00090738, "Skyrim.esm")
  ; Cicero
  RegisterScreenshotOf(0x000550F0, "Skyrim.esm")
  ; Clinton Lylvieve
  RegisterScreenshotOf(0x00019A2C, "Skyrim.esm")
  ; Colette Marence
  RegisterScreenshotOf(0x0001C19A, "Skyrim.esm")
  ; Commander Caius
  RegisterScreenshotOf(0x00038257, "Skyrim.esm")
  ; Commander Maro
  RegisterScreenshotOf(0x0001D4B5, "Skyrim.esm")
  ; Constance Michel
  RegisterScreenshotOf(0x00013350, "Skyrim.esm")
  ; Corpulus Vinius
  RegisterScreenshotOf(0x00013266, "Skyrim.esm")
  ; Cosnach
  RegisterScreenshotOf(0x00013390, "Skyrim.esm")
  ; Curalmil
  RegisterScreenshotOf(0x00048B55, "Skyrim.esm")
  ; Cynric Endell
  RegisterScreenshotOf(0x000D4FD8, "Skyrim.esm")
  ; Dagny
  RegisterScreenshotOf(0x0001434B, "Skyrim.esm")
  ; Dagur
  RegisterScreenshotOf(0x0001C183, "Skyrim.esm")
  ; Daighre
  RegisterScreenshotOf(0x00013391, "Skyrim.esm")
  ; Dalan Merchad
  RegisterScreenshotOf(0x000132A4, "Skyrim.esm")
  ; Danica Pure-Spring
  RegisterScreenshotOf(0x00013BA5, "Skyrim.esm")
  ; Deeja
  RegisterScreenshotOf(0x00013268, "Skyrim.esm")
  ; Deekus
  RegisterScreenshotOf(0x00020040, "Skyrim.esm")
  ; Degaine
  RegisterScreenshotOf(0x00013392, "Skyrim.esm")
  ; Delacourt
  RegisterScreenshotOf(0x00072663, "Skyrim.esm")
  ; Delphine
  RegisterScreenshotOf(0x00013478, "Skyrim.esm")
  ; Delvin Mallory
  RegisterScreenshotOf(0x0001CB78, "Skyrim.esm")
  ; Dengeir of Stuhn
  RegisterScreenshotOf(0x0001365A, "Skyrim.esm")
  ; Derkeethus
  RegisterScreenshotOf(0x0001403E, "Skyrim.esm")
  ; Dervenin the Mad
  RegisterScreenshotOf(0x0001327C, "Skyrim.esm")
  ; Dinya Balu
  RegisterScreenshotOf(0x00013352, "Skyrim.esm")
  ; Dirge
  RegisterScreenshotOf(0x0001336D, "Skyrim.esm")
  ; Donnel
  RegisterScreenshotOf(0x000D673A, "Skyrim.esm")
  ; Dorthe
  RegisterScreenshotOf(0x00013477, "Skyrim.esm")
  ; Drahff
  RegisterScreenshotOf(0x00095F7E, "Skyrim.esm")
  ; Drascua
  RegisterScreenshotOf(0x000240D7, "Skyrim.esm")
  ; Dravin Llanith
  RegisterScreenshotOf(0x00013353, "Skyrim.esm")
  ; Dravynea the Stoneweaver
  RegisterScreenshotOf(0x0001365F, "Skyrim.esm")
  ; Drevis Neloren
  RegisterScreenshotOf(0x0001C198, "Skyrim.esm")
  ; Drifa
  RegisterScreenshotOf(0x00013354, "Skyrim.esm")
  ; Dro'marash
  RegisterScreenshotOf(0x0001B1CF, "Skyrim.esm")
  ; Dryston
  RegisterScreenshotOf(0x000D6711, "Skyrim.esm")
  ; Duach
  RegisterScreenshotOf(0x00013393, "Skyrim.esm")
  ; Dulug
  RegisterScreenshotOf(0x000C78C0, "Skyrim.esm")
  ; Dushnamub
  RegisterScreenshotOf(0x0001B079, "Skyrim.esm")
  ; Edda
  RegisterScreenshotOf(0x00013356, "Skyrim.esm")
  ; Edith
  RegisterScreenshotOf(0x000877AF, "Skyrim.esm")
  ; Einarth
  RegisterScreenshotOf(0x0002C6CC, "Skyrim.esm")
  ; Eirid
  RegisterScreenshotOf(0x0001C185, "Skyrim.esm")
  ; Eisa Blackthorn
  RegisterScreenshotOf(0x000D001A, "Skyrim.esm")
  ; Elda Early-Dawn
  RegisterScreenshotOf(0x0001412A, "Skyrim.esm")
  ; Elenwen
  RegisterScreenshotOf(0x00013269, "Skyrim.esm")
  ; Elgrim
  RegisterScreenshotOf(0x00013357, "Skyrim.esm")
  ; Elisif the Fair
  RegisterScreenshotOf(0x0001326A, "Skyrim.esm")
  ; Elrindir
  RegisterScreenshotOf(0x00013B9E, "Skyrim.esm")
  ; Eltrys
  RegisterScreenshotOf(0x00013394, "Skyrim.esm")
  ; Embry
  RegisterScreenshotOf(0x0003550B, "Skyrim.esm")
  ; Emperor Titus Mede II
  RegisterScreenshotOf(0x0001D4B9, "Skyrim.esm")
  ; Endarie
  RegisterScreenshotOf(0x0001326F, "Skyrim.esm")
  ; Endon
  RegisterScreenshotOf(0x00013395, "Skyrim.esm")
  ; Enmon
  RegisterScreenshotOf(0x00013B6C, "Skyrim.esm")
  ; Ennis
  RegisterScreenshotOf(0x0001B3B5, "Skyrim.esm")
  ; Ennodius Papius
  RegisterScreenshotOf(0x0001360C, "Skyrim.esm")
  ; Enthir
  RegisterScreenshotOf(0x0001C19C, "Skyrim.esm")
  ; Eola
  RegisterScreenshotOf(0x0001990F, "Skyrim.esm")
  ; Eorlund Gray-Mane
  RegisterScreenshotOf(0x00013B9D, "Skyrim.esm")
  ; Erandur
  RegisterScreenshotOf(0x0002427D, "Skyrim.esm")
  ; Erdi
  RegisterScreenshotOf(0x00013271, "Skyrim.esm")
  ; Eriana
  RegisterScreenshotOf(0x0002ABC4, "Skyrim.esm")
  ; Erik the Slayer
  RegisterScreenshotOf(0x00065657, "Skyrim.esm")
  ; Erikur
  RegisterScreenshotOf(0x00013272, "Skyrim.esm")
  ; Erith
  RegisterScreenshotOf(0x000133AB, "Skyrim.esm")
  ; Erlendr
  RegisterScreenshotOf(0x000EA71F, "Skyrim.esm")
  ; Esbern
  RegisterScreenshotOf(0x00013358, "Skyrim.esm")
  ; Estormo
  RegisterScreenshotOf(0x00034D97, "Skyrim.esm")
  ; Etienne Rarnis
  RegisterScreenshotOf(0x0003A1D3, "Skyrim.esm")
  ; Evette San
  RegisterScreenshotOf(0x00013273, "Skyrim.esm")
  ; Eydis
  RegisterScreenshotOf(0x00013B77, "Skyrim.esm")
  ; Faendal
  RegisterScreenshotOf(0x00013480, "Skyrim.esm")
  ; Faida
  RegisterScreenshotOf(0x00019A28, "Skyrim.esm")
  ; Faleen
  RegisterScreenshotOf(0x00013397, "Skyrim.esm")
  ; Falion
  RegisterScreenshotOf(0x000135E9, "Skyrim.esm")
  ; Falk Firebeard
  RegisterScreenshotOf(0x00013274, "Skyrim.esm")
  ; Faralda
  RegisterScreenshotOf(0x0001C197, "Skyrim.esm")
  ; Farengar Secret-Fire
  RegisterScreenshotOf(0x00013BBB, "Skyrim.esm")
  ; Farkas
  RegisterScreenshotOf(0x0001A692, "Skyrim.esm")
  ; Faryl Atheron
  RegisterScreenshotOf(0x00014131, "Skyrim.esm")
  ; Fastred
  RegisterScreenshotOf(0x000136BF, "Skyrim.esm")
  ; Fenrig (Ghost)
  RegisterScreenshotOf(0x00038287, "Skyrim.esm")
  ; Festus Krex
  RegisterScreenshotOf(0x0001BDB2, "Skyrim.esm")
  ; Fihada
  RegisterScreenshotOf(0x00013275, "Skyrim.esm")
  ; Filnjar
  RegisterScreenshotOf(0x000136C3, "Skyrim.esm")
  ; Fjola
  RegisterScreenshotOf(0x00090739, "Skyrim.esm")
  ; Frabbi
  RegisterScreenshotOf(0x00013398, "Skyrim.esm")
  ; Fralia Gray-Mane
  RegisterScreenshotOf(0x00013B9C, "Skyrim.esm")
  ; Francois Beaufort
  RegisterScreenshotOf(0x00013359, "Skyrim.esm")
  ; Freir
  RegisterScreenshotOf(0x00013277, "Skyrim.esm")
  ; Frida
  RegisterScreenshotOf(0x00013614, "Skyrim.esm")
  ; Fridrika
  RegisterScreenshotOf(0x00013278, "Skyrim.esm")
  ; Frodnar
  RegisterScreenshotOf(0x0001347E, "Skyrim.esm")
  ; Frofnir Trollsbane
  RegisterScreenshotOf(0x0003E8AD, "Skyrim.esm")
  ; Froki Whetted-Blade
  RegisterScreenshotOf(0x000185F6, "Skyrim.esm")
  ; From-Deepest-Fathoms
  RegisterScreenshotOf(0x0001335A, "Skyrim.esm")
  ; Frost
  RegisterScreenshotOf(0x00097E1E, "Skyrim.esm")
  ; Frothar
  RegisterScreenshotOf(0x0001434C, "Skyrim.esm")
  ; Fruki
  RegisterScreenshotOf(0x00013615, "Skyrim.esm")
  ; Fultheim the Fearless
  RegisterScreenshotOf(0x0002E3E8, "Skyrim.esm")
  ; Gabriella
  RegisterScreenshotOf(0x0001BDB8, "Skyrim.esm")
  ; Gadba gro-Largash
  RegisterScreenshotOf(0x0001B09A, "Skyrim.esm")
  ; Gadnor
  RegisterScreenshotOf(0x0002EB58, "Skyrim.esm")
  ; Gaius Maro
  RegisterScreenshotOf(0x00044050, "Skyrim.esm")
  ; Galmar Stone-Fist
  RegisterScreenshotOf(0x00014128, "Skyrim.esm")
  ; Ganna Uriel
  RegisterScreenshotOf(0x0001365D, "Skyrim.esm")
  ; Garakh
  RegisterScreenshotOf(0x00019E1C, "Skyrim.esm")
  ; Garthar
  RegisterScreenshotOf(0x000B03A3, "Skyrim.esm")
  ; Garvey
  RegisterScreenshotOf(0x000D6703, "Skyrim.esm")
  ; Gat gro-Shargakh
  RegisterScreenshotOf(0x000199B7, "Skyrim.esm")
  ; Geimund
  RegisterScreenshotOf(0x0001327D, "Skyrim.esm")
  ; Gemma Uriel
  RegisterScreenshotOf(0x00014040, "Skyrim.esm")
  ; Gerdur
  RegisterScreenshotOf(0x0001347C, "Skyrim.esm")
  ; Gestur Rockbreaker
  RegisterScreenshotOf(0x00013603, "Skyrim.esm")
  ; Ghak
  RegisterScreenshotOf(0x000C78C2, "Skyrim.esm")
  ; Ghamorz
  RegisterScreenshotOf(0x000C78CC, "Skyrim.esm")
  ; Gharol
  RegisterScreenshotOf(0x00013B7C, "Skyrim.esm")
  ; Ghorbash the Iron Hand
  RegisterScreenshotOf(0x00013B81, "Skyrim.esm")
  ; Ghorza gra-Bagol
  RegisterScreenshotOf(0x0001339A, "Skyrim.esm")
  ; Ghunzul
  RegisterScreenshotOf(0x00013679, "Skyrim.esm")
  ; Gian the Fist
  RegisterScreenshotOf(0x0010A062, "Skyrim.esm")
  ; Gianna
  RegisterScreenshotOf(0x0004BCC3, "Skyrim.esm")
  ; Gilfre
  RegisterScreenshotOf(0x0001367A, "Skyrim.esm")
  ; Giraud Gemane
  RegisterScreenshotOf(0x00013281, "Skyrim.esm")
  ; Gisli
  RegisterScreenshotOf(0x00013282, "Skyrim.esm")
  ; Gissu
  RegisterScreenshotOf(0x00039F23, "Skyrim.esm")
  ; Golldir
  RegisterScreenshotOf(0x00019FE8, "Skyrim.esm")
  ; Gorm
  RegisterScreenshotOf(0x000135EA, "Skyrim.esm")
  ; Gralnach
  RegisterScreenshotOf(0x00019C01, "Skyrim.esm")
  ; Grelka
  RegisterScreenshotOf(0x000136C5, "Skyrim.esm")
  ; Grelod the Kind
  RegisterScreenshotOf(0x0001335E, "Skyrim.esm")
  ; Grimvar Cruel-Sea
  RegisterScreenshotOf(0x00014133, "Skyrim.esm")
  ; Grisvar the Unlucky
  RegisterScreenshotOf(0x0001339B, "Skyrim.esm")
  ; Grogmar gro-Burzag
  RegisterScreenshotOf(0x000136C6, "Skyrim.esm")
  ; Grosta Grosta Nord
  RegisterScreenshotOf(0x00019C00, "Skyrim.esm")
  ; Guardian Saerek
  RegisterScreenshotOf(0x0003725E, "Skyrim.esm")
  ; Guardian Troll Spirit
  RegisterScreenshotOf(0x000E7EB2, "Skyrim.esm")
  ; Gul
  RegisterScreenshotOf(0x000C78CA, "Skyrim.esm")
  ; Gularzob
  RegisterScreenshotOf(0x00019E20, "Skyrim.esm")
  ; Gulum-Ei
  RegisterScreenshotOf(0x00013284, "Skyrim.esm")
  ; Gunjar
  RegisterScreenshotOf(0x0009B0AD, "Skyrim.esm")
  ; Gwendolyn
  RegisterScreenshotOf(0x0002C930, "Skyrim.esm")
  ; Gwilin
  RegisterScreenshotOf(0x000658D4, "Skyrim.esm")
  ; Hadring
  RegisterScreenshotOf(0x00013627, "Skyrim.esm")
  ; Hadvar
  RegisterScreenshotOf(0x0002BF9F, "Skyrim.esm")
  ; Haelga
  RegisterScreenshotOf(0x0001335F, "Skyrim.esm")
  ; Hafjorg
  RegisterScreenshotOf(0x00013360, "Skyrim.esm")
  ; Haldyn
  RegisterScreenshotOf(0x0001DC04, "Skyrim.esm")
  ; Halldir
  RegisterScreenshotOf(0x00064B1C, "Skyrim.esm")
  ; Hamal
  RegisterScreenshotOf(0x0001E765, "Skyrim.esm")
  ; Hamelyn
  RegisterScreenshotOf(0x0010A04C, "Skyrim.esm")
  ; Haran
  RegisterScreenshotOf(0x0001C184, "Skyrim.esm")
  ; Harrald
  RegisterScreenshotOf(0x00013361, "Skyrim.esm")
  ; Hathrasil
  RegisterScreenshotOf(0x0001339C, "Skyrim.esm")
  ; Hefid the Deaf
  RegisterScreenshotOf(0x0009400E, "Skyrim.esm")
  ; Heimskr
  RegisterScreenshotOf(0x00013BAC, "Skyrim.esm")
  ; Helgird
  RegisterScreenshotOf(0x00014124, "Skyrim.esm")
  ; Helvard
  RegisterScreenshotOf(0x00013657, "Skyrim.esm")
  ; Hemming Black-Briar
  RegisterScreenshotOf(0x00013362, "Skyrim.esm")
  ; Heratar
  RegisterScreenshotOf(0x000CE089, "Skyrim.esm")
  ; Herluin Lothaire
  RegisterScreenshotOf(0x00029DAE, "Skyrim.esm")
  ; Hermir Strong-Heart
  RegisterScreenshotOf(0x0001412D, "Skyrim.esm")
  ; Hert
  RegisterScreenshotOf(0x0001367C, "Skyrim.esm")
  ; Hevnoraak
  RegisterScreenshotOf(0x0004D6E7, "Skyrim.esm")
  ; Hewnon Black-Skeever
  RegisterScreenshotOf(0x00095FD5, "Skyrim.esm")
  ; Hilde
  RegisterScreenshotOf(0x00035533, "Skyrim.esm")
  ; Hillevi Cruel-Sea
  RegisterScreenshotOf(0x0001411F, "Skyrim.esm")
  ; Hjorunn
  RegisterScreenshotOf(0x00013287, "Skyrim.esm")
  ; Hod
  RegisterScreenshotOf(0x0001347D, "Skyrim.esm")
  ; Hoddreid
  RegisterScreenshotOf(0x000CE09D, "Skyrim.esm")
  ; Hofgrir Horse-Crusher
  RegisterScreenshotOf(0x00013351, "Skyrim.esm")
  ; Hogni Red-Arm
  RegisterScreenshotOf(0x000284AC, "Skyrim.esm")
  ; Horgeir
  RegisterScreenshotOf(0x00019A1D, "Skyrim.esm")
  ; Horik
  RegisterScreenshotOf(0x0001A6B9, "Skyrim.esm")
  ; Horm
  RegisterScreenshotOf(0x00013288, "Skyrim.esm")
  ; Hrefna
  RegisterScreenshotOf(0x00013668, "Skyrim.esm")
  ; Hreinn
  RegisterScreenshotOf(0x0001339D, "Skyrim.esm")
  ; Hroar
  RegisterScreenshotOf(0x00013363, "Skyrim.esm")
  ; Hroggar
  RegisterScreenshotOf(0x000135F0, "Skyrim.esm")
  ; Hroki
  RegisterScreenshotOf(0x0001339E, "Skyrim.esm")
  ; Hrongar
  RegisterScreenshotOf(0x00013BBC, "Skyrim.esm")
  ; Hulda
  RegisterScreenshotOf(0x00013BA3, "Skyrim.esm")
  ; Iddra
  RegisterScreenshotOf(0x00013662, "Skyrim.esm")
  ; Idgrod Ravencrone
  RegisterScreenshotOf(0x000135EB, "Skyrim.esm")
  ; Idgrod the Younger
  RegisterScreenshotOf(0x000135EC, "Skyrim.esm")
  ; Idolaf Battle-Born
  RegisterScreenshotOf(0x00013BB2, "Skyrim.esm")
  ; Igmund
  RegisterScreenshotOf(0x0001339F, "Skyrim.esm")
  ; Illdi
  RegisterScreenshotOf(0x00013289, "Skyrim.esm")
  ; Illia
  RegisterScreenshotOf(0x00048C2F, "Skyrim.esm")
  ; Imedhnain
  RegisterScreenshotOf(0x000133A1, "Skyrim.esm")
  ; Indara Caerellia
  RegisterScreenshotOf(0x0001364F, "Skyrim.esm")
  ; Indaryn
  RegisterScreenshotOf(0x00013370, "Skyrim.esm")
  ; Inge Six-Fingers
  RegisterScreenshotOf(0x0001328A, "Skyrim.esm")
  ; Ingun Black-Briar
  RegisterScreenshotOf(0x00013364, "Skyrim.esm")
  ; Iona
  RegisterScreenshotOf(0x000A2C91, "Skyrim.esm")
  ; Irgnir
  RegisterScreenshotOf(0x00013617, "Skyrim.esm")
  ; Irileth
  RegisterScreenshotOf(0x00013BB8, "Skyrim.esm")
  ; Irnskar Ironhand
  RegisterScreenshotOf(0x0001328B, "Skyrim.esm")
  ; Isabelle Rolaine
  RegisterScreenshotOf(0x00039840, "Skyrim.esm")
  ; J'darr
  RegisterScreenshotOf(0x0003B0E7, "Skyrim.esm")
  ; J'Kier
  RegisterScreenshotOf(0x0002ABC3, "Skyrim.esm")
  ; J'zargo
  RegisterScreenshotOf(0x0001C195, "Skyrim.esm")
  ; J'zhar
  RegisterScreenshotOf(0x0003B0E6, "Skyrim.esm")
  ; Jala
  RegisterScreenshotOf(0x0001328C, "Skyrim.esm")
  ; Japhet
  RegisterScreenshotOf(0x000E63D6, "Skyrim.esm")
  ; Jaree-Ra
  RegisterScreenshotOf(0x0001328D, "Skyrim.esm")
  ; Jawanan
  RegisterScreenshotOf(0x0001328E, "Skyrim.esm")
  ; Jenassa
  RegisterScreenshotOf(0x000B9982, "Skyrim.esm")
  ; Jesper
  RegisterScreenshotOf(0x00013604, "Skyrim.esm")
  ; Jod
  RegisterScreenshotOf(0x00013618, "Skyrim.esm")
  ; Jofthor
  RegisterScreenshotOf(0x000136BD, "Skyrim.esm")
  ; Jon Battle-Born
  RegisterScreenshotOf(0x00013BB1, "Skyrim.esm")
  ; Jonna
  RegisterScreenshotOf(0x000135ED, "Skyrim.esm")
  ; Jora Wing-Wish
  RegisterScreenshotOf(0x00014120, "Skyrim.esm")
  ; Jordis the Sword-Maiden
  RegisterScreenshotOf(0x000A2C8F, "Skyrim.esm")
  ; Jorgen
  RegisterScreenshotOf(0x000138B6, "Skyrim.esm")
  ; Joric
  RegisterScreenshotOf(0x000135EE, "Skyrim.esm")
  ; Jorleif
  RegisterScreenshotOf(0x00014135, "Skyrim.esm")
  ; Jorn
  RegisterScreenshotOf(0x0001328F, "Skyrim.esm")
  ; Jouane Manette
  RegisterScreenshotOf(0x000136B3, "Skyrim.esm")
  ; Julienne Lylvieve
  RegisterScreenshotOf(0x00026F0F, "Skyrim.esm")
  ; Karita
  RegisterScreenshotOf(0x0001361A, "Skyrim.esm")
  ; Karl
  RegisterScreenshotOf(0x00013619, "Skyrim.esm")
  ; Karliah
  RegisterScreenshotOf(0x0001B07F, "Skyrim.esm")
  ; Katla
  RegisterScreenshotOf(0x00013290, "Skyrim.esm")
  ; Keeper Carcette
  RegisterScreenshotOf(0x000BFB55, "Skyrim.esm")
  ; Keerava
  RegisterScreenshotOf(0x00013365, "Skyrim.esm")
  ; Kematu
  RegisterScreenshotOf(0x00021601, "Skyrim.esm")
  ; Kerah
  RegisterScreenshotOf(0x000133A2, "Skyrim.esm")
  ; Kesh the Clean
  RegisterScreenshotOf(0x00089986, "Skyrim.esm")
  ; Kharag gro-Shurkul
  RegisterScreenshotOf(0x00013291, "Skyrim.esm")
  ; Kharjo
  RegisterScreenshotOf(0x0001B1D2, "Skyrim.esm")
  ; Khayla
  RegisterScreenshotOf(0x0001B1D9, "Skyrim.esm")
  ; Kibell
  RegisterScreenshotOf(0x0003F21E, "Skyrim.esm")
  ; Kjar
  RegisterScreenshotOf(0x00013293, "Skyrim.esm")
  ; Kjeld the Younger
  RegisterScreenshotOf(0x00013661, "Skyrim.esm")
  ; Kleppr
  RegisterScreenshotOf(0x000133A3, "Skyrim.esm")
  ; Klimmek
  RegisterScreenshotOf(0x000136C2, "Skyrim.esm")
  ; Knjakr
  RegisterScreenshotOf(0x00094000, "Skyrim.esm")
  ; Knud
  RegisterScreenshotOf(0x00013294, "Skyrim.esm")
  ; Kodiak Whitemane
  RegisterScreenshotOf(0x0001A68E, "Skyrim.esm")
  ; Kodrir
  RegisterScreenshotOf(0x0001360D, "Skyrim.esm")
  ; Korir
  RegisterScreenshotOf(0x0001C188, "Skyrim.esm")
  ; Kornalus
  RegisterScreenshotOf(0x00039BB7, "Skyrim.esm")
  ; Kraldar
  RegisterScreenshotOf(0x0001C180, "Skyrim.esm")
  ; Krosis
  RegisterScreenshotOf(0x00100767, "Skyrim.esm")
  ; Kust
  RegisterScreenshotOf(0x0001364C, "Skyrim.esm")
  ; Kyr
  RegisterScreenshotOf(0x000D37D1, "Skyrim.esm")
  ; Laila Law-Giver
  RegisterScreenshotOf(0x00013366, "Skyrim.esm")
  ; Lami
  RegisterScreenshotOf(0x000135EF, "Skyrim.esm")
  ; Lars Battle-Born
  RegisterScreenshotOf(0x00013BAF, "Skyrim.esm")
  ; Lash gra-Dushnikh
  RegisterScreenshotOf(0x00013B6E, "Skyrim.esm")
  ; Legate Rikke
  RegisterScreenshotOf(0x000132A1, "Skyrim.esm")
  ; Legate Skulnar
  RegisterScreenshotOf(0x0008455E, "Skyrim.esm")
  ; Leifur
  RegisterScreenshotOf(0x00013610, "Skyrim.esm")
  ; Leigelf Quicksilver
  RegisterScreenshotOf(0x0001361B, "Skyrim.esm")
  ; Lemkil
  RegisterScreenshotOf(0x000136B8, "Skyrim.esm")
  ; Leonara Arius
  RegisterScreenshotOf(0x00037E04, "Skyrim.esm")
  ; Leontius Salvius
  RegisterScreenshotOf(0x00013B76, "Skyrim.esm")
  ; Lieutenant Salvarus
  RegisterScreenshotOf(0x000C44FF, "Skyrim.esm")
  ; Lis
  RegisterScreenshotOf(0x000A19FF, "Skyrim.esm")
  ; Lisbet
  RegisterScreenshotOf(0x000133A5, "Skyrim.esm")
  ; Lisette
  RegisterScreenshotOf(0x00013297, "Skyrim.esm")
  ; Lob
  RegisterScreenshotOf(0x00019E1E, "Skyrim.esm")
  ; Lod
  RegisterScreenshotOf(0x00013650, "Skyrim.esm")
  ; Lodvar
  RegisterScreenshotOf(0x00019A22, "Skyrim.esm")
  ; Logrolf the Willful
  RegisterScreenshotOf(0x000133A6, "Skyrim.esm")
  ; Lond Northstrider
  RegisterScreenshotOf(0x0001361C, "Skyrim.esm")
  ; Lortheim
  RegisterScreenshotOf(0x00014145, "Skyrim.esm")
  ; Louis Letrush
  RegisterScreenshotOf(0x00013368, "Skyrim.esm")
  ; Lowlife
  RegisterScreenshotOf(0x0005CBE9, "Skyrim.esm")
  ; Lu'ah
  RegisterScreenshotOf(0x0002333A, "Skyrim.esm")
  ; Lucan Valerius
  RegisterScreenshotOf(0x0001347A, "Skyrim.esm")
  ; Lurbuk gro-Dushnikh
  RegisterScreenshotOf(0x0001AA63, "Skyrim.esm")
  ; Lydia
  RegisterScreenshotOf(0x000A2C8E, "Skyrim.esm")
  ; Lynly Star-Sung
  RegisterScreenshotOf(0x000136BC, "Skyrim.esm")
  ; M'aiq the Liar
  RegisterScreenshotOf(0x000954BF, "Skyrim.esm")
  ; Ma'dran
  RegisterScreenshotOf(0x0001B1D1, "Skyrim.esm")
  ; Ma'jhad
  RegisterScreenshotOf(0x0001B1D5, "Skyrim.esm")
  ; Ma'randru-jo
  RegisterScreenshotOf(0x0001B1D7, "Skyrim.esm")
  ; Ma'tasarr
  RegisterScreenshotOf(0x000CE09B, "Skyrim.esm")
  ; Ma'zaka
  RegisterScreenshotOf(0x00013298, "Skyrim.esm")
  ; Madanach
  RegisterScreenshotOf(0x000133A7, "Skyrim.esm")
  ; Madena
  RegisterScreenshotOf(0x0001361D, "Skyrim.esm")
  ; Madesi
  RegisterScreenshotOf(0x0001B072, "Skyrim.esm")
  ; Mahk
  RegisterScreenshotOf(0x000C78BE, "Skyrim.esm")
  ; Malkoran
  RegisterScreenshotOf(0x0009CB66, "Skyrim.esm")
  ; Mallus Maccius
  RegisterScreenshotOf(0x0002BA8E, "Skyrim.esm")
  ; Malthyr Elenil
  RegisterScreenshotOf(0x0001414E, "Skyrim.esm")
  ; Malur Seloth
  RegisterScreenshotOf(0x0001C182, "Skyrim.esm")
  ; Mammoth Guardian Spirit
  RegisterScreenshotOf(0x000E7EAF, "Skyrim.esm")
  ; Maramal
  RegisterScreenshotOf(0x0001335B, "Skyrim.esm")
  ; Marcurio
  RegisterScreenshotOf(0x000B9980, "Skyrim.esm")
  ; Marise Aravel
  RegisterScreenshotOf(0x00013369, "Skyrim.esm")
  ; Mathies Caerellia
  RegisterScreenshotOf(0x0001364E, "Skyrim.esm")
  ; Maul
  RegisterScreenshotOf(0x000371D6, "Skyrim.esm")
  ; Maurice Jondrelle
  RegisterScreenshotOf(0x0001C605, "Skyrim.esm")
  ; Maven Black-Briar
  RegisterScreenshotOf(0x0001336A, "Skyrim.esm")
  ; Medresi Dran
  RegisterScreenshotOf(0x0003B5B2, "Skyrim.esm")
  ; Meeko
  RegisterScreenshotOf(0x000D95E9, "Skyrim.esm")
  ; Melaran
  RegisterScreenshotOf(0x00013299, "Skyrim.esm")
  ; Melka
  RegisterScreenshotOf(0x00039B3E, "Skyrim.esm")
  ; Mena
  RegisterScreenshotOf(0x00013B6D, "Skyrim.esm")
  ; Michel Lylvieve
  RegisterScreenshotOf(0x00019A2E, "Skyrim.esm")
  ; Mikael
  RegisterScreenshotOf(0x0001A670, "Skyrim.esm")
  ; Mila Valentia
  RegisterScreenshotOf(0x00013BAD, "Skyrim.esm")
  ; Minette Vinius
  RegisterScreenshotOf(0x0001329B, "Skyrim.esm")
  ; Mirabelle Ervine
  RegisterScreenshotOf(0x0001C1A0, "Skyrim.esm")
  ; Mjoll the Lioness
  RegisterScreenshotOf(0x0001336B, "Skyrim.esm")
  ; Mogdurz
  RegisterScreenshotOf(0x000C78DF, "Skyrim.esm")
  ; Molgrom Twice-Killed
  RegisterScreenshotOf(0x0001336C, "Skyrim.esm")
  ; Morokei
  RegisterScreenshotOf(0x000F496C, "Skyrim.esm")
  ; Morven
  RegisterScreenshotOf(0x000D6719, "Skyrim.esm")
  ; Moth gro-Bagol
  RegisterScreenshotOf(0x00055A5E, "Skyrim.esm")
  ; Mralki
  RegisterScreenshotOf(0x000136B6, "Skyrim.esm")
  ; Mudcrab Guardian Spirit
  RegisterScreenshotOf(0x000E662B, "Skyrim.esm")
  ; Muiri
  RegisterScreenshotOf(0x0001406B, "Skyrim.esm")
  ; Mul gro-Largash
  RegisterScreenshotOf(0x0001B07A, "Skyrim.esm")
  ; Mulush gro-Shugurz
  RegisterScreenshotOf(0x000133A9, "Skyrim.esm")
  ; Murbul
  RegisterScreenshotOf(0x00013B7A, "Skyrim.esm")
  ; Nagrub
  RegisterScreenshotOf(0x00013B7F, "Skyrim.esm")
  ; Nahagliiv
  RegisterScreenshotOf(0x000FE431, "Skyrim.esm")
  ; Nahkriin
  RegisterScreenshotOf(0x000F849B, "Skyrim.esm")
  ; Nana Ildene
  RegisterScreenshotOf(0x000133A0, "Skyrim.esm")
  ; Narfi
  RegisterScreenshotOf(0x000136C0, "Skyrim.esm")
  ; Naris the Wicked
  RegisterScreenshotOf(0x000427A6, "Skyrim.esm")
  ; Narri
  RegisterScreenshotOf(0x00013654, "Skyrim.esm")
  ; Nazeem
  RegisterScreenshotOf(0x00013BBF, "Skyrim.esm")
  ; Nazir
  RegisterScreenshotOf(0x0001C3AB, "Skyrim.esm")
  ; Neetrenaza
  RegisterScreenshotOf(0x0001412F, "Skyrim.esm")
  ; Nelacar
  RegisterScreenshotOf(0x0001E7D5, "Skyrim.esm")
  ; Nelkir
  RegisterScreenshotOf(0x0001434D, "Skyrim.esm")
  ; Nenya
  RegisterScreenshotOf(0x00013659, "Skyrim.esm")
  ; Nepos the Nose
  RegisterScreenshotOf(0x000133AA, "Skyrim.esm")
  ; Nerien
  RegisterScreenshotOf(0x000233D2, "Skyrim.esm")
  ; Niels
  RegisterScreenshotOf(0x000411D0, "Skyrim.esm")
  ; Nightingale Sentinel
  RegisterScreenshotOf(0x0001BB5D, "Skyrim.esm")
  ; Nils
  RegisterScreenshotOf(0x0001414B, "Skyrim.esm")
  ; Nilsine Shatter-Shield
  RegisterScreenshotOf(0x0001412C, "Skyrim.esm")
  ; Niluva Hlaalu
  RegisterScreenshotOf(0x0001336E, "Skyrim.esm")
  ; Nimriel
  RegisterScreenshotOf(0x0002C926, "Skyrim.esm")
  ; Niranye
  RegisterScreenshotOf(0x00014123, "Skyrim.esm")
  ; Niruin
  RegisterScreenshotOf(0x0001CD91, "Skyrim.esm")
  ; Nirya
  RegisterScreenshotOf(0x0001C19B, "Skyrim.esm")
  ; Nivenor
  RegisterScreenshotOf(0x0001336F, "Skyrim.esm")
  ; Njada Stonearm
  RegisterScreenshotOf(0x0001A6D9, "Skyrim.esm")
  ; Nord
  RegisterScreenshotOf(0x000E3EAD, "Skyrim.esm")
  ; Nura Snow-Shod
  RegisterScreenshotOf(0x00013372, "Skyrim.esm")
  ; Nurelion
  RegisterScreenshotOf(0x00014148, "Skyrim.esm")
  ; Octieve San
  RegisterScreenshotOf(0x0001329D, "Skyrim.esm")
  ; Odar
  RegisterScreenshotOf(0x0001329E, "Skyrim.esm")
  ; Odfel
  RegisterScreenshotOf(0x000136C4, "Skyrim.esm")
  ; Odvan
  RegisterScreenshotOf(0x000133AC, "Skyrim.esm")
  ; Oengul War-Anvil
  RegisterScreenshotOf(0x00014142, "Skyrim.esm")
  ; Oglub
  RegisterScreenshotOf(0x00013B80, "Skyrim.esm")
  ; Ogmund
  RegisterScreenshotOf(0x000133AD, "Skyrim.esm")
  ; Ogol
  RegisterScreenshotOf(0x00019E22, "Skyrim.esm")
  ; Olava the Feeble
  RegisterScreenshotOf(0x00013BAE, "Skyrim.esm")
  ; Olda
  RegisterScreenshotOf(0x00019A20, "Skyrim.esm")
  ; Olfina Gray-Mane
  RegisterScreenshotOf(0x00013B9B, "Skyrim.esm")
  ; Olfrid Battle-Born
  RegisterScreenshotOf(0x00013BB4, "Skyrim.esm")
  ; Olur
  RegisterScreenshotOf(0x0001995B, "Skyrim.esm")
  ; Omluag
  RegisterScreenshotOf(0x000133AE, "Skyrim.esm")
  ; Ondolemar
  RegisterScreenshotOf(0x000133AF, "Skyrim.esm")
  ; Onmund
  RegisterScreenshotOf(0x0001C194, "Skyrim.esm")
  ; Orchendor
  RegisterScreenshotOf(0x00045F78, "Skyrim.esm")
  ; Orgnar
  RegisterScreenshotOf(0x00013479, "Skyrim.esm")
  ; Orla
  RegisterScreenshotOf(0x000133B0, "Skyrim.esm")
  ; Orthorn
  RegisterScreenshotOf(0x0002A388, "Skyrim.esm")
  ; Orthus Endario
  RegisterScreenshotOf(0x0001413B, "Skyrim.esm")
  ; Otar the Mad
  RegisterScreenshotOf(0x0003763A, "Skyrim.esm")
  ; Paarthurnax
  RegisterScreenshotOf(0x0003C57C, "Skyrim.esm")
  ; Pactur
  RegisterScreenshotOf(0x00013605, "Skyrim.esm")
  ; Pantea Ateia
  RegisterScreenshotOf(0x0001329F, "Skyrim.esm")
  ; Paratus Decimius
  RegisterScreenshotOf(0x00034CBA, "Skyrim.esm")
  ; Pavo Attius
  RegisterScreenshotOf(0x000133B1, "Skyrim.esm")
  ; Perth
  RegisterScreenshotOf(0x0001996C, "Skyrim.esm")
  ; Phinis Gestor
  RegisterScreenshotOf(0x0001C199, "Skyrim.esm")
  ; Proventus Avenicci
  RegisterScreenshotOf(0x00013BBA, "Skyrim.esm")
  ; Pumpkin
  RegisterScreenshotOf(0x000B11A7, "Skyrim.esm")
  ; Quaranir
  RegisterScreenshotOf(0x0002BA3C, "Skyrim.esm")
  ; Quintus Navale
  RegisterScreenshotOf(0x0001414C, "Skyrim.esm")
  ; Ra'jirr
  RegisterScreenshotOf(0x000D37CF, "Skyrim.esm")
  ; Ra'kheran
  RegisterScreenshotOf(0x0002ABC2, "Skyrim.esm")
  ; Ra'zhinda
  RegisterScreenshotOf(0x0001B1D3, "Skyrim.esm")
  ; Raerek
  RegisterScreenshotOf(0x000133B2, "Skyrim.esm")
  ; Ragnar
  RegisterScreenshotOf(0x00013B6A, "Skyrim.esm")
  ; Rahgot
  RegisterScreenshotOf(0x00035351, "Skyrim.esm")
  ; Ralof
  RegisterScreenshotOf(0x0002BF9D, "Skyrim.esm")
  ; Ranmir
  RegisterScreenshotOf(0x0001C186, "Skyrim.esm")
  ; Ravyn Imyan
  RegisterScreenshotOf(0x000B03A4, "Skyrim.esm")
  ; Razelan
  RegisterScreenshotOf(0x000368C8, "Skyrim.esm")
  ; Reburrus Quintilius
  RegisterScreenshotOf(0x000133B3, "Skyrim.esm")
  ; Red Eagle
  RegisterScreenshotOf(0x000C1908, "Skyrim.esm")
  ; Reldith
  RegisterScreenshotOf(0x000136B4, "Skyrim.esm")
  ; Revyn Sadri
  RegisterScreenshotOf(0x0001413A, "Skyrim.esm")
  ; Rexus
  RegisterScreenshotOf(0x0005BF2B, "Skyrim.esm")
  ; Rhiada
  RegisterScreenshotOf(0x000133B4, "Skyrim.esm")
  ; Rhorlak
  RegisterScreenshotOf(0x000799E4, "Skyrim.esm")
  ; Ri'saad
  RegisterScreenshotOf(0x0001B1DB, "Skyrim.esm")
  ; Ria
  RegisterScreenshotOf(0x0001A6D7, "Skyrim.esm")
  ; Rissing
  RegisterScreenshotOf(0x0002ABC0, "Skyrim.esm")
  ; Rogatus Salvius
  RegisterScreenshotOf(0x000133B5, "Skyrim.esm")
  ; Roggi Knot-Beard
  RegisterScreenshotOf(0x0001403F, "Skyrim.esm")
  ; Roggvir
  RegisterScreenshotOf(0x000A3BDB, "Skyrim.esm")
  ; Rolff Stone-Fist
  RegisterScreenshotOf(0x0003EFE9, "Skyrim.esm")
  ; Romlyn Dreth
  RegisterScreenshotOf(0x00013377, "Skyrim.esm")
  ; Rondach
  RegisterScreenshotOf(0x000133B6, "Skyrim.esm")
  ; Rorik
  RegisterScreenshotOf(0x000136B2, "Skyrim.esm")
  ; Rorlund
  RegisterScreenshotOf(0x000132A2, "Skyrim.esm")
  ; Ruki
  RegisterScreenshotOf(0x00038289, "Skyrim.esm")
  ; Rulindil
  RegisterScreenshotOf(0x00039F1F, "Skyrim.esm")
  ; Runa Fair-Shield
  RegisterScreenshotOf(0x00013378, "Skyrim.esm")
  ; Rune
  RegisterScreenshotOf(0x000D4FDE, "Skyrim.esm")
  ; Runil
  RegisterScreenshotOf(0x0001364D, "Skyrim.esm")
  ; Rustleif
  RegisterScreenshotOf(0x0001361E, "Skyrim.esm")
  ; Saadia
  RegisterScreenshotOf(0x00013BA2, "Skyrim.esm")
  ; Sabine Nytte
  RegisterScreenshotOf(0x000132A3, "Skyrim.esm")
  ; Sabjorn
  RegisterScreenshotOf(0x0002BA8C, "Skyrim.esm")
  ; Sabre Cat Guardian Spirit
  RegisterScreenshotOf(0x000E7EAD, "Skyrim.esm")
  ; Saerlund
  RegisterScreenshotOf(0x00013379, "Skyrim.esm")
  ; Sahloknir
  RegisterScreenshotOf(0x00032D9B, "Skyrim.esm")
  ; Salvianus
  RegisterScreenshotOf(0x00094012, "Skyrim.esm")
  ; Sam Guevenne
  RegisterScreenshotOf(0x0001BB9C, "Skyrim.esm")
  ; Samuel
  RegisterScreenshotOf(0x0001337A, "Skyrim.esm")
  ; Sapphire
  RegisterScreenshotOf(0x000C19A3, "Skyrim.esm")
  ; Savos Aren
  RegisterScreenshotOf(0x0001C19F, "Skyrim.esm")
  ; Sayma
  RegisterScreenshotOf(0x0001329A, "Skyrim.esm")
  ; Scouts-Many-Marshes
  RegisterScreenshotOf(0x0001412E, "Skyrim.esm")
  ; Selveni Nethri
  RegisterScreenshotOf(0x0003A745, "Skyrim.esm")
  ; Senna
  RegisterScreenshotOf(0x000133B7, "Skyrim.esm")
  ; Septimus Signus
  RegisterScreenshotOf(0x0002D514, "Skyrim.esm")
  ; Seren
  RegisterScreenshotOf(0x0001361F, "Skyrim.esm")
  ; Sergius Turrianus
  RegisterScreenshotOf(0x0001C23E, "Skyrim.esm")
  ; Severio Pelagia
  RegisterScreenshotOf(0x0002C925, "Skyrim.esm")
  ; Shadowmere
  RegisterScreenshotOf(0x0009CCD7, "Skyrim.esm")
  ; Shadr
  RegisterScreenshotOf(0x00013371, "Skyrim.esm")
  ; Shahvee
  RegisterScreenshotOf(0x0001411A, "Skyrim.esm")
  ; Sharamph
  RegisterScreenshotOf(0x00019953, "Skyrim.esm")
  ; Sheogorath
  RegisterScreenshotOf(0x0002AC69, "Skyrim.esm")
  ; Shuftharz
  RegisterScreenshotOf(0x00019957, "Skyrim.esm")
  ; Sibbi Black-Briar
  RegisterScreenshotOf(0x0001337B, "Skyrim.esm")
  ; Siddgeir
  RegisterScreenshotOf(0x00013653, "Skyrim.esm")
  ; Sifnar Ironkettle
  RegisterScreenshotOf(0x00029D96, "Skyrim.esm")
  ; Sigaar
  RegisterScreenshotOf(0x0009B7AA, "Skyrim.esm")
  ; Sigrid
  RegisterScreenshotOf(0x00013476, "Skyrim.esm")
  ; Silana Petreia
  RegisterScreenshotOf(0x000132A5, "Skyrim.esm")
  ; Sild the Warlock
  RegisterScreenshotOf(0x0005197F, "Skyrim.esm")
  ; Silda the Unseen
  RegisterScreenshotOf(0x00014121, "Skyrim.esm")
  ; Silus Vesuius
  RegisterScreenshotOf(0x000240CC, "Skyrim.esm")
  ; Silvia
  RegisterScreenshotOf(0x0004B0AE, "Skyrim.esm")
  ; Sinderion
  RegisterScreenshotOf(0x000EEDF1, "Skyrim.esm")
  ; Sinding [Falkreath Jail]
  RegisterScreenshotOf(0x0006C1B7, "Skyrim.esm")
  ; Sinding [Grotto]
  RegisterScreenshotOf(0x000136AC, "Skyrim.esm")
  ; Sinmir
  RegisterScreenshotOf(0x000813B5, "Skyrim.esm")
  ; Sirgar
  RegisterScreenshotOf(0x00013607, "Skyrim.esm")
  ; Sissel
  RegisterScreenshotOf(0x000136BA, "Skyrim.esm")
  ; Skaggi Scar-Face
  RegisterScreenshotOf(0x000133B8, "Skyrim.esm")
  ; Skald the Elder
  RegisterScreenshotOf(0x00013620, "Skyrim.esm")
  ; Skeever Guardian Spirit
  RegisterScreenshotOf(0x000E662E, "Skyrim.esm")
  ; Skjor
  RegisterScreenshotOf(0x0001A690, "Skyrim.esm")
  ; Skuli
  RegisterScreenshotOf(0x00013B78, "Skyrim.esm")
  ; Skulvar Sable-Hilt
  RegisterScreenshotOf(0x00013BB7, "Skyrim.esm")
  ; Snilf
  RegisterScreenshotOf(0x0001B071, "Skyrim.esm")
  ; Snilling
  RegisterScreenshotOf(0x000132A6, "Skyrim.esm")
  ; Solaf
  RegisterScreenshotOf(0x00013652, "Skyrim.esm")
  ; Sondas Drenim
  RegisterScreenshotOf(0x0001366B, "Skyrim.esm")
  ; Sorex Vinius
  RegisterScreenshotOf(0x000132A7, "Skyrim.esm")
  ; Sorli the Builder
  RegisterScreenshotOf(0x00013606, "Skyrim.esm")
  ; Sosia Tremellia
  RegisterScreenshotOf(0x000133B9, "Skyrim.esm")
  ; Stalleo
  RegisterScreenshotOf(0x0004B4AF, "Skyrim.esm")
  ; Stands-In-Shallows
  RegisterScreenshotOf(0x00014130, "Skyrim.esm")
  ; Stenvar
  RegisterScreenshotOf(0x000B9983, "Skyrim.esm")
  ; Stig Salt-Plank
  RegisterScreenshotOf(0x0001DC00, "Skyrim.esm")
  ; Stump
  RegisterScreenshotOf(0x0001E62A, "Skyrim.esm")
  ; Styrr
  RegisterScreenshotOf(0x000132A8, "Skyrim.esm")
  ; Sulla Trebatius
  RegisterScreenshotOf(0x0003B0E2, "Skyrim.esm")
  ; Susanna the Wicked
  RegisterScreenshotOf(0x0001412B, "Skyrim.esm")
  ; Suvaris Atheron
  RegisterScreenshotOf(0x00014122, "Skyrim.esm")
  ; Svaknir
  RegisterScreenshotOf(0x00016C87, "Skyrim.esm")
  ; Svana Far-Shield
  RegisterScreenshotOf(0x0001337C, "Skyrim.esm")
  ; Sven
  RegisterScreenshotOf(0x0001347F, "Skyrim.esm")
  ; Swanhvir
  RegisterScreenshotOf(0x00013608, "Skyrim.esm")
  ; Sybille Stentor
  RegisterScreenshotOf(0x000132AA, "Skyrim.esm")
  ; Sylgja
  RegisterScreenshotOf(0x000C3A3F, "Skyrim.esm")
  ; Synda Llanith
  RegisterScreenshotOf(0x000BB2C0, "Skyrim.esm")
  ; Syndus
  RegisterScreenshotOf(0x00029DAA, "Skyrim.esm")
  ; Taarie
  RegisterScreenshotOf(0x000132AB, "Skyrim.esm")
  ; Tacitus Sallustius
  RegisterScreenshotOf(0x0001402D, "Skyrim.esm")
  ; Talen-Jei
  RegisterScreenshotOf(0x00013373, "Skyrim.esm")
  ; Teeba-Ei
  RegisterScreenshotOf(0x0001360A, "Skyrim.esm")
  ; Tekla
  RegisterScreenshotOf(0x00013656, "Skyrim.esm")
  ; Telrav
  RegisterScreenshotOf(0x0001BA08, "Skyrim.esm")
  ; Temba Wide-Arm
  RegisterScreenshotOf(0x000658D2, "Skyrim.esm")
  ; Thaena
  RegisterScreenshotOf(0x0001C189, "Skyrim.esm")
  ; Thaer
  RegisterScreenshotOf(0x0009B7A6, "Skyrim.esm")
  ; Thonar Silver-Blood
  RegisterScreenshotOf(0x000133BA, "Skyrim.esm")
  ; Thonjolf
  RegisterScreenshotOf(0x0001C181, "Skyrim.esm")
  ; Thonnir
  RegisterScreenshotOf(0x000135F2, "Skyrim.esm")
  ; Thorald Gray-Mane
  RegisterScreenshotOf(0x0001C241, "Skyrim.esm")
  ; Thoring
  RegisterScreenshotOf(0x00013621, "Skyrim.esm")
  ; Threki the Innocent
  RegisterScreenshotOf(0x00013367, "Skyrim.esm")
  ; Thrynn
  RegisterScreenshotOf(0x000D4FDB, "Skyrim.esm")
  ; Tiber
  RegisterScreenshotOf(0x00023EF1, "Skyrim.esm")
  ; Tilma the Haggard
  RegisterScreenshotOf(0x00013BB6, "Skyrim.esm")
  ; Tolfdir
  RegisterScreenshotOf(0x0001C19E, "Skyrim.esm")
  ; Tonilia
  RegisterScreenshotOf(0x000B8827, "Skyrim.esm")
  ; Torbjorn Shatter-Shield
  RegisterScreenshotOf(0x0001413F, "Skyrim.esm")
  ; Torkild the Fearsome
  RegisterScreenshotOf(0x000CE084, "Skyrim.esm")
  ; Tormir
  RegisterScreenshotOf(0x0001403D, "Skyrim.esm")
  ; Torom
  RegisterScreenshotOf(0x0002F442, "Skyrim.esm")
  ; Torsten Cruel-Sea
  RegisterScreenshotOf(0x00014136, "Skyrim.esm")
  ; Torvar
  RegisterScreenshotOf(0x0001A6DB, "Skyrim.esm")
  ; Tova Shatter-Shield
  RegisterScreenshotOf(0x00014125, "Skyrim.esm")
  ; Tsavani
  RegisterScreenshotOf(0x000353C7, "Skyrim.esm")
  ; Tsrasuna
  RegisterScreenshotOf(0x000CE081, "Skyrim.esm")
  ; Tulvur
  RegisterScreenshotOf(0x00014139, "Skyrim.esm")
  ; Tynan
  RegisterScreenshotOf(0x000D6718, "Skyrim.esm")
  ; Tythis Ulen
  RegisterScreenshotOf(0x0001337D, "Skyrim.esm")
  ; Uaile
  RegisterScreenshotOf(0x000133BC, "Skyrim.esm")
  ; Ugor
  RegisterScreenshotOf(0x00019E1A, "Skyrim.esm")
  ; Ulag
  RegisterScreenshotOf(0x000E2BBF, "Skyrim.esm")
  ; Ulfberth War-Bear
  RegisterScreenshotOf(0x00013B9F, "Skyrim.esm")
  ; Ulfr the Blind
  RegisterScreenshotOf(0x000812FC, "Skyrim.esm")
  ; Ulfric Stormcloak
  RegisterScreenshotOf(0x0001414D, "Skyrim.esm")
  ; Ulundil
  RegisterScreenshotOf(0x00014141, "Skyrim.esm")
  ; Umana
  RegisterScreenshotOf(0x0003B0E3, "Skyrim.esm")
  ; Umurn
  RegisterScreenshotOf(0x00013B7E, "Skyrim.esm")
  ; Una
  RegisterScreenshotOf(0x000132AC, "Skyrim.esm")
  ; Ungrien
  RegisterScreenshotOf(0x0001337E, "Skyrim.esm")
  ; Unmid Snow-Shod
  RegisterScreenshotOf(0x000371D7, "Skyrim.esm")
  ; Uraccen
  RegisterScreenshotOf(0x000133BD, "Skyrim.esm")
  ; Urag gro-Shub
  RegisterScreenshotOf(0x0001C193, "Skyrim.esm")
  ; Urog
  RegisterScreenshotOf(0x0001B078, "Skyrim.esm")
  ; Ursine Guardian
  RegisterScreenshotOf(0x000E7EA9, "Skyrim.esm")
  ; Urzoga gra-Shugurz
  RegisterScreenshotOf(0x000133BE, "Skyrim.esm")
  ; Uthgerd the Unbroken
  RegisterScreenshotOf(0x000918E2, "Skyrim.esm")
  ; Vagrant
  RegisterScreenshotOf(0x000A3F8E, "Skyrim.esm")
  ; Valdar
  RegisterScreenshotOf(0x0002C18D, "Skyrim.esm")
  ; Valga Vinicia
  RegisterScreenshotOf(0x00013655, "Skyrim.esm")
  ; Valie
  RegisterScreenshotOf(0x0003B0E1, "Skyrim.esm")
  ; Valindor
  RegisterScreenshotOf(0x0001337F, "Skyrim.esm")
  ; Vals Veran
  RegisterScreenshotOf(0x00019FE6, "Skyrim.esm")
  ; Vanryth Gatharian
  RegisterScreenshotOf(0x00029DAF, "Skyrim.esm")
  ; Vantus Loreius
  RegisterScreenshotOf(0x0001A6B1, "Skyrim.esm")
  ; Vasha
  RegisterScreenshotOf(0x0002E3F0, "Skyrim.esm")
  ; Veezara
  RegisterScreenshotOf(0x0001C3AA, "Skyrim.esm")
  ; Vekel the Man
  RegisterScreenshotOf(0x00013380, "Skyrim.esm")
  ; Verner Rock-Chucker
  RegisterScreenshotOf(0x00013665, "Skyrim.esm")
  ; Vex
  RegisterScreenshotOf(0x0001CD90, "Skyrim.esm")
  ; Viarmo
  RegisterScreenshotOf(0x000132AD, "Skyrim.esm")
  ; Vigdis Salvius
  RegisterScreenshotOf(0x000133BF, "Skyrim.esm")
  ; Vigilance
  RegisterScreenshotOf(0x0009A7AA, "Skyrim.esm")
  ; Vigilant Tyranus
  RegisterScreenshotOf(0x000A733B, "Skyrim.esm")
  ; Vignar Gray-Mane
  RegisterScreenshotOf(0x00013BB5, "Skyrim.esm")
  ; Vilkas Vilkas
  RegisterScreenshotOf(0x0001A694, "Skyrim.esm")
  ; Viola Giordano
  RegisterScreenshotOf(0x00014129, "Skyrim.esm")
  ; Vipir the Fleet
  RegisterScreenshotOf(0x0001CD8F, "Skyrim.esm")
  ; Virkmund
  RegisterScreenshotOf(0x000135F1, "Skyrim.esm")
  ; Vittoria Vici
  RegisterScreenshotOf(0x0001327A, "Skyrim.esm")
  ; Vivienne Onis
  RegisterScreenshotOf(0x000132AE, "Skyrim.esm")
  ; Voada
  RegisterScreenshotOf(0x000133C0, "Skyrim.esm")
  ; Vokun
  RegisterScreenshotOf(0x000327C2, "Skyrim.esm")
  ; Volsung
  RegisterScreenshotOf(0x00041930, "Skyrim.esm")
  ; Vorstag
  RegisterScreenshotOf(0x000B997F, "Skyrim.esm")
  ; Vuljotnaak
  RegisterScreenshotOf(0x000FE430, "Skyrim.esm")
  ; Vulwulf Snow-Shod
  RegisterScreenshotOf(0x00013381, "Skyrim.esm")
  ; Weylin
  RegisterScreenshotOf(0x0009C8AA, "Skyrim.esm")
  ; Wilhelm
  RegisterScreenshotOf(0x000136BB, "Skyrim.esm")
  ; Willem
  RegisterScreenshotOf(0x000661AF, "Skyrim.esm")
  ; Wilmuth
  RegisterScreenshotOf(0x0009CCD9, "Skyrim.esm")
  ; Wolf Guardian Spirit
  RegisterScreenshotOf(0x000E662D, "Skyrim.esm")
  ; Wolf Spirit
  RegisterScreenshotOf(0x000F608C, "Skyrim.esm")
  ; Wujeeta
  RegisterScreenshotOf(0x00013382, "Skyrim.esm")
  ; Wulfgar
  RegisterScreenshotOf(0x0002C6CA, "Skyrim.esm")
  ; Wuunferth the Unliving
  RegisterScreenshotOf(0x00014146, "Skyrim.esm")
  ; Wylandriah
  RegisterScreenshotOf(0x00019DEF, "Skyrim.esm")
  ; Wyndelius Gatharian
  RegisterScreenshotOf(0x0005FFDF, "Skyrim.esm")
  ; Yar gro-Gatuk
  RegisterScreenshotOf(0x000CE087, "Skyrim.esm")
  ; Yatul
  RegisterScreenshotOf(0x0001B077, "Skyrim.esm")
  ; Yngvar the Singer
  RegisterScreenshotOf(0x000133C1, "Skyrim.esm")
  ; Ysolda
  RegisterScreenshotOf(0x00013BAB, "Skyrim.esm")
  ; Zaria
  RegisterScreenshotOf(0x0003A19A, "Skyrim.esm")
  ; Zaynabi
  RegisterScreenshotOf(0x0001B1D0, "Skyrim.esm")
endFunction
