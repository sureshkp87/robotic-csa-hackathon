global class GetFinancialAccountsActionCust {
    global class ActionInput {
        @InvocableVariable(
            label='Account Id'
            description='The Salesforce Contact Id of the customer'
            required=true
        )
        global Id accountId;
    }

    global class ActionOutput {
        @InvocableVariable(
            label='Financial Accounts Output'
            description='List of financial accounts for the customer'
        )
        global FAOutputWrapper result;
    }

    @InvocableMethod(
        label='Get Financial Accounts New'
        description='Fetches all active financial accounts linked to the given Account via FinancialAccountParty'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new FAOutputWrapper();

            try {
                if (input.accountId == null) {
                    output.result.error = 'Contact Id is required.';
                    outputs.add(output);
                    continue;
                }

                List<FinancialAccountParty> parties = [
                    SELECT
                        Role,
                        FinancialAccount.Id,
                        FinancialAccount.Name,
                        FinancialAccount.FinancialAccountNumber,
                        FinancialAccount.Type,
                        FinancialAccount.Status,
                        FinancialAccount.IsHeldAway
                    FROM FinancialAccountParty
                    WHERE AccountId = :input.accountId
                      AND FinancialAccount.Status = 'Active'
                    ORDER BY FinancialAccount.Name ASC
                ];

                if (parties.isEmpty()) {
                    output.result.error = 'No active financial accounts found for this customer.';
                    outputs.add(output);
                    continue;
                }

                for (FinancialAccountParty party : parties) {
                    output.result.financialAccounts.add(
                        new FAOutputWrapper.FinancialAccountData(
                            party.FinancialAccount,
                            party.Role
                        )
                    );
                }

            } catch (Exception e) {
                output.result.error = 'An error occurred: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}