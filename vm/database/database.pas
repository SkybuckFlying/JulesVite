{
  This unit is a temporary placeholder for the Go 'vm/database' package.
  It provides a minimal IDatabase interface to allow the conversion of dependent units.
}
unit V.VM.Database;

interface

uses
  System.SysUtils, System.Numerics,
  V.Common.Types;

type
  IDatabase = interface
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    function CreateAccount(const Addr: TAddress): Boolean;
    function HasSuicided(const Addr: TAddress): Boolean;
    procedure Suicide(const Addr: TAddress);
    function GetBalance(const Addr: TAddress; const Token: TTokenId): TBigInteger;
    procedure AddBalance(const Addr: TAddress; const Token: TTokenId; Amount: TBigInteger);
    procedure SubBalance(const Addr: TAddress; const Token: TTokenId; Amount: TBigInteger);
    function GetNonce(const Addr: TAddress): UInt64;
    procedure SetNonce(const Addr: TAddress; Nonce: UInt64);
    function GetCodeHash(const Addr: TAddress): THash;
    function GetCode(const Addr: TAddress): TBytes;
    procedure SetCode(const Addr: TAddress; const Code: TBytes);
    function GetState(const Addr: TAddress; const Hash: THash): THash;
    procedure SetState(const Addr: TAddress; const Key, Value: THash);
    function Exist(const Addr: TAddress): Boolean;
  end;

implementation

end.