unit MainBankForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, ComCtrls, BankData;

type
  TMainBankForm = class(TForm)
    MainPanel: TPanel;
    NotebookMain: TNotebook;
    
    { Account Management Page }
    CreateAccountPage: TTabSheet;
    pnlCreateAccount: TPanel;
    lblAccountNumber: TLabel;
    edtAccountNumber: TEdit;
    lblPassport: TLabel;
    edtPassport: TEdit;
    lblFullName: TLabel;
    edtFullName: TEdit;
    lblCategory: TLabel;
    cbCategory: TComboBox;
    lblInitialAmount: TLabel;
    edtInitialAmount: TEdit;
    btnCreateAccount: TButton;
    mmoStatus: TMemo;
    
    { Operations Page }
    OperationsPage: TTabSheet;
    pnlOperations: TPanel;
    lblOpAccountNumber: TLabel;
    edtOpAccountNumber: TEdit;
    lblAmount: TLabel;
    edtAmount: TEdit;
    btnDeposit: TButton;
    btnWithdraw: TButton;
    btnApplyInterest: TButton;
    
    { View Accounts Page }
    ViewAccountsPage: TTabSheet;
    sgAccounts: TStringGrid;
    btnRefreshAccounts: TButton;
    btnDeleteAccount: TButton;
    
    { Navigation }
    btnPageCreate: TButton;
    btnPageOperations: TButton;
    btnPageView: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    
    { Create Account }
    procedure btnCreateAccountClick(Sender: TObject);
    
    { Operations }
    procedure btnDepositClick(Sender: TObject);
    procedure btnWithdrawClick(Sender: TObject);
    procedure btnApplyInterestClick(Sender: TObject);
    
    { View Accounts }
    procedure btnRefreshAccountsClick(Sender: TObject);
    procedure btnDeleteAccountClick(Sender: TObject);
    
    { Navigation }
    procedure btnPageCreateClick(Sender: TObject);
    procedure btnPageOperationsClick(Sender: TObject);
    procedure btnPageViewClick(Sender: TObject);
    
  private
    BankManager: TBankAccountManager;
    procedure LoadAccountsToGrid;
    procedure LogMessage(Msg: string);
  end;

var
  MainBankForm: TMainBankForm;

implementation

{$R *.lfm}

procedure TMainBankForm.FormCreate(Sender: TObject);
begin
  BankManager := TBankAccountManager.Create;
  
  { Initialize ComboBox with categories }
  cbCategory.Items.Clear;
  cbCategory.Items.Add('Стандартный');
  cbCategory.Items.Add('Премиум');
  cbCategory.Items.Add('VIP');
  cbCategory.Items.Add('Студентов');
  cbCategory.Items.Add('Пенсионеров');
  cbCategory.ItemIndex := 0;
  
  { Initialize StringGrid }
  sgAccounts.ColCount := 7;
  sgAccounts.RowCount := 1;
  sgAccounts.Cells[0, 0] := 'Лицевой счет';
  sgAccounts.Cells[1, 0] := 'ФИО';
  sgAccounts.Cells[2, 0] := 'Паспорт';
  sgAccounts.Cells[3, 0] := 'Категория';
  sgAccounts.Cells[4, 0] := 'Сумма (РУБ)';
  sgAccounts.Cells[5, 0] := 'Ставка (%)';
  sgAccounts.Cells[6, 0] := 'Последняя операция';
  
  { Set column widths }
  sgAccounts.ColWidths[0] := 100;
  sgAccounts.ColWidths[1] := 150;
  sgAccounts.ColWidths[2] := 120;
  sgAccounts.ColWidths[3] := 100;
  sgAccounts.ColWidths[4] := 100;
  sgAccounts.ColWidths[5] := 80;
  sgAccounts.ColWidths[6] := 150;
  
  NotebookMain.PageIndex := 0;
  LogMessage('Система управления вкладами инициализирована');
end;

procedure TMainBankForm.FormDestroy(Sender: TObject);
begin
  BankManager.Free;
end;

procedure TMainBankForm.btnCreateAccountClick(Sender: TObject);
var
  Category: TDepositCategory;
  InitialAmount: Double;
begin
  if (edtAccountNumber.Text = '') or (edtPassport.Text = '') or (edtFullName.Text = '') then
  begin
    LogMessage('ОШИБКА: Заполните все поля!');
    Exit;
  end;

  try
    InitialAmount := StrToFloat(edtInitialAmount.Text);
    if InitialAmount < 0 then
      raise Exception.Create('Сумма не может быть отрицательной');
  except
    LogMessage('ОШИБКА: Некорректная сумма!');
    Exit;
  end;

  Category := TDepositCategory(cbCategory.ItemIndex);

  if BankManager.CreateAccount(edtAccountNumber.Text, edtPassport.Text,
    edtFullName.Text, Category, InitialAmount) then
  begin
    LogMessage(Format('✓ Счет %s создан успешно! (ФИО: %s)', 
      [edtAccountNumber.Text, edtFullName.Text]));
    
    { Clear form }
    edtAccountNumber.Clear;
    edtPassport.Clear;
    edtFullName.Clear;
    edtInitialAmount.Clear;
    cbCategory.ItemIndex := 0;
  end
  else
    LogMessage('ОШИБКА: Счет с таким номером уже существует!');
end;

procedure TMainBankForm.btnDepositClick(Sender: TObject);
var
  Amount: Double;
begin
  if edtOpAccountNumber.Text = '' then
  begin
    LogMessage('ОШИБКА: Введите номер счета!');
    Exit;
  end;

  try
    Amount := StrToFloat(edtAmount.Text);
    if Amount <= 0 then
      raise Exception.Create('Сумма должна быть больше нуля');
  except
    LogMessage('ОШИБКА: Некорректная сумма!');
    Exit;
  end;

  if BankManager.Deposit(edtOpAccountNumber.Text, Amount) then
  begin
    LogMessage(Format('✓ Пополнение счета %s на сумму %.2f РУБ успешно!', 
      [edtOpAccountNumber.Text, Amount]));
    edtAmount.Clear;
  end
  else
    LogMessage('ОШИБКА: Счет не найден или операция не выполнена!');
end;

procedure TMainBankForm.btnWithdrawClick(Sender: TObject);
var
  Amount: Double;
  Account: TBankAccount;
begin
  if edtOpAccountNumber.Text = '' then
  begin
    LogMessage('ОШИБКА: Введите номер счета!');
    Exit;
  end;

  try
    Amount := StrToFloat(edtAmount.Text);
    if Amount <= 0 then
      raise Exception.Create('Сумма должна быть больше нуля');
  except
    LogMessage('ОШИБКА: Некорректная сумма!');
    Exit;
  end;

  Account := BankManager.GetAccount(edtOpAccountNumber.Text);
  if Account.AccountNumber = '' then
  begin
    LogMessage('ОШИБКА: Счет не найден!');
    Exit;
  end;

  if Account.CurrentAmount < Amount then
  begin
    LogMessage(Format('ОШИБКА: Недостаточно средств! Баланс: %.2f РУБ', 
      [Account.CurrentAmount]));
    Exit;
  end;

  if BankManager.Withdraw(edtOpAccountNumber.Text, Amount) then
  begin
    LogMessage(Format('✓ Снятие со счета %s на сумму %.2f РУБ успешно!', 
      [edtOpAccountNumber.Text, Amount]));
    edtAmount.Clear;
  end
  else
    LogMessage('ОШИБКА: Операция не выполнена!');
end;

procedure TMainBankForm.btnApplyInterestClick(Sender: TObject);
var
  Account: TBankAccount;
begin
  if edtOpAccountNumber.Text = '' then
  begin
    LogMessage('ОШИБКА: Введите номер счета!');
    Exit;
  end;

  Account := BankManager.GetAccount(edtOpAccountNumber.Text);
  if Account.AccountNumber = '' then
  begin
    LogMessage('ОШИБКА: Счет не найден!');
    Exit;
  end;

  BankManager.ApplyInterest(edtOpAccountNumber.Text);
  Account := BankManager.GetAccount(edtOpAccountNumber.Text);
  LogMessage(Format('✓ Проценты начислены! Новый баланс: %.2f РУБ (Ставка: %.1f%%)', 
    [Account.CurrentAmount, Account.InterestRate]));
end;

procedure TMainBankForm.btnRefreshAccountsClick(Sender: TObject);
begin
  LoadAccountsToGrid;
  LogMessage('✓ Список счетов обновлен');
end;

procedure TMainBankForm.btnDeleteAccountClick(Sender: TObject);
var
  SelectedRow: Integer;
  AccountNumber: string;
begin
  SelectedRow := sgAccounts.Row;
  if SelectedRow <= 0 then
  begin
    LogMessage('ОШИБКА: Выберите счет для удаления!');
    Exit;
  end;

  AccountNumber := sgAccounts.Cells[0, SelectedRow];
  if BankManager.DeleteAccount(AccountNumber) then
  begin
    LogMessage(Format('✓ Счет %s удален успешно!', [AccountNumber]));
    LoadAccountsToGrid;
  end
  else
    LogMessage('ОШИБКА: Не удалось удалить счет!');
end;

procedure TMainBankForm.btnPageCreateClick(Sender: TObject);
begin
  NotebookMain.PageIndex := 0;
end;

procedure TMainBankForm.btnPageOperationsClick(Sender: TObject);
begin
  NotebookMain.PageIndex := 1;
end;

procedure TMainBankForm.btnPageViewClick(Sender: TObject);
begin
  NotebookMain.PageIndex := 2;
  LoadAccountsToGrid;
end;

procedure TMainBankForm.LoadAccountsToGrid;
var
  i: Integer;
  Account: TBankAccount;
begin
  sgAccounts.RowCount := BankManager.GetAccountCount + 1;
  
  for i := 0 to BankManager.GetAccountCount - 1 do
  begin
    Account := BankManager.GetAccountByIndex(i);
    sgAccounts.Cells[0, i + 1] := Account.AccountNumber;
    sgAccounts.Cells[1, i + 1] := Account.FullName;
    sgAccounts.Cells[2, i + 1] := Account.PassportNumber;
    sgAccounts.Cells[3, i + 1] := BankManager.GetCategoryName(Account.Category);
    sgAccounts.Cells[4, i + 1] := Format('%.2f', [Account.CurrentAmount]);
    sgAccounts.Cells[5, i + 1] := Format('%.1f', [Account.InterestRate]);
    sgAccounts.Cells[6, i + 1] := FormatDateTime('dd.mm.yyyy hh:mm', Account.LastOperationDate);
  end;
end;

procedure TMainBankForm.LogMessage(Msg: string);
begin
  mmoStatus.Lines.Insert(0, FormatDateTime('[hh:mm:ss] ', Now) + Msg);
  if mmoStatus.Lines.Count > 100 then
    mmoStatus.Lines.Delete(mmoStatus.Lines.Count - 1);
end;

end.
