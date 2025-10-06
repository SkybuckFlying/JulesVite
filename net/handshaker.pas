unit V.Net.Handshaker;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Net.Codec,
  V.Net.Message;

type
  THandshake = record
    // Placeholder for handshake data
  end;

  IHandshaker = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3F}']
    function Handshake(peer: TObject): TTuple<THandshake, Error>; // TObject is a placeholder for peer
  end;

implementation

end.