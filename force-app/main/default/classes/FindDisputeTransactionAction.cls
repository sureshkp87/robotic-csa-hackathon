global class FindDisputeTransactionAction {

    global class ActionInput {
        @InvocableVariable(label='Financial Account Id' required=true)
        global Id financialAccountId;

        @InvocableVariable(label='Disputed Amount')
        global Decimal amount;

        @InvocableVariable(label='Merchant Name or Description Keyword')
        global String keyword;

        @InvocableVariable(label='Transaction Date')
        global Date transactionDate;
    }

    global class ActionOutput {
        @InvocableVariable(label='Matched Transaction')
        global DisputeTransactionWrapper result;
    }

    @InvocableMethod(
        label='Find Dispute Transaction'
        description='Finds a matching FinancialAccountTransaction based on amount, merchant keyword and date'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new DisputeTransactionWrapper();

            try {
                if (input.financialAccountId == null) {
                    output.result.error = 'Financial Account Id is required.';
                    outputs.add(output);
                    continue;
                }

                // Build dynamic SOQL based on provided inputs
                String soql =
                    'SELECT Id, Name, Description, Amount, ' +
                    'TransactionDate, PostedDate, ' +
                    'DebitCreditIndicator, Type, SubType, ' +
                    'Status, TransactionCode, TransactionIdentifier, ' +
                    'FinancialAccountId, ' +
                    'FinancialAccount.Name, ' +
                    'FinancialAccount.FinancialAccountNumber ' +
                    'FROM FinancialAccountTransaction ' +
                    'WHERE FinancialAccountId = :faId ' +
                    'AND DebitCreditIndicator = \'Debit\' ';

                Id faId = input.financialAccountId;

                if (input.amount != null) {
                    soql += 'AND Amount = :amt ';
                }
                if (input.transactionDate != null) {
                    soql += 'AND TransactionDate = :txnDate ';
                }
                if (String.isNotBlank(input.keyword)) {
                    soql += 'AND Description LIKE :kw ';
                }

                soql += 'ORDER BY TransactionDate DESC LIMIT 1';

                Decimal amt  = input.amount;
                Date txnDate = input.transactionDate;
                String kw    = '%' + input.keyword + '%';

                List<FinancialAccountTransaction> txns =
                    Database.query(soql);

                if (txns.isEmpty()) {
                    output.result.error =
                        'No matching transaction found. ' +
                        'Please verify the amount, merchant, or date.';
                    outputs.add(output);
                    continue;
                }

                FinancialAccountTransaction txn = txns[0];
                output.result.transactionId          = txn.Id;
                output.result.transactionName        = txn.Name;
                output.result.description            = txn.Description;
                output.result.amount                 = txn.Amount;
                output.result.transactionDate        = String.valueOf(txn.TransactionDate);
                output.result.postedDate             = String.valueOf(txn.PostedDate);
                output.result.debitCreditIndicator   = txn.DebitCreditIndicator;
                output.result.type                   = txn.Type;
                output.result.subType                = txn.SubType;
                output.result.status                 = txn.Status;
                output.result.transactionCode        = txn.TransactionCode;
                output.result.transactionIdentifier  = txn.TransactionIdentifier;
                output.result.financialAccountId     = txn.FinancialAccountId;
                output.result.financialAccountName   = txn.FinancialAccount.Name;
                output.result.financialAccountNumber =
                    txn.FinancialAccount.FinancialAccountNumber;

            } catch (Exception e) {
                output.result.error =
                    'Error finding transaction: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}