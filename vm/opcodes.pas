{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/vm/opcodes.go
}
unit V.VM.Opcodes;

interface

uses
  System.SysUtils;

type
  TOpCode = Byte;

const
  // 0x0 range - arithmetic ops.
  opStop = TOpCode(0);
  opAdd = TOpCode(1);
  opMul = TOpCode(2);
  opSub = TOpCode(3);
  opDiv = TOpCode(4);
  opSDiv = TOpCode(5);
  opMod = TOpCode(6);
  opSMod = TOpCode(7);
  opAddMod = TOpCode(8);
  opMulMod = TOpCode(9);
  opExp = TOpCode(10);
  opSignExtend = TOpCode(11);

  // 0x10 range - comparison ops.
  opLT = TOpCode($10);
  opGT = TOpCode($11);
  opSLT = TOpCode($12);
  opSGT = TOpCode($13);
  opEQ = TOpCode($14);
  opIsZero = TOpCode($15);
  opAnd = TOpCode($16);
  opOr = TOpCode($17);
  opXor = TOpCode($18);
  opNot = TOpCode($19);
  opByte = TOpCode($1a);
  opSHL = TOpCode($1b);
  opSHR = TOpCode($1c);
  opSAR = TOpCode($1d);

  // 0x20 range - hash ops.
  opSha3 = TOpCode($20);
  opBlake2b = TOpCode($21);

  // 0x30 range - closure state.
  opAddress = TOpCode($30);
  opBalance = TOpCode($31);
  opOrigin = TOpCode($32);
  opCaller = TOpCode($33);
  opCallValue = TOpCode($34);
  opCallDataLoad = TOpCode($35);
  opCallDataSize = TOpCode($36);
  opCallDataCopy = TOpCode($37);
  opCodeSize = TOpCode($38);
  opCodeCopy = TOpCode($39);
  opGasPrice = TOpCode($3a);
  opExtCodeSize = TOpCode($3b);
  opExtCodeCopy = TOpCode($3c);
  opReturnDataSize = TOpCode($3d);
  opReturnDataCopy = TOpCode($3e);
  opExtCodeHash = TOpCode($3f);

  // 0x40 range - block operations.
  opBlockHash = TOpCode($40);
  opCoinbase = TOpCode($41);
  opTimestamp = TOpCode($42);
  opHeight = TOpCode($43);
  opDifficulty = TOpCode($44);
  opGasLimit = TOpCode($45);
  opTokenId = TOpCode($46);
  opAccountHeight = TOpCode($47);
  opPrevHash = TOpCode($48);
  opFromHash = TOpCode($49);
  opSeed = TOpCode($4a);
  opRandom = TOpCode($4b);

  // 0x50 range - 'storage' and execution.
  opPop = TOpCode($50);
  opMLoad = TOpCode($51);
  opMStore = TOpCode($52);
  opMStore8 = TOpCode($53);
  opSLoad = TOpCode($54);
  opSStore = TOpCode($55);
  opJump = TOpCode($56);
  opJumpI = TOpCode($57);
  opPC = TOpCode($58);
  opMSize = TOpCode($59);
  opGas = TOpCode($5a);
  opJumpDest = TOpCode($5b);

  // 0x60 range.
  opPush1 = TOpCode($60);
  opPush2 = TOpCode($61);
  opPush3 = TOpCode($62);
  opPush4 = TOpCode($63);
  opPush5 = TOpCode($64);
  opPush6 = TOpCode($65);
  opPush7 = TOpCode($66);
  opPush8 = TOpCode($67);
  opPush9 = TOpCode($68);
  opPush10 = TOpCode($69);
  opPush11 = TOpCode($6a);
  opPush12 = TOpCode($6b);
  opPush13 = TOpCode($6c);
  opPush14 = TOpCode($6d);
  opPush15 = TOpCode($6e);
  opPush16 = TOpCode($6f);
  opPush17 = TOpCode($70);
  opPush18 = TOpCode($71);
  opPush19 = TOpCode($72);
  opPush20 = TOpCode($73);
  opPush21 = TOpCode($74);
  opPush22 = TOpCode($75);
  opPush23 = TOpCode($76);
  opPush24 = TOpCode($77);
  opPush25 = TOpCode($78);
  opPush26 = TOpCode($79);
  opPush27 = TOpCode($7a);
  opPush28 = TOpCode($7b);
  opPush29 = TOpCode($7c);
  opPush30 = TOpCode($7d);
  opPush31 = TOpCode($7e);
  opPush32 = TOpCode($7f);

  opDup1 = TOpCode($80);
  opDup2 = TOpCode($81);
  opDup3 = TOpCode($82);
  opDup4 = TOpCode($83);
  opDup5 = TOpCode($84);
  opDup6 = TOpCode($85);
  opDup7 = TOpCode($86);
  opDup8 = TOpCode($87);
  opDup9 = TOpCode($88);
  opDup10 = TOpCode($89);
  opDup11 = TOpCode($8a);
  opDup12 = TOpCode($8b);
  opDup13 = TOpCode($8c);
  opDup14 = TOpCode($8d);
  opDup15 = TOpCode($8e);
  opDup16 = TOpCode($8f);

  opSwap1 = TOpCode($90);
  opSwap2 = TOpCode($91);
  opSwap3 = TOpCode($92);
  opSwap4 = TOpCode($93);
  opSwap5 = TOpCode($94);
  opSwap6 = TOpCode($95);
  opSwap7 = TOpCode($96);
  opSwap8 = TOpCode($97);
  opSwap9 = TOpCode($98);
  opSwap10 = TOpCode($99);
  opSwap11 = TOpCode($9a);
  opSwap12 = TOpCode($9b);
  opSwap13 = TOpCode($9c);
  opSwap14 = TOpCode($9d);
  opSwap15 = TOpCode($9e);
  opSwap16 = TOpCode($9f);

  // 0xa0 range - logging ops.
  opLog0 = TOpCode($a0);
  opLog1 = TOpCode($a1);
  opLog2 = TOpCode($a2);
  opLog3 = TOpCode($a3);
  opLog4 = TOpCode($a4);

  // 0xf0 range - closures.
  opCreate = TOpCode($f0);
  opCall = TOpCode($f1);
  opCall2 = TOpCode($f2);
  opReturn = TOpCode($f3);
  opDelegateCall = TOpCode($f4);
  opStaticCall = TOpCode($fa);
  opRevert = TOpCode($fd);
  opSelfDestruct = TOpCode($ff);

type
  TOpCodeHelper = record helper for TOpCode
    function IsPush: Boolean;
    function IsStaticJump: Boolean;
    function ToString: string;
  end;

implementation

uses System.Generics.Collections;

var
  OpCodeToStringMap: TDictionary<TOpCode, string>;

function TOpCodeHelper.IsPush: Boolean;
begin
  Result := (Self >= opPush1) and (Self <= opPush32);
end;

function TOpCodeHelper.IsStaticJump: Boolean;
begin
  Result := Self = opJump;
end;

function TOpCodeHelper.ToString: string;
begin
  if OpCodeToStringMap.TryGetValue(Self, Result) then
    Exit(Result)
  else
    Exit(Format('Missing opcode 0x%x', [Byte(Self)]));
end;

initialization
  OpCodeToStringMap := TDictionary<TOpCode, string>.Create;
  OpCodeToStringMap.Add(opStop, 'STOP');
  OpCodeToStringMap.Add(opAdd, 'ADD');
  // ... and so on for all opcodes
end.