public class FinancialAccountBalanceCustom {
    @InvocableMethod(label='Get Financial Account Balances'
                     description='Fetches financial account balances by type for a party')
    public static List<Response> getBalances(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res = new Response();

            try {
                // ── Step 1: Get Financial Accounts via FinancialAccountParty ──
                List<FinancialAccountParty> parties = [
                    SELECT
                        Id,
                        FinancialAccountId,
                        FinancialAccount.Name,
                        FinancialAccount.Type,
                        FinancialAccount.Status,
                        Role
                    FROM FinancialAccountParty
                    WHERE AccountId = :req.partyId         // ← adjust field name if needed
                    AND Role = 'Owner'             // ← adjust role value if needed
                    AND FinancialAccount.Status = 'Active'
                    LIMIT 100
                ];

                if (parties.isEmpty()) {
                    res.success      = false;
                    res.errorMessage = 'No active financial accounts found for this party';
                    responses.add(res);
                    continue;
                }

                // ── Step 2: Collect Financial Account Ids ──────
                Set<Id> financialAccountIds = new Set<Id>();
                Map<Id, String> accountTypeMap = new Map<Id, String>();

                for (FinancialAccountParty party : parties) {
                    financialAccountIds.add(party.FinancialAccountId);
                    accountTypeMap.put(
                        party.FinancialAccountId,
                        party.FinancialAccount.Type != null
                            ? party.FinancialAccount.Type
                            : 'Unknown'
                    );
                }

                // ── Step 3: Get Balances from FinancialAccountBalance ──
                List<FinancialAccountBalance> balances = [
                    SELECT
                        Id,
                        FinancialAccountId,
                        Amount,
                        Type,
                        BalanceAsOfDate
                    FROM FinancialAccountBalance
                    WHERE FinancialAccountId IN :financialAccountIds
                    ORDER BY BalanceAsOfDate DESC
                    LIMIT 200
                ];

                if (balances.isEmpty()) {
                    res.success      = false;
                    res.errorMessage = 'No balance records found';
                    responses.add(res);
                    continue;
                }

                // ── Step 4: Group Balance by Account Type ───────
                Map<String, Decimal> balanceByType = new Map<String, Decimal>();
                Map<String, Integer> countByType   = new Map<String, Integer>();
                Decimal grandTotal = 0;

                for (FinancialAccountBalance bal : balances) {
                    String accType = accountTypeMap.get(bal.FinancialAccountId);
                    Decimal amount = bal.Amount != null ? bal.Amount : 0;

                    if (balanceByType.containsKey(accType)) {
                        balanceByType.put(accType, balanceByType.get(accType) + amount);
                        countByType.put(accType, countByType.get(accType) + 1);
                    } else {
                        balanceByType.put(accType, amount);
                        countByType.put(accType, 1);
                    }

                    grandTotal += amount;
                }

                // ── Step 5: Build Summary ───────────────────────
                List<BalanceSummary> summaries = new List<BalanceSummary>();
                for (String accType : balanceByType.keySet()) {
                    BalanceSummary summary = new BalanceSummary();
                    summary.accountType  = accType;
                    summary.totalBalance = balanceByType.get(accType);
                    summary.accountCount = countByType.get(accType);
                    summaries.add(summary);
                }

                res.success       = true;
                res.totalBalance  = grandTotal;
                res.accountCount  = financialAccountIds.size();
                res.balanceByType = summaries;

            } catch (Exception e) {
                res.success      = false;
                res.errorMessage = e.getMessage();
            }

            responses.add(res);
        }

        return responses;
    }

    // ─── Balance Summary ───────────────────────────────────
    public class BalanceSummary {
        @InvocableVariable(label='Account Type')
        public String accountType;

        @InvocableVariable(label='Total Balance')
        public Decimal totalBalance;

        @InvocableVariable(label='Account Count')
        public Integer accountCount;
    }

    // ─── Request ───────────────────────────────────────────
    public class Request {
        @InvocableVariable(label='Party Id' required=true)
        public String partyId;          // Account Id or Contact Id of the person

        @InvocableVariable(label='Role Filter' required=false)
        public String roleFilter;       // e.g. 'PrimaryOwner', 'Joint' — optional
    }

    // ─── Response ──────────────────────────────────────────
    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Total Balance')
        public Decimal totalBalance;

        @InvocableVariable(label='Account Count')
        public Integer accountCount;

        @InvocableVariable(label='Balance By Type')
        public List<BalanceSummary> balanceByType;
    }
}