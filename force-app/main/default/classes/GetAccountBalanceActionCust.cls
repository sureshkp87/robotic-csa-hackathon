global class GetAccountBalanceActionCust {
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
            label='Account Balance Output'
            description='Balance details for the selected financial account'
        )
        global FABalanceWrapper result;
    }

    @InvocableMethod(
        label='Get Account Balance NEW'
        description='Fetches balance details from FinancialAccountBalance for a given Financial Account'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new FABalanceWrapper();

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
                        Status,
                        CurrencyIsoCode
                    FROM FinancialAccount
                    WHERE Id = :input.financialAccountId
                    LIMIT 1
                ];

                output.result.financialAccountId     = fa.Id;
                output.result.financialAccountName   = fa.Name;
                output.result.financialAccountNumber = fa.FinancialAccountNumber;
                output.result.financialAccountType   = fa.Type;
                output.result.status                 = fa.Status;
                output.result.currencyCode           = fa.CurrencyIsoCode;

                // Fetch child balance records
                List<FinancialAccountBalance> balances = [
                    SELECT
                        Type,
                        Amount,
                        BalanceAsOfDate
                    FROM FinancialAccountBalance
                    WHERE FinancialAccountId = :input.financialAccountId
                    ORDER BY BalanceAsOfDate DESC
                ];

                if (balances.isEmpty()) {
                    output.result.error = 'No balance records found for this account.';
                    outputs.add(output);
                    continue;
                }

                for (FinancialAccountBalance fab : balances) {
                    output.result.balances.add(
                        new FABalanceWrapper.BalanceEntry(fab)
                    );
                }

                // Set asOfDate from most recent balance record
                output.result.asOfDate = output.result.balances[0].balanceAsOfDate;

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