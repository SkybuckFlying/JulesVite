{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/common/utils.go
}
unit V.Common.Utils;

interface

uses
  System.SysUtils, System.Generics.Collections;

// SyncMapLen returns the number of items in a dictionary.
function SyncMapLen<TKey, TValue>(const AMap: TDictionary<TKey, TValue>): Cardinal;

// ToJson converts an item to its JSON string representation.
function ToJson(AItem: TObject): string;

// Crit logs a critical error and then halts the application.
procedure Crit(const Msg: string; const-var-args Args: array of const);

implementation

uses
  System.Json, System.Threading, V.Log15;

function SyncMapLen<TKey, TValue>(const AMap: TDictionary<TKey, TValue>): Cardinal;
begin
  if AMap = nil then
    Result := 0
  else
    Result := AMap.Count;
end;

function ToJson(AItem: TObject): string;
begin
  try
    Result := TJson.ObjectToJsonString(AItem);
  except
    on E: Exception do
      Result := 'err: ' + E.Message;
  end;
end;

procedure Crit(const Msg: string; const-var-args Args: array of const);
var
  Log: TLogger;
begin
  Log := TLogger.New('module', 'crit');
  try
    Log.Error(Msg, Args);
    Writeln(Msg);
    TThread.Sleep(2000);
    Log.Crit(Msg, Args);
  finally
    Log.Free;
  end;
end;

end.