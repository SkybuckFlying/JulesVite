{
  This unit is a temporary placeholder for the Go 'ledger/chain/sync_cache' package.
  It provides a minimal implementation to allow the conversion of dependent units.
}
unit V.Ledger.Chain.SyncCache;

interface

uses
  System.SysUtils, V.Interfaces;

// NewSyncCache creates a new sync cache.
function NewSyncCache(const Path: string): ISyncCache;

implementation

type
  TSyncCache = class(TInterfacedObject, ISyncCache)
    // Placeholder implementation
  end;

function NewSyncCache(const Path: string): ISyncCache;
begin
  Result := TSyncCache.Create; // Placeholder
end;

end.