unit V.Net.SyncState;

interface

uses
  System.SysUtils,
  V.Common.Types;

type
  TSyncState = (ssUnknown, ssSyncing, ssSynced);

  ISyncState = interface
    ['{C3D4E5F6-A7B8-4C8D-9E8F-706B5C4D3E2E}']
    function GetState: TSyncState;
    procedure SetState(state: TSyncState);
    function GetBestPeer: TObject; // Placeholder for Peer
  end;

implementation

end.