{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/CODER/PYTHONLIB-TP)
  @abstract(Target: Turbo Pascal 7, Free Pascal 3.2)
}

Unit PYTHONLB;

INTERFACE

Function  Bin(X:Byte):String;
Procedure DivMod(Dividend,Divisor:LongInt;Var R,Rem:LongInt);
Function  Eval(Infix:String):Real;
Procedure ExecFile(Cmd,Param:String);
Function  Float(n:String):Real;
Function  Hex(value:LongInt):String;
Function  Long(n:String):LongInt;
Function  Oct(value:Byte):String;
Function  POW(a,b:Real):Real;
Function  Range(Start,Stop,Step:Integer):Pointer;
Function  Raw_Input(Prompt:String):String;

IMPLEMENTATION

Uses DOS;

Var
 Stack:Array[0..100]of Char;
 TopOfStack:Byte;
 resultStack:Array[0..100]of Real;
 TopOfStackInt:Byte;
 I:Byte;
 AllParam:String;
 ResultEval:Real;

Function TrimZero(S:String):String;
Var
 I:Byte;
Begin
 For I:=1to Length(S)do Begin
  If S[I]<>'0'Then Begin
   TrimZero:=Copy(S,I,255);
   Exit;
  End;
 End;
 TrimZero:=S;
End;

Function Bin(X:Byte):String;
Var
 I:Integer;
 S:String;
Begin
 If X=0 Then Begin
  Bin:='0';
  Exit;
 End;
 S:='';
 For I:=0 to 7 do Begin
  S:=Chr(Byte('0')+((X shr I)and 1))+S;
 End;
 Bin:='0b'+TrimZero(S);
End;

Procedure DivMod(Dividend,Divisor:LongInt;Var R,Rem:LongInt);Begin
 If Dividend<0 Then begin
  Dividend:=-Dividend;
  R:=-(Dividend Div Divisor);
  Rem:=-(Dividend+(R*Divisor));
 End
  Else
 Begin
  R:=Dividend Div Divisor;
  Rem:=Dividend-(R*Divisor);
 End;
End;

Procedure StackPushChar(C:Char);Begin
 If TopOfStack>=High(Stack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  Stack[TopOfStack]:=C;
  Inc(TopOfStack);
 End;
End;

Function StackPop:String;
Var
 S:String;
 Err:Word;
Begin
 Dec(TopOfStack);
 If TopOfStack<1Then Begin
  WriteLn('Pile vide');
  Halt;
 End
  Else
 StackPop:=Stack[TopOfStack];
End;

Function StackPeek:Char;Begin
 StackPeek:=Stack[TopOfStack-1];
End;

Procedure ResultStackPush(C:Real);Begin
 If TopOfStackInt>=High(ResultStack)Then Begin
  WriteLn('Pile pleine!');
  Halt;
 End
  Else
 Begin
  ResultStack[TopOfStackInt]:=C;
  Inc(TopOfStackInt);
 End;
End;

Function ResultStackPop:Real;Begin
 Dec(TopOfStackInt);
 If TopOfStackInt<1Then Begin
  WriteLn('Pile vide');
  Halt;
 End
  Else
 ResultStackPop:=ResultStack[TopOfStackInt];
End;

Function Eval(Infix:String):Real;
Var
 I:Byte;
 Top,P_2:Char;
 AppendOk:Boolean;
 _Result,P,P2:Real;
 Err:Word;
 PostFix:String;
 Value:String;
 Exposant:Boolean;
Begin
 TopOfStack:=1;
 TopOfStackInt:=1;
 PostFix:='';
 If Infix[1]='-'Then Infix:='(0)'+Infix;
 I:=1;
 Repeat
  If Infix[I]in['0'..'9']Then Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Infix[I]in['E','e']Then Begin
     Exposant:=True;
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If(Exposant)and(Infix[I]in['-','+'])Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    If Infix[I]in['0'..'9','.']Then Begin
     Value:=Value+Infix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Infix);
   PostFix:=PostFix+'('+Value+')';
  End
  Else If Infix[I]='('Then Begin
   StackPushChar(Infix[I]);
   Inc(I);
  End
  Else If Infix[I]in['*','+','-','/']Then Begin
   While(TopOfStack>1)and(StackPeek <> '(')do Begin
    Top:=StackPeek;
    P_2:=Infix[I];
    AppendOk:=True;
    If(Top='+')and(P_2='*')Then AppendOk:=False
    Else If(Top='*')and(P_2='-')Then AppendOk:=True
    Else If(Top='+')and(P_2='-')Then AppendOk:=True;
    If(AppendOk)Then PostFix:=PostFix+StackPop
                Else Break;
   End;
   StackPushChar(Infix[I]);
   Inc(I);
  End
  Else If Infix[I]=')'Then Begin
   While(TopOfStack>1)and(StackPeek<>'(')do PostFix:=PostFix+StackPop;
   If TopOfStack>1Then StackPop;
   Inc(I);
  End
   Else
  Inc(I);
 Until I>Length(Infix);
 While(TopOfStack>1)do PostFix:=PostFix+StackPop;
  { Transformation en POSTFIX }
 I:=1;
 Repeat
  If PostFix[I]in['*','+','-','/']Then Begin
   P:=ResultStackPop;
   P2:=ResultStackPop;
   Case PostFix[I]of
    '+':_Result:=P2+P;
    '-':_Result:=P2-P;
    '*':_Result:=P2*P;
    '/':_Result:=P2/P;
    Else _Result:=-1;
   End;
   ResultStackPush(_Result);
  End
   Else
  Begin
   Value:='';
   Exposant:=False;
   Repeat
    If Postfix[I]in['0'..'9','.']Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Postfix[I]in['E','e'])Then Begin
     Exposant:=True;
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    If(Value<>'')and(Exposant)and(Postfix[I]in['+','-'])Then Begin
     Value:=Value+Postfix[I];
     Inc(I);
    End
     Else
    Break;
   Until I>Length(Postfix);
   If Value<>''Then Begin
    Val(Value,_Result,Err);
    ResultStackPush(_Result);
   End;
  End;
  Inc(I);
 Until I>Length(Postfix);
 Eval:=ResultStackPop;
End;

Procedure ExecFile(Cmd,Param:String);Begin
 Exec(Cmd,Param);
End;


Function Float(n:String):Real;
Var
 R:Real;
 Err:Word;
Begin
 Val(n,R,Err);
 Float:=R;
End;

Function Hex(value:LongInt):String;
Const
 matrix:Array[0..15]of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
Begin
 If value=0 Then Begin
  Hex:='0x0';
  Exit;
 End;
 Hex:='0x'+TrimZero(matrix[(value shr 28) and $0F]+matrix[(value shr 24)and $F]+
               matrix[(value shr 20) and $0F]+matrix[(value shr 16)and $F]+
               matrix[(value shr 12) and $0F]+matrix[(value shr 8)and $F]+
               matrix[(value shr 4) and $0F]+matrix[value and $F]);
End;

Function Long(n:String):LongInt;
Var
 R:LongInt;
 Err:Word;
Begin
 Val(n,R,Err);
 Long:=R;
End;

Function Oct(value:Byte):String;
Const
 matrix:Array[0..7]of Char = ('0','1','2','3','4','5','6','7');
Begin
 If value=0 Then Begin
  Oct:='0';
  Exit;
 End;
 Oct:=TrimZero(matrix[(value shr 6) and 7]+
               matrix[(value shr 3) and 7]+
               matrix[value and 7]);
End;

Function POW(a,b:Real):Real;
Var
 p:Real;
 I:Integer;
Begin
 p:=1;
 For i:=1 to Trunc(b) do Begin
  p:=p*a;
 End;
 Pow:=p;
End;

Function Range(Start,Stop,Step:Integer):Pointer;
Type
 TLongInt=Array[0..999]of LongInt;
Var
 P:^TLongInt;
 NumItem,I:Integer;
 Value:LongInt;
Begin
 NumItem:=(Stop-Start+1)div Step;
 GetMem(P,SizeOf(LongInt)*NumItem);
 If(P<>NIL)Then Begin
  Value:=Start;
  For I:=0 to NumItem-1 do Begin
   P^[I]:=Value;
   Inc(Value,Step);
  End;
 End;
 Range:=P;
End;

Function Raw_Input(Prompt:String):String;
Var
 Response:String;
Begin
 Write(Prompt);
 ReadLn(Response);
 Raw_Input:=Response;
End;

END.