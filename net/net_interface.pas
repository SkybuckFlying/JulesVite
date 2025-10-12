unit V.Net.NetIntf;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Net.Peer;

type
  INetIntf = interface
    ['{D0E1F2A3-B4C5-4384-9586-777253445678}']
    // This is another placeholder for a network interface, likely a more
    // specific or internal one compared to the one in V.Net.Net.
    function GetPeer(id: string): IPeer;
  end;

implementation

end.