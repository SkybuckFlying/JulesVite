{
  This unit is a temporary placeholder for the Go 'vitepb' package.
  It provides minimal class definitions for protobuf messages to allow
  the conversion of dependent units.
}
unit V.Common.VitePB;

interface

uses
  System.SysUtils, V.Proto, V.Interfaces.Core;

type
  // Protobuf message placeholders
  TProtoHashHeight = class(TInterfacedObject, IMessage)
  public
    Hash: TBytes;
    Height: UInt64;
  end;

  TProtoSnapshotBlock = class(TInterfacedObject, IMessage)
    // Placeholder - properties would be defined by the .proto file
  end;

  TProtoAccountBlock = class(TInterfacedObject, IMessage)
    // Placeholder - properties would be defined by the .proto file
  end;

  TGetSnapshotBlocks = class(TInterfacedObject, IMessage)
  public
    From: TProtoHashHeight;
    Count: UInt64;
    Forward: Boolean;
    constructor Create;
  end;

  TSnapshotBlocks = class(TInterfacedObject, IMessage)
  public
    Blocks: array of TProtoSnapshotBlock;
  end;

  TGetAccountBlocks = class(TInterfacedObject, IMessage)
  public
    Address: TBytes;
    From: TProtoHashHeight;
    Count: UInt64;
    Forward: Boolean;
    constructor Create;
  end;

  TAccountBlocks = class(TInterfacedObject, IMessage)
  public
    Blocks: array of TProtoAccountBlock;
  end;

  TNewSnapshotBlock = class(TInterfacedObject, IMessage)
  public
    Block: TProtoSnapshotBlock;
    TTL: Int32;
  end;

  TNewAccountBlock = class(TInterfacedObject, IMessage)
  public
    Block: TProtoAccountBlock;
    TTL: Int32;
  end;

  TProtoHashHeightPoint = class(TInterfacedObject, IMessage)
  public
    Point: TProtoHashHeight;
    Size: UInt64;
    constructor Create;
  end;

  TProtoHashHeightList = class(TInterfacedObject, IMessage)
  public
    Points: array of TProtoHashHeightPoint;
  end;

  TGetHashHeightList = class(TInterfacedObject, IMessage)
  public
    From: array of TProtoHashHeight;
    Step: UInt64;
    To: UInt64;
  end;

  TPeerError = class(TInterfacedObject, IMessage)
    // Placeholder
  end;

implementation

{ TGetSnapshotBlocks }

constructor TGetSnapshotBlocks.Create;
begin
  inherited;
  From := TProtoHashHeight.Create;
end;

{ TGetAccountBlocks }

constructor TGetAccountBlocks.Create;
begin
  inherited;
  From := TProtoHashHeight.Create;
end;

{ TProtoHashHeightPoint }

constructor TProtoHashHeightPoint.Create;
begin
  inherited;
  Point := TProtoHashHeight.Create;
end;

end.