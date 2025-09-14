library tpaex;

{$mode objfpc}{$H+}

uses
  sysutils, tpa, types, files;

{$I simbaplugin.inc}


procedure Lape_TPAMatrix(const Params: PParamArray; const Result: Pointer); cdecl;
begin
  P2DBoolArray(Result)^ := TPAMatrix(PPointArray(Params^[0])^);
end;

procedure Lape_AStarTPAEx(const Params: PParamArray; const Result: Pointer); cdecl;
begin
  PPointArray(Result)^ := AStarTPAEx(PPointArray(Params^[0])^, P2DFloatArray(Params^[1])^, PPoint(Params^[2])^, PPoint(Params^[3])^, PBoolean(Params^[4])^);
end;

procedure Lape_AStarTPA(const Params: PParamArray; const Result: Pointer); cdecl;
begin
  PPointArray(Result)^ := AStarTPA(PPointArray(Params^[0])^, PPoint(Params^[1])^, PPoint(Params^[2])^, PBoolean(Params^[3])^);
end;

procedure Lape_FileReadBytes(const Params: PParamArray; const Result: Pointer); cdecl;
begin
  PByteArray(Result)^ := FileReadBytes(PString(Params^[0])^);
end;

procedure Lape_FileReadBytesRange(const Params: PParamArray; const Result: Pointer); cdecl;
begin
  PByteArray(Result)^ := FileReadBytesRange(PString(Params^[0])^, PInteger(Params^[1])^, PInteger(Params^[2])^);
end;

begin
  addGlobalFunc('function TPAMatrix(tpa: TPointArray): TBooleanMatrix; native;', @Lape_TPAMatrix);
  addGlobalFunc('function AStarTPAEx(tpa: TPointArray; out paths: TSingleMatrix; start, goal: TPoint; diagonalTravel: Boolean): TPointArray; native;', @Lape_AStarTPAEx);
  addGlobalFunc('function AStarTPA(tpa: TPointArray; start, goal: TPoint; diagonalTravel: Boolean): TPointArray; native;', @Lape_AStarTPA);
  addGlobalFunc('function OpenFileReadBytes(filename: String): TByteArray; native;', @Lape_FileReadBytes);
  addGlobalFunc('function OpenFileReadBytesRange(filename: String; start, finish: Integer): TByteArray; native;', @Lape_FileReadBytesRange);
end.
