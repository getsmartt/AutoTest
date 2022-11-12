{
  Export NPCs Test Suite - AutoTest_NPCs_Run.json
  
}
unit AutoTest_MPCs;

var
  slCsv: TStringList;
  i: string;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
  AddMessage('Export NPCs Test Suite...');
  slCsv := TStringList.Create;
  Result := 0;
  slCsv.Add ('{');
  slCsv.Add ('	"stringList": {');
  slCsv.Add ('		"tests_to_run": [');
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  worldElement : IwbContainer;
  modFile : IwbFile;
  idxMaster : integer;
  masters : string;
begin
  // AddMessage('Processing: ' + FullPath(e));
   if (Signature(e) = 'NPC_') and (ElementExists(e, 'FULL')) then begin
    slCsv.Add(
      i + '			' +
      '"' + GetFileName(GetFile(MasterOrSelf(e))) + '/0x' +
      IntToHex(FixedFormID(e), 8) + '/' +
      GetFileName(GetFile(e)) + '"'
      
    );
    i := ',';
  end;
  Result := 0;
end;

// Called after processing
// You can remove it if script doesn't require finalization code
function Finalize: integer;
begin
  slCsv.Add ('		]');
  slCsv.Add ('	}');
  slCsv.Add ('}');
  slCsv.SaveToFile(DataPath + 'SKSE\Plugins\StorageUtilData\AutoTest_NPCs_Run.json');
  slCsv.Free;
  AddMessage('Export done in ' + DataPath + 'SKSE\Plugins\StorageUtilData\AutoTest_NPCs_Run.json');
  // Application.Terminate;
  // ExitProcess(0);
  Result := 0;
end;

end.
