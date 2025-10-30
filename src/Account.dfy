include "Transaction.dfy"
include "Configuration.dfy"

module Account {
  import opened Transaction
  import opened Configuration

  // Account status enumeration
  datatype AccountStatus = Active | Suspended | Closed

  // Account data structure with complete state
  datatype Account = Account(
    id: nat,
    owner: string,
    balance: int,
    history: seq<Transaction>,
    overdraftEnabled: bool,
    overdraftLimit: int,  // Maximum negative balance allowed (positive number)
    maxBalance: int,
    maxTransaction: int,
    totalFeesCollected: int,
    status: AccountStatus,
    createdAt: nat
  )

  // Core invariant: balance matches transaction history
  // Ensures consistency between computed balance and recorded balance
  ghost predicate BalanceMatchesHistory(account: Account)
  {
    account.balance == ComputeBalanceFromHistory(account.history)
  }

  // Recursively compute balance from transaction history
  // Base case: empty history has zero balance
  // Recursive case: first transaction amount plus balance of remaining history
  function ComputeBalanceFromHistory(history: seq<Transaction>): int
  {
    if |history| == 0 then 0
    else history[0].amount + ComputeBalanceFromHistory(history[1..])
  }

  // Helper function to compute total fees from transaction history
  function TotalFees(history: seq<Transaction>): int
  {
    if |history| == 0 then 0
    else history[0].fee + TotalFees(history[1..])
  }

  // Account validity invariant
  // Ensures all account state constraints are satisfied
  ghost predicate ValidAccount(account: Account)
  {
    // Balance matches history
    BalanceMatchesHistory(account) &&
    // Overdraft limit non-negative
    account.overdraftLimit >= 0 &&
    // Balance respects overdraft setting
    (account.overdraftEnabled ==> account.balance >= -account.overdraftLimit) &&
    (!account.overdraftEnabled ==> account.balance >= 0) &&
    // Max limits are positive
    account.maxBalance > 0 &&
    account.maxTransaction > 0 &&
    // Total fees non-negative
    account.totalFeesCollected >= 0 &&
    // Owner name not empty
    |account.owner| > 0 &&
    // Fee monotonicity in history
    TotalFees(account.history) == account.totalFeesCollected
  }

  // Create new account with initial deposit
  // Returns account instance and success flag
  // Uses configuration defaults from Configuration module for validation limits
  method CreateAccount(
    id: nat,
    owner: string,
    initialDeposit: int,
    enableOverdraft: bool,
    overdraftLimit: int,
    maxBalance: int,
    maxTransaction: int
  ) returns (account: Account, success: bool)
    requires |owner| > 0
    requires initialDeposit >= 0
    requires overdraftLimit >= 0
    requires maxBalance > 0
    requires maxTransaction > 0
    requires initialDeposit <= maxBalance
    ensures success ==> ValidAccount(account)
    ensures success ==> account.id == id
    ensures success ==> account.owner == owner
    ensures success ==> account.balance == initialDeposit
    ensures !success ==> account == Account(0, "", 0, [], false, 0, 1, 1, 0, Closed, 0)
  {
    // Validate initial deposit does not exceed max balance
    // maxBalance should respect Configuration.DEFAULT_MAX_BALANCE_CENTS
    if initialDeposit > maxBalance {
      account := Account(0, "", 0, [], false, 0, 1, 1, 0, Closed, 0);
      success := false;
      return;
    }

    // Create initial deposit transaction
    var initialTx := Transaction(
      "INIT-" + owner,  // Simple ID generation
      id,
      Deposit,
      initialDeposit,
      "Initial deposit",
      0,  // Timestamp placeholder
      0,
      initialDeposit,
      Completed,
      None,
      []
    );

    // Construct account with initial state
    // Configuration defaults:
    // - enableOverdraft defaults to Configuration.DEFAULT_OVERDRAFT_ENABLED
    // - overdraftLimit defaults to Configuration.DEFAULT_OVERDRAFT_LIMIT_CENTS
    // - maxBalance defaults to Configuration.DEFAULT_MAX_BALANCE_CENTS
    // - maxTransaction defaults to Configuration.DEFAULT_MAX_TRANSACTION_CENTS
    account := Account(
      id,
      owner,
      initialDeposit,
      if initialDeposit > 0 then [initialTx] else [],
      enableOverdraft,
      overdraftLimit,
      maxBalance,
      maxTransaction,
      0,  // No fees yet
      Active,
      0   // Timestamp placeholder
    );
    success := true;
  }
}
