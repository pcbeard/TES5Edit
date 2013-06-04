﻿{
  根据 ScaleXY 将衍生位置调整到相关中心点。
  脚本必须应用到 worldspace 。
}
unit userscript;

const
  CenterX = 28672; // center X point to scale from
  CenterY = 63424; // center Y point to scale from
  ScaleXY = 1.25;  // scale factor
  CellSize = 4096;

var
  slCELL: TStringList;
  Refs: array [0..50000] of IInterface;
  RefsCount: integer;

function Initialize: integer;
begin
  slCELL := TStringList.Create;
  RefsCount := 0;
end;

function Process(e: IInterface): integer;
var
  Sig, s: string;
begin
  Sig := Signature(e);
  
  // build a list of temporary cells
  // persistent references always remain in 0,0 persistent cell, so we don't need it
  if (Sig = 'CELL') and not GetIsPersistent(e) then begin
    s := Format('%d,%d', [
      Integer(GetElementNativeValues(e, 'XCLC\X')),
      Integer(GetElementNativeValues(e, 'XCLC\Y'))
    ]);
    if slCELL.IndexOf(s) = -1 then
      slCELL.AddObject(s, GetLoadOrderFormID(e))
    else
      AddMessage('重复记录 ' + s);
  end

  else

  // build a list of all references
  if (Sig = 'REFR') or (Sig = 'PGRE') or (Sig = 'PMIS') or (Sig = 'ACHR') or (Sig = 'ACRE') or
     (Sig = 'PARW') or (Sig = 'PBAR') or (Sig = 'PBEA') or (Sig = 'PCON') or (Sig = 'PFLA') or
     (Sig = 'PHZD')
  then begin
    Refs[RefsCount] := e;
    Inc(RefsCount);
  end

  else

  // remove pathgrids and navmeshes
  if (Sig = 'PGRD') or (Sig = 'NAVM') then begin
    RemoveNode(e);
  end;
end;

function Finalize: integer;
var
  i, idx, formid: integer;
  x, y: integer;
  s: string;
begin
  // for each reference
  for i := 0 to RefsCount - 1 do begin
    // update position
    SetElementNativeValues(Refs[i], 'DATA\方位\X', (GetElementNativeValues(Refs[i], 'DATA\方位\X') - CenterX)*ScaleXY + CenterX);
    SetElementNativeValues(Refs[i], 'DATA\方位\Y', (GetElementNativeValues(Refs[i], 'DATA\方位\Y') - CenterY)*ScaleXY + CenterY);
    // move temporary references to another cell if needed
    if not GetIsPersistent(Refs[i]) then begin
      // new cell coordinates
      x := GetElementNativeValues(Refs[i], 'DATA\方位\X');
      y := GetElementNativeValues(Refs[i], 'DATA\方位\Y');
      x := x div CellSize;
      y := y div CellSize;
      s := Format('%d,%d', [x, y]);
      // find that cell in list
      idx := slCELL.IndexOf(s);
      if idx <> - 1 then begin
        // get FormID of the current cell
        formid := GetElementNativeValues(Refs[i], 'Cell');
        // move reference if current cell differs from new cell
        if formid <> Integer(slCELL.Objects[idx]) then
          SetElementNativeValues(Refs[i], 'Cell', Integer(slCELL.Objects[idx]));
      end else
        AddMessage(Format('编号 %s 场景（来源于 %s）方位调整为 (%s,%s)', [
          s,
          Name(Refs[i]),
          GetElementEditValues(Refs[i], 'DATA\方位\X'),
          GetElementEditValues(Refs[i], 'DATA\方位\Y')
        ]));
    end;
  end;
  
  slCELL.Free;
end;



end.