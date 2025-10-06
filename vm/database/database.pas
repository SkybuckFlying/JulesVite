unit V.VM.Database;

interface

uses
  System.SysUtils,
  V.Common.Types,
  Go.Big;

type
  IDatabase = interface
    ['{B2C3D4E5-F6A7-4B8C-AD9E-8F706B5C4D3E}']
    function CreateAccount(address: TAddress);
    function SubBalance(address: TAddress; amount: IBigInt);
    function AddBalance(address: TAddress; amount: IBigInt);
    function GetBalance(address: TAddress): IBigInt;
    function GetNonce(address: TAddress): UInt64;
    procedure SetNonce(address: TAddress; nonce: UInt64);
    function GetCodeHash(address: TAddress): THash;
    procedure SetCode(address: TAddress; code: TBytes);
    function GetCode(address: TAddress): TBytes;
    procedure SetState(address: TAddress; key: THash; value: TBytes);
    function GetState(address: TAddress; key: THash): TBytes;
    function Suicide(address: TAddress): Boolean;
    function HasSuicided(address: TAddress): Boolean;
    // ... other database methods
  end;

implementation

end.