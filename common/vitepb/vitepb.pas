unit V.Common.VitePB;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Proto;

type
  // This unit will contain the Delphi representations of the protobuf messages
  // defined in the .proto files. For now, it's a placeholder.

  TConsensusPoint = class(TInterfacedObject, IMessage)
    // Placeholder fields
  public
    Hash: TBytes;
    PrevHash: TBytes;
    Contents: TArray<TPointContent>;
    Votes: TArray<TPointVoteContent>;
  end;

  TPointContent = class(TInterfacedObject, IMessage)
  public
    Address: TBytes;
    ENum: UInt32;
    FNum: UInt32;
  end;

  TPointVoteContent = class(TInterfacedObject, IMessage)
  public
    Name: string;
    VoteCnt: TBytes;
  end;

implementation

end.