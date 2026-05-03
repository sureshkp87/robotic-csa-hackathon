global class IssueProvisionalCreditAction {

    global class ActionInput {
        @InvocableVariable(label='Dispute Id' required=true)
        global Id disputeId;

        @InvocableVariable(label='Dispute Item Id' required=true)
        global Id disputeItemId;

        @InvocableVariable(label='Financial Account Id' required=true)
        global Id financialAccountId;

        @InvocableVariable(label='Credit Amount' required=true)
        global Decimal creditAmount;
    }

    global class ActionOutput {
        @InvocableVariable(label='Provisional Credit Output')
        global DisputeWrapper result;
    }

    @InvocableMethod(
        label='Issue Provisional Credit'
        description='Issues provisional credit transaction and updates DisputeItem using standard FSC fields'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new DisputeWrapper();

            try {
                // Step 1 — Create provisional credit as FinancialAccountTransaction
                FinancialAccountTransaction creditTxn = new FinancialAccountTransaction(
                    FinancialAccountId    = input.financialAccountId,
                    TransactionDate       = Date.today(),
                    PostedDate            = Date.today(),
                    Description           = 'Provisional Credit - Dispute ' + input.disputeId,
                    Amount                = input.creditAmount,
                    DebitCreditIndicator  = 'Credit',
                    Type                  = 'Adjustment',
                    SubType               = 'Provisional Credit',
                    Status                = 'Posted',
                    TransactionCode       = 'PROV-CR',
                    TransactionIdentifier = 'PROV-' + input.disputeItemId
                );
                insert creditTxn;

                // Step 2 — Update DisputeItem using standard fields only
                DisputeItem di = new DisputeItem(
                    Id                        = input.disputeItemId,
                    ProvisionalCreditStatus   = 'Approved',
                    ProvisionalCreditDate     = Date.today(),
                    ApprovedProvisionalCredit = input.creditAmount
                );
                update di;

                // Step 3 — Fetch and return updated DisputeItem
                DisputeItem updatedItem = [
                    SELECT
                        Id,
                        Status,
                        DisputedAmount,
                        MerchantName,
                        TransactionDate,
                        TransactionDescription,
                        TransactionAmount,
                        ProvisionalCreditStatus,
                        ProvisionalCreditDate,
                        ApprovedProvisionalCredit,
                        ProvisionalCreditApproverId,
                        CardLastFourDigit,
                        CardBrand
                    FROM DisputeItem
                    WHERE Id = :input.disputeItemId
                    LIMIT 1
                ];

                output.result.disputeId               = input.disputeId;
                output.result.disputeItemId           = updatedItem.Id;
                output.result.status                  = updatedItem.Status;
                output.result.disputedAmount          = updatedItem.DisputedAmount;
                output.result.merchantName            = updatedItem.MerchantName;
                output.result.transactionDate         = String.valueOf(
                    updatedItem.TransactionDate);
                output.result.transactionDescription  = updatedItem.TransactionDescription;
                output.result.provisionalCreditStatus = updatedItem.ProvisionalCreditStatus;
                output.result.provisionalCreditDate   = updatedItem.ProvisionalCreditDate != null
                    ? String.valueOf(updatedItem.ProvisionalCreditDate)
                    : null;
                output.result.cardLastFourDigit       = updatedItem.CardLastFourDigit;
                output.result.cardBrand               = updatedItem.CardBrand;

            } catch (Exception e) {
                output.result.error = 'Error issuing provisional credit: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}