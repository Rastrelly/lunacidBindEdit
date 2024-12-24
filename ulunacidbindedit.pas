unit uLunacidBindEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TForm1 }

  strArr = array of string;

  inpLst = record
    name:string;
    bindings:strArr;
  end;

  TForm1 = class(TForm)
    btn_open: TButton;
    btn_parse: TButton;
    btn_add_bind: TButton;
    btn_construct: TButton;
    Button2: TButton;
    btn_set_bind: TButton;
    btn_delete_bind: TButton;
    btn_preset_use: TButton;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    edt_bind_code: TEdit;
    edt_key: TEdit;
    ed_filename: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    ListBox3: TListBox;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure btn_add_bindClick(Sender: TObject);
    procedure btn_constructClick(Sender: TObject);
    procedure btn_delete_bindClick(Sender: TObject);
    procedure btn_openClick(Sender: TObject);
    procedure btn_parseClick(Sender: TObject);
    procedure btn_preset_useClick(Sender: TObject);
    procedure btn_set_bindClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ListBox2SelectionChange(Sender: TObject; User: boolean);
    procedure ListBox3SelectionChange(Sender: TObject; User: boolean);
    procedure redrawBList(var sid:integer);
  private

  public

  end;

var
  Form1: TForm1;

  dataFile:TextFile;
  filePath:string;
  fileText:strArr;

  filePreamble:string; //keep here the header

  storedBinds:array of inpLst;

  selBind,selBindId:integer;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btn_openClick(Sender: TObject);
var cLine:string;
    i:integer;
begin
  if (OpenDialog1.Execute) then
  begin
    //prep
    setlength(fileText,0);
    ListBox1.Clear;
    filePath:=OpenDialog1.FileName;
    ed_filename.Text:=filePath;

    //file ops
    AssignFile(dataFile,filePath);
    Reset(dataFile);
    while not EOF(dataFile) do
    begin
      ReadLn(dataFile,cLine);
      SetLength(fileText,Length(fileText)+1);
      fileText[High(fileText)]:=cLine;
    end;
    CloseFile(dataFile);

    //display read data
    for i:=0 to length(fileText)-1 do
    begin
      ListBox1.AddItem(fileText[i],nil);
    end;

  end;

end;

procedure TForm1.btn_constructClick(Sender: TObject);
var bText:string;
begin
  if (ComboBox1.Text<>'Dpad') then
  begin
    bText:=ComboBox1.Text+'/'+edt_key.Text;
  end
  else
    bText:='Dpad';

  edt_bind_code.Text:=bText;
end;

procedure TForm1.btn_delete_bindClick(Sender: TObject);
var i,maxB,outSid:integer;
begin
  maxB:=High(storedBinds[selBind].bindings);
  if (maxB=selBindId) then SetLength(storedBinds[selBind].bindings,length(storedBinds[selBind].bindings)-1);
  if (maxB>selBindId) then
  begin
    for i:=selBindId to maxB-1 do
    begin
      storedBinds[selBind].bindings[i]:=storedBinds[selBind].bindings[i+1];
    end;
    SetLength(storedBinds[selBind].bindings,length(storedBinds[selBind].bindings)-1);
  end;
  selBindId:=High(storedBinds[selBind].bindings);
  redrawBList(outSid);
  ListBox3.ItemIndex:=selBindId;
end;

procedure TForm1.btn_add_bindClick(Sender: TObject);
var outSid:integer;
begin
  SetLength(storedBinds[selBind].bindings,Length(storedBinds[selBind].bindings)+1);
  storedBinds[selBind].bindings[High(storedBinds[selBind].bindings)]:=edt_bind_code.Text;
  selBindId:=High(storedBinds[selBind].bindings);
  redrawBList(outSid);
  ListBox3.ItemIndex:=selBindId;
end;


procedure parseBindSet(txt:string; var ds:strArr);
var cs:char;
    ctxt:string;
    i,l:integer;
begin
  //ShowMessage('Parsing set: '+txt);
  setlength(ds,0);
  l:=high(txt);
  ctxt:='';
  for i:=1 to l do
  begin
    cs:=txt[i];
    if ((cs<>'|') and (i<l)) then
    ctxt:=ctxt+cs
    else
    begin
      if (cs<>'|') then ctxt:=ctxt+cs;
      SetLength(ds,length(ds)+1);
      ds[high(ds)]:=ctxt;
      ctxt:='';
    end;
  end;
end;

procedure parseFileText;
var i,l:integer;
    cid:integer;
begin
  l:=Length(fileText);
  setlength(storedBinds,0);
  cid:=0;
  filePreamble:='';

  //get first cid with keys
  while (true) do
  begin
    filePreamble:=filePreamble+fileText[cid]+#13#10;
    if (fileText[cid]='Player') then
    begin
      inc(cid); inc(cid); inc(cid); break;
    end;
    inc(cid);
  end;

  setLength(storedBinds,0);

  i:=cid;

  while (i<l) do
  begin
    //ShowMessage('Parsing line: '+fileText[i]);
    setLength(storedBinds,Length(storedBinds)+1);
    if (fileText[i]='UI') then
    begin
      inc(i);
      inc(i);
      inc(i);
    end;
    storedBinds[High(storedBinds)].name:=fileText[i];
    inc(i);
    inc(i);
    if (i>=l) then break;
    parseBindSet(fileText[i],storedBinds[High(storedBinds)].bindings);
    inc(i);
    inc(i);
    if (i>=l) then break;
  end;

end;

procedure TForm1.btn_parseClick(Sender: TObject);
var i:integer;
begin
  parseFileText;
  listBox2.Clear;
  ListBox3.Clear;
  for i:=0 to Length(storedBinds)-1 do
  begin
    ListBox2.AddItem(storedBinds[i].name,nil);
  end;
end;

procedure TForm1.btn_preset_useClick(Sender: TObject);
begin
  edt_key.Text:=ComboBox2.Text;
end;

procedure TForm1.btn_set_bindClick(Sender: TObject);
var outSid:integer;
begin
  storedBinds[selBind].bindings[selBindId]:=edt_bind_code.Text;
  redrawBList(outSid);
  ListBox3.ItemIndex:=selBindId;
end;

procedure TForm1.Button2Click(Sender: TObject);
var outText:string;
    add,dr:string;
    utf8txt:AnsiString;
    i,j,l,lb:integer;
begin
  dr:=#10;
  outText:=filePreamble+dr;
  outtext:=outText+dr;
  l:=length(storedBinds);
  for i:=0 to l-1 do
  begin
    outText:=outText+storedBinds[i].name+dr+dr;
    lb:=length(storedBinds[i].bindings);
    for j:=0 to lb-1 do
    begin
      add:='|';
      if j<lb-1 then add:='|';
      outText:=outText+storedBinds[i].bindings[j]+add;
    end;
    outText:=outText+dr+dr;

    //add UI section
    if (storedBinds[i].name='Reset') then
    outText:=outText+'UI'+dr+dr+dr;
  end;

  AssignFile(dataFile,filePath);
  Rewrite(dataFile);
  utf8txt:=UTF8Encode(outText);
  Write(dataFile,utf8txt);
  CloseFile(dataFile);

end;

procedure TForm1.redrawBList(var sid:integer);
var i,selId:integer;
begin
  ListBox3.Clear;
  selId:=ListBox2.ItemIndex;
  sid:=selId;
  for i:=0 to length(storedBinds[selId].bindings)-1 do
  begin
    ListBox3.AddItem(storedBinds[selId].bindings[i],nil);
  end;
end;

procedure TForm1.ListBox2SelectionChange(Sender: TObject; User: boolean);
var i,selId:integer;
begin
  redrawBList(selId);
  selBind:=selId;
end;

procedure TForm1.ListBox3SelectionChange(Sender: TObject; User: boolean);
var selId:integer;
    codetxt:string;
    csym:string;
    tpname:string;
begin
  selId:=ListBox3.ItemIndex;
  selBindId:=selId;
  edt_bind_code.Text:=ListBox3.Items[selId];
end;


end.

