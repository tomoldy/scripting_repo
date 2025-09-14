unit files;

{$mode objfpc}{$H+}

{$modeswitch advancedrecords}
{$modeswitch arrayoperators}

{$scopedenums on}

{$IFOPT D-} // No debug info = enable max optimization
  {$OPTIMIZATION LEVEL4}
  {$OPTIMIZATION noORDERFIELDS} // need same field ordering in script
  {$OPTIMIZATION noDEADSTORE}   // buggy as of FPC .2.2
{$ENDIF}

interface

uses
  SysUtils;

function FileReadBytes(const fileName: String): TBytes;
function FileReadBytesRange(const fileName: String; start, finish: Integer): TBytes;

implementation

function FileReadBytes(const fileName: String): TBytes;
var
  F: THandle;
  FileLen: Integer;
  BytesRead: Integer;
begin
  F := FileOpen(fileName, fmOpenRead or fmShareDenyNone);
  if F = feInvalidHandle then
  begin
    Result := [];
    Exit;
  end;

  try
    FileLen := FileSeek(F, 0, 2);
    if (FileLen <= 0) then
    begin
      Result := [];
      Exit;
    end;

    SetLength(Result, FileLen);

    FileSeek(F, 0, 0);
    BytesRead := FileRead(F, Result[0], Length(Result));

    if BytesRead < Length(Result) then
      Result := []; // Handle failure (e.g., partial read)

  finally
    FileClose(F);
  end;
end;

function FileReadBytesRange(const fileName: String; start, finish: Integer): TBytes;
var
  F: THandle;
  FileLen: Integer;
  ReadLen: Integer;
  BytesRead: Integer;
begin
  F := FileOpen(fileName, fmOpenRead or fmShareDenyNone);
  if F = feInvalidHandle then
  begin
    Result := [];
    Exit;
  end;

  try
    // Get the file size
    FileLen := FileSeek(F, 0, 2); // Seek to the end of the file to get its size
    if (FileLen <= 0) or (start < 0) or (finish < start) or (finish >= FileLen) then
    begin
      Result := [];
      Exit;
    end;

    // Calculate the length to read (from start to finish)
    ReadLen := finish - start + 1;

    // Set the result array to the required length
    SetLength(Result, ReadLen);

    // Seek to the start position and read the bytes
    FileSeek(F, start, 0);
    BytesRead := FileRead(F, Result[0], ReadLen);

    if BytesRead < ReadLen then
      Result := []; // Handle failure (e.g., partial read)

  finally
    FileClose(F);
  end;
end;

end.

