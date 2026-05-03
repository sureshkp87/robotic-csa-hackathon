global class GetMiniStatementAction {

    global class ActionInput {
        @InvocableVariable(
            label='Financial Account Id'
            description='The Salesforce Id of the Financial Account'
            required=true
        )
        global Id financialAccountId;
    }

    global class ActionOutput {
        @InvocableVariable(
            label='Mini Statement Output'
            description='Last 5 transactions for the selected financial account'
        )
        global MiniStatementWrapper result;
    }

    @InvocableMethod(
        label='Get Mini Statement'
        description='Fetches the last 5 transactions for a given Financial Account'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new MiniStatementWrapper();

            try {
                if (input.financialAccountId == null) {
                    output.result.error = 'Financial Account Id is required.';
                    outputs.add(output);
                    continue;
                }

                // Fetch parent FinancialAccount details
                FinancialAccount fa = [
                    SELECT
                        Id,
                        Name,
                        FinancialAccountNumber,
                        Type,
                        CurrencyIsoCode
                    FROM FinancialAccount
                    WHERE Id = :input.financialAccountId
                    LIMIT 1
                ];

                output.result.financialAccountId     = fa.Id;
                output.result.financialAccountName   = fa.Name;
                output.result.financialAccountNumber = fa.FinancialAccountNumber;
                output.result.financialAccountType   = fa.Type;
                output.result.currencyCode           = fa.CurrencyIsoCode;

                // Fetch last 5 transactions ordered by TransactionDate
                List<FinancialAccountTransaction> txns = [
                    SELECT
                        Id,
                        Name,
                        CurrencyIsoCode,
                        TransactionDate,
                        PostedDate,
                        Description,
                        Amount,
                        DebitCreditIndicator,
                        Status,
                        Type,
                        SubType,
                        TransactionCode,
                        TransactionIdentifier
                    FROM FinancialAccountTransaction
                    WHERE FinancialAccountId = :input.financialAccountId
                    ORDER BY TransactionDate DESC, PostedDate DESC
                    LIMIT 5
                ];

                if (txns.isEmpty()) {
                    output.result.error = 'No transactions found for this account.';
                    outputs.add(output);
                    continue;
                }

                for (FinancialAccountTransaction txn : txns) {
                    output.result.transactions.add(
                        new MiniStatementWrapper.TransactionEntry(txn)
                    );
                }

            } catch (QueryException e) {
                output.result.error = 'Financial account not found or access denied.';
            } catch (Exception e) {
                output.result.error = 'An error occurred: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}