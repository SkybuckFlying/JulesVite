unit V.Net.Syncer;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Net.SyncState,
  V.Net.Skeleton,
  V.Net.SyncDownloader,
  V.Net.SyncCacheReader,
  V.Ledger.Chain.Interface;

type
  ISyncer = interface
    ['{A7B8C9D0-E1F2-4081-9283-746F50413234}']
    // This is a placeholder for the main syncer interface.
    procedure Start;
    procedure Stop;
  end;

implementation

end.