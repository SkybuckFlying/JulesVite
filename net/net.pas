unit V.Net.Net;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Net.Peer,
  V.Net.Message,
  V.Net.Syncer,
  V.Net.SyncServer,
  V.Net.Broadcaster,
  V.Net.MsgHandler,
  V.Net.BlockFeed;

type
  INet = interface
    ['{C9D0E1F2-A3B4-4283-9485-767152434567}']
    // This is a placeholder for the main network interface.
    procedure Start;
    procedure Stop;
  end;

implementation

end.