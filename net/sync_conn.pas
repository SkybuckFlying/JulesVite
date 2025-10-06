unit V.Net.SyncConn;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Net.Peer;

type
  ISyncConn = interface
    ['{E5F6A7B8-C9D0-4E8F-9081-726D5E4F3012}']
    // This is a placeholder for the sync connection interface.
    function GetPeer: IPeer;
  end;

implementation

end.