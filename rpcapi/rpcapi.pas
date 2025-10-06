{
  This unit is a temporary placeholder for the Go 'rpcapi' package.
  It provides minimal functions to allow the conversion of dependent units.
}
unit V.RPCAPI;

interface

uses
  System.SysUtils, V.Vite, V.RPC;

// Init initializes the RPC API backend.
procedure Init(const ADataDir, ALogLevel, ATestTokenHexPrivKey, ATestTokenTti: string; ANetID: Cardinal; ATxDexEnable: PBoolean);

// GetPublicApis returns the public APIs.
function GetPublicApis(AVite: TVite): TArray<TAPI>;

// GetApis returns a selection of APIs.
function GetApis(AVite: TVite; const APublicModules: array of string): TArray<TAPI>;

// MergeApis merges two sets of APIs.
function MergeApis(APIs1, APIs2: TArray<TAPI>): TArray<TAPI>;

implementation

procedure Init(const ADataDir, ALogLevel, ATestTokenHexPrivKey, ATestTokenTti: string; ANetID: Cardinal; ATxDexEnable: PBoolean);
begin
  // Placeholder
end;

function GetPublicApis(AVite: TVite): TArray<TAPI>;
begin
  Result := nil; // Placeholder
end;

function GetApis(AVite: TVite; const APublicModules: array of string): TArray<TAPI>;
begin
  Result := nil; // Placeholder
end;

function MergeApis(APIs1, APIs2: TArray<TAPI>): TArray<TAPI>;
var
  len1, len2, i: Integer;
begin
  len1 := Length(APIs1);
  len2 := Length(APIs2);
  SetLength(Result, len1 + len2);
  if len1 > 0 then
    Move(APIs1[0], Result[0], len1 * SizeOf(TAPI));
  if len2 > 0 then
    Move(APIs2[0], Result[len1], len2 * SizeOf(TAPI));
end;

end.