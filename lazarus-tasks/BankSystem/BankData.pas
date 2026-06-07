unit BankData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils;

type
  { Deposit Categories }
  TDepositCategory = (dcStandard, dcPremium, dcVIP, dcStudents, dcRetirees);

  { Account Record }
  TBankAccount = record
    AccountNumber: string;
    Category: TDepositCategory;
    PassportNumber: string;
    FullName: string;
    CurrentAmount: Double;
    InterestRate: Double;
    LastOperationDate: TDateTime;
    OpenDate: TDateTime;
  end;

  { Bank Account Manager }
  TBankAccountManager = class
  private
    FAccounts: TList;
    function FindAccountIndex(AccountNumber: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    { Account Operations }
    function CreateAccount(AccountNumber, PassportNumber, FullName: string;
      Category: TDepositCategory; InitialAmount: Double): Boolean;
    function DeleteAccount(AccountNumber: string): Boolean;
    function GetAccount(AccountNumber: string): TBankAccount;
    function AccountExists(AccountNumber: string): Boolean;
    
    { Transactions }
    function Deposit(AccountNumber: string; Amount: Double): Boolean;
    function Withdraw(AccountNumber: string; Amount: Double): Boolean;
    
    { Interest Calculation }
    procedure ApplyInterest(AccountNumber: string);
    function GetInterestRate(Category: TDepositCategory): Double;
    
    { Account List }
    function GetAccountCount: Integer;
    function GetAccountByIndex(Index: Integer): TBankAccount;
    procedure UpdateAccount(AccountNumber: string; Account: TBankAccount);
    
    { Utility }
    procedure ClearAll;
    function GetCategoryName(Category: TDepositCategory): string;
  end;

implementation

{ TBankAccountManager }

constructor TBankAccountManager.Create;
begin
  inherited Create;
  FAccounts := TList.Create;
end;

destructor TBankAccountManager.Destroy;
var
  i: Integer;
begin
  for i := FAccounts.Count - 1 downto 0 do
    Dispose(PTBankAccount(FAccounts[i]));
  FAccounts.Free;
  inherited Destroy;
end;

function TBankAccountManager.FindAccountIndex(AccountNumber: string): Integer;
var
  i: Integer;
  pAcc: PTBankAccount;
begin
  Result := -1;
  for i := 0 to FAccounts.Count - 1 do
  begin
    pAcc := PTBankAccount(FAccounts[i]);
    if pAcc^.AccountNumber = AccountNumber then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TBankAccountManager.CreateAccount(AccountNumber, PassportNumber, FullName: string;
  Category: TDepositCategory; InitialAmount: Double): Boolean;
var
  pAcc: PTBankAccount;
begin
  if AccountExists(AccountNumber) then
  begin
    Result := False;
    Exit;
  end;

  New(pAcc);
  pAcc^.AccountNumber := AccountNumber;
  pAcc^.PassportNumber := PassportNumber;
  pAcc^.FullName := FullName;
  pAcc^.Category := Category;
  pAcc^.CurrentAmount := InitialAmount;
  pAcc^.InterestRate := GetInterestRate(Category);
  pAcc^.LastOperationDate := Now;
  pAcc^.OpenDate := Now;

  FAccounts.Add(pAcc);
  Result := True;
end;

function TBankAccountManager.DeleteAccount(AccountNumber: string): Boolean;
var
  Index: Integer;
begin
  Index := FindAccountIndex(AccountNumber);
  if Index >= 0 then
  begin
    Dispose(PTBankAccount(FAccounts[Index]));
    FAccounts.Delete(Index);
    Result := True;
  end
  else
    Result := False;
end;

function TBankAccountManager.GetAccount(AccountNumber: string): TBankAccount;
var
  Index: Integer;
begin
  Index := FindAccountIndex(AccountNumber);
  if Index >= 0 then
    Result := PTBankAccount(FAccounts[Index])^
  else
  begin
    FillChar(Result, SizeOf(TBankAccount), 0);
    Result.AccountNumber := '';
  end;
end;

function TBankAccountManager.AccountExists(AccountNumber: string): Boolean;
begin
  Result := FindAccountIndex(AccountNumber) >= 0;
end;

function TBankAccountManager.Deposit(AccountNumber: string; Amount: Double): Boolean;
var
  Index: Integer;
  pAcc: PTBankAccount;
begin
  Result := False;
  if Amount <= 0 then Exit;

  Index := FindAccountIndex(AccountNumber);
  if Index >= 0 then
  begin
    pAcc := PTBankAccount(FAccounts[Index]);
    pAcc^.CurrentAmount := pAcc^.CurrentAmount + Amount;
    pAcc^.LastOperationDate := Now;
    Result := True;
  end;
end;

function TBankAccountManager.Withdraw(AccountNumber: string; Amount: Double): Boolean;
var
  Index: Integer;
  pAcc: PTBankAccount;
begin
  Result := False;
  if Amount <= 0 then Exit;

  Index := FindAccountIndex(AccountNumber);
  if Index >= 0 then
  begin
    pAcc := PTBankAccount(FAccounts[Index]);
    if pAcc^.CurrentAmount >= Amount then
    begin
      pAcc^.CurrentAmount := pAcc^.CurrentAmount - Amount;
      pAcc^.LastOperationDate := Now;
      Result := True;
    end;
  end;
end;

procedure TBankAccountManager.ApplyInterest(AccountNumber: string);
var
  Index: Integer;
  pAcc: PTBankAccount;
  InterestAmount: Double;
  DaysPassed: Integer;
begin
  Index := FindAccountIndex(AccountNumber);
  if Index >= 0 then
  begin
    pAcc := PTBankAccount(FAccounts[Index]);
    DaysPassed := DaysBetween(Now, pAcc^.LastOperationDate);
    
    if DaysPassed > 0 then
    begin
      InterestAmount := pAcc^.CurrentAmount * pAcc^.InterestRate / 100 / 365 * DaysPassed;
      pAcc^.CurrentAmount := pAcc^.CurrentAmount + InterestAmount;
      pAcc^.LastOperationDate := Now;
    end;
  end;
end;

function TBankAccountManager.GetInterestRate(Category: TDepositCategory): Double;
begin
  case Category of
    dcStandard: Result := 2.5;
    dcPremium: Result := 4.0;
    dcVIP: Result := 5.5;
    dcStudents: Result := 3.0;
    dcRetirees: Result := 3.5;
  else
    Result := 2.0;
  end;
end;

function TBankAccountManager.GetAccountCount: Integer;
begin
  Result := FAccounts.Count;
end;

function TBankAccountManager.GetAccountByIndex(Index: Integer): TBankAccount;
begin
  if (Index >= 0) and (Index < FAccounts.Count) then
    Result := PTBankAccount(FAccounts[Index])^
  else
    FillChar(Result, SizeOf(TBankAccount), 0);
end;

procedure TBankAccountManager.UpdateAccount(AccountNumber: string; Account: TBankAccount);
var
  Index: Integer;
begin
  Index := FindAccountIndex(AccountNumber);
  if Index >= 0 then
    PTBankAccount(FAccounts[Index])^ := Account;
end;

procedure TBankAccountManager.ClearAll;
var
  i: Integer;
begin
  for i := FAccounts.Count - 1 downto 0 do
    Dispose(PTBankAccount(FAccounts[i]));
  FAccounts.Clear;
end;

function TBankAccountManager.GetCategoryName(Category: TDepositCategory): string;
begin
  case Category of
    dcStandard: Result := 'Стандартный';
    dcPremium: Result := 'Премиум';
    dcVIP: Result := 'VIP';
    dcStudents: Result := 'Студентов';
    dcRetirees: Result := 'Пенсионеров';
  else
    Result := 'Неизвестно';
  end;
end;

end.
