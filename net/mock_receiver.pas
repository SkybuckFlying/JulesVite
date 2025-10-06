{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/mock_receiver.go
}
unit V.Net.MockReceiver;

interface

uses
  System.SysUtils,
  V.Interfaces.Core, V.Net.Interface, V.Net.Fetcher;

type
  TMockReceiver = class(TInterfacedObject, IBlockReceiver)
  public
    procedure ReceiveAccountBlock(Block: PAccountBlock; Source: TBlockSource);
    procedure ReceiveSnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
  end;

implementation

{ TMockReceiver }

procedure TMockReceiver.ReceiveAccountBlock(Block: PAccountBlock; Source: TBlockSource);
begin
  // No-op
end;

procedure TMockReceiver.ReceiveSnapshotBlock(Block: PSnapshotBlock; Source: TBlockSource);
begin
  // No-op
end;

end.