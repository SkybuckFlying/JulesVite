unit V.Net.SyncServer;

interface

uses
  System.SysUtils,
  V.Net.Peer;

type
  ISyncServer = interface
    ['{B8C9D0E1-F2A3-4182-9384-757051423455}']
    // This is a placeholder for the sync server interface, which likely
    // handles requests from other peers for synchronization.
    procedure Start;
    procedure Stop;
  end;

implementation

end.