unit ConveyorMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Math;

type
  { Item on conveyor }
  TConveyorItem = record
    X: Double;
    ItemType: Integer; { 0=box, 1=cylinder, 2=sphere }
    Color: TColor;
  end;

  TConveyorMainForm = class(TForm)
    pnlMain: TPanel;
    pnlControl: TPanel;
    pnlCanvas: TPanel;
    imgConveyor: TImage;
    
    lblSpeed: TLabel;
    trackSpeed: TTrackBar;
    lblSpeedValue: TLabel;
    
    lblItemType: TLabel;
    cbItemType: TComboBox;
    
    lblItemColor: TLabel;
    btnItemColor: TButton;
    
    btnStart: TButton;
    btnStop: TButton;
    btnAddItem: TButton;
    btnClear: TButton;
    
    lblItemCount: TLabel;
    edtItemCount: TLabel;
    
    timerAnimation: TTimer;
    colorDialog: TColorDialog;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    
    procedure trackSpeedChange(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnAddItemClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnItemColorClick(Sender: TObject);
    procedure cbItemTypeChange(Sender: TObject);
    
    procedure timerAnimationTimer(Sender: TObject);
    procedure imgConveyorPaint(Sender: TObject);
    
  private
    Items: array of TConveyorItem;
    IsRunning: Boolean;
    CurrentSpeed: Double;
    CurrentItemType: Integer;
    CurrentItemColor: TColor;
    ConveyorY: Integer;
    
    procedure DrawConveyor;
    procedure DrawItems;
    procedure DrawBox(X, Y: Integer; Color: TColor);
    procedure DrawCylinder(X, Y: Integer; Color: TColor);
    procedure DrawSphere(X, Y: Integer; Color: TColor);
    procedure UpdateItemCount;
    procedure RemoveOffscreenItems;
  end;

var
  ConveyorMainForm: TConveyorMainForm;

implementation

{$R *.lfm}

procedure TConveyorMainForm.FormCreate(Sender: TObject);
begin
  SetLength(Items, 0);
  IsRunning := False;
  CurrentSpeed := 2;
  CurrentItemType := 0;
  CurrentItemColor := clRed;
  ConveyorY := 200;
  
  { Initialize ComboBox }
  cbItemType.Items.Clear;
  cbItemType.Items.Add('Коробка');
  cbItemType.Items.Add('Цилиндр');
  cbItemType.Items.Add('Сфера');
  cbItemType.ItemIndex := 0;
  
  trackSpeed.Min := 1;
  trackSpeed.Max := 50;
  trackSpeed.Position := 10;
  trackSpeed.OnChange := @trackSpeedChange;
  
  timerAnimation.Interval := 30;
  timerAnimation.Enabled := False;
  
  btnItemColor.Color := CurrentItemColor;
  colorDialog.Color := CurrentItemColor;
  
  UpdateItemCount;
end;

procedure TConveyorMainForm.FormDestroy(Sender: TObject);
begin
  SetLength(Items, 0);
end;

procedure TConveyorMainForm.FormResize(Sender: TObject);
begin
  imgConveyor.Repaint;
end;

procedure TConveyorMainForm.trackSpeedChange(Sender: TObject);
begin
  CurrentSpeed := trackSpeed.Position / 5;
  lblSpeedValue.Caption := Format('%.1f', [CurrentSpeed]);
end;

procedure TConveyorMainForm.btnStartClick(Sender: TObject);
begin
  IsRunning := True;
  timerAnimation.Enabled := True;
  btnStart.Enabled := False;
  btnStop.Enabled := True;
end;

procedure TConveyorMainForm.btnStopClick(Sender: TObject);
begin
  IsRunning := False;
  timerAnimation.Enabled := False;
  btnStart.Enabled := True;
  btnStop.Enabled := False;
end;

procedure TConveyorMainForm.btnAddItemClick(Sender: TObject);
var
  NewLen: Integer;
begin
  NewLen := Length(Items) + 1;
  SetLength(Items, NewLen);
  
  Items[NewLen - 1].X := -50;
  Items[NewLen - 1].ItemType := CurrentItemType;
  Items[NewLen - 1].Color := CurrentItemColor;
  
  UpdateItemCount;
  imgConveyor.Repaint;
end;

procedure TConveyorMainForm.btnClearClick(Sender: TObject);
begin
  SetLength(Items, 0);
  UpdateItemCount;
  imgConveyor.Repaint;
end;

procedure TConveyorMainForm.btnItemColorClick(Sender: TObject);
begin
  if colorDialog.Execute then
  begin
    CurrentItemColor := colorDialog.Color;
    btnItemColor.Color := CurrentItemColor;
  end;
end;

procedure TConveyorMainForm.cbItemTypeChange(Sender: TObject);
begin
  CurrentItemType := cbItemType.ItemIndex;
end;

procedure TConveyorMainForm.timerAnimationTimer(Sender: TObject);
var
  i: Integer;
begin
  if IsRunning then
  begin
    { Move items }
    for i := 0 to Length(Items) - 1 do
      Items[i].X := Items[i].X + CurrentSpeed;
    
    RemoveOffscreenItems;
    UpdateItemCount;
    imgConveyor.Repaint;
  end;
end;

procedure TConveyorMainForm.RemoveOffscreenItems;
var
  i, j: Integer;
  NewItems: array of TConveyorItem;
  NewLen: Integer;
begin
  NewLen := 0;
  SetLength(NewItems, Length(Items));
  
  for i := 0 to Length(Items) - 1 do
  begin
    if Items[i].X < imgConveyor.Width + 100 then
    begin
      NewItems[NewLen] := Items[i];
      Inc(NewLen);
    end;
  end;
  
  SetLength(NewItems, NewLen);
  SetLength(Items, NewLen);
  
  for i := 0 to NewLen - 1 do
    Items[i] := NewItems[i];
  
  SetLength(NewItems, 0);
end;

procedure TConveyorMainForm.DrawConveyor;
var
  Canvas: TCanvas;
  i: Integer;
  LineCount: Integer;
begin
  Canvas := imgConveyor.Canvas;
  
  { Draw background }
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(Rect(0, 0, imgConveyor.Width, imgConveyor.Height));
  
  { Draw conveyor belt (top line) }
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 3;
  Canvas.MoveTo(0, ConveyorY);
  Canvas.LineTo(imgConveyor.Width, ConveyorY);
  
  { Draw conveyor belt (bottom line) }
  Canvas.MoveTo(0, ConveyorY + 80);
  Canvas.LineTo(imgConveyor.Width, ConveyorY + 80);
  
  { Draw conveyor belt pattern (moving dashes) }
  Canvas.Pen.Color := clGray;
  Canvas.Pen.Width := 1;
  
  LineCount := (imgConveyor.Width div 30) + 2;
  for i := 0 to LineCount do
  begin
    Canvas.MoveTo(Round((i * 30 - Trunc(CurrentSpeed * 10) mod 30)), ConveyorY + 20);
    Canvas.LineTo(Round((i * 30 - Trunc(CurrentSpeed * 10) mod 30)), ConveyorY + 60);
  end;
  
  { Draw support }
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 2;
  Canvas.MoveTo(20, ConveyorY + 80);
  Canvas.LineTo(20, ConveyorY + 120);
  Canvas.MoveTo(imgConveyor.Width - 20, ConveyorY + 80);
  Canvas.LineTo(imgConveyor.Width - 20, ConveyorY + 120);
end;

procedure TConveyorMainForm.DrawBox(X, Y: Integer; Color: TColor);
var
  Canvas: TCanvas;
  Size: Integer;
begin
  Canvas := imgConveyor.Canvas;
  Size := 35;
  
  Canvas.Brush.Color := Color;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 2;
  Canvas.Rectangle(X, Y - Size div 2, X + Size, Y + Size div 2);
  
  { Draw outline }
  Canvas.MoveTo(X, Y - Size div 2);
  Canvas.LineTo(X + Size div 4, Y - Size div 2 - 8);
  Canvas.LineTo(X + Size + Size div 4, Y - Size div 2 - 8);
  Canvas.LineTo(X + Size, Y - Size div 2);
end;

procedure TConveyorMainForm.DrawCylinder(X, Y: Integer; Color: TColor);
var
  Canvas: TCanvas;
  Width: Integer;
  Height: Integer;
begin
  Canvas := imgConveyor.Canvas;
  Width := 40;
  Height := 30;
  
  { Draw cylinder body }
  Canvas.Brush.Color := Color;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 2;
  Canvas.Ellipse(X, Y - Height div 2 - 5, X + Width, Y - Height div 2 + 5);
  Canvas.Rectangle(X, Y - Height div 2, X + Width, Y + Height div 2);
  Canvas.Ellipse(X, Y + Height div 2 - 5, X + Width, Y + Height div 2 + 5);
end;

procedure TConveyorMainForm.DrawSphere(X, Y: Integer; Color: TColor);
var
  Canvas: TCanvas;
  Radius: Integer;
  i: Integer;
begin
  Canvas := imgConveyor.Canvas;
  Radius := 18;
  
  Canvas.Brush.Color := Color;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 2;
  Canvas.Ellipse(X - Radius, Y - Radius, X + Radius, Y + Radius);
  
  { Draw highlight }
  Canvas.Pen.Color := clWhite;
  Canvas.Pen.Width := 1;
  Canvas.Arc(X - Radius + 5, Y - Radius + 5, X - Radius + 15, Y - Radius + 15, 0, 360);
end;

procedure TConveyorMainForm.DrawItems;
var
  i: Integer;
  Canvas: TCanvas;
begin
  Canvas := imgConveyor.Canvas;
  
  for i := 0 to Length(Items) - 1 do
  begin
    case Items[i].ItemType of
      0: DrawBox(Round(Items[i].X), ConveyorY + 40, Items[i].Color);
      1: DrawCylinder(Round(Items[i].X), ConveyorY + 40, Items[i].Color);
      2: DrawSphere(Round(Items[i].X), ConveyorY + 40, Items[i].Color);
    end;
  end;
end;

procedure TConveyorMainForm.imgConveyorPaint(Sender: TObject);
begin
  DrawConveyor;
  DrawItems;
end;

procedure TConveyorMainForm.UpdateItemCount;
begin
  edtItemCount.Caption := IntToStr(Length(Items));
end;

end.
