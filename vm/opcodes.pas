unit V.VM.Opcodes;

interface

type
  TOpCode = Byte;

const
  // Define VM opcodes as constants here.
  // This is just a small sample.
  opStop = $00;
  opAdd = $01;
  opMul = $02;
  opSub = $03;
  opDiv = $04;
  opSDiv = $05;
  opMod = $06;
  opSMod = $07;
  opAddMod = $08;
  opMulMod = $09;
  opExp = $0a;
  opSignExtend = $0b;

  opLt = $10;
  opGt = $11;
  opSLt = $12;
  opSGt = $13;
  opEq = $14;
  opIsZero = $15;
  opAnd = $16;
  opOr = $17;
  opXor = $18;
  opNot = $19;
  opByte = $1a;

  opSha3 = $20;

  opAddress = $30;
  opBalance = $31;
  opOrigin = $32;
  opCaller = $33;
  opCallValue = $34;
  opCallDataLoad = $35;
  opCallDataSize = $36;
  opCallDataCopy = $37;
  opCodeSize = $38;
  opCodeCopy = $39;
  opGasPrice = $3a;
  opExtCodeSize = $3b;
  opExtCodeCopy = $3c;

  opPush1 = $60;
  opPush2 = $61;
  // ... and so on up to PUSH32
  opPush32 = $7f;

  opDup1 = $80;
  // ... and so on up to DUP16
  opDup16 = $8f;

  opSwap1 = $90;
  // ... and so on up to SWAP16
  opSwap16 = $9f;

  opLog0 = $a0;
  // ... and so on up to LOG4
  opLog4 = $a4;

  opCreate = $f0;
  opCall = $f1;
  opCallCode = $f2;
  opReturn = $f3;
  opDelegateCall = $f4;

  opStaticCall = $fa;

  opRevert = $fd;
  opSuicide = $ff;

implementation

end.