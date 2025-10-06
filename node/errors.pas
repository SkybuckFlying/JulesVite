{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/node/errors.go
}
unit V.Node.Errors;

interface

uses
  System.SysUtils;

type
  ENodeError = class(Exception);
  ENodeDataDirUsed = class(ENodeError);
  ENodeStopped = class(ENodeError);
  ENodeRunning = class(ENodeError);
  EWalletConfigNil = class(ENodeError);

// ConvertFileLockError converts a generic file lock error into a more
// specific ENodeDataDirUsed exception if applicable.
function ConvertFileLockError(const E: Exception): Exception;

implementation

const
  // These are common error codes for file locking violations on Windows.
  // A more platform-agnostic solution would be needed for production.
  DataDirInUseErrnos: array[0..1] of Cardinal = (32, 33); // ERROR_SHARING_VIOLATION, ERROR_LOCK_VIOLATION

function ConvertFileLockError(const E: Exception): Exception;
var
  err: EInOutError;
  code: Cardinal;
begin
  if E is EInOutError then
  begin
    err := E as EInOutError;
    for code in DataDirInUseErrnos do
    begin
      if Cardinal(err.ErrorCode) = code then
        Exit(ENodeDataDirUsed.Create('Data directory already in use'));
    end;
  end;
  Result := E; // Return original exception if not a file lock error
end;

initialization
  // Register exception classes if needed, e.g., for JSON serialization
  // or specific handling frameworks. For now, this is not required.
end.