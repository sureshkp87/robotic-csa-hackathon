global class CreateDisputeAction {

    global class ActionInput {
        @InvocableVariable(label='Contact Id' required=true)
        global Id contactId;

        @InvocableVariable(label='Financial Account Id' required=true)
        global Id financialAccountId;

        @InvocableVariable(label='Transaction Id' required=true)
        global String transactionId;

        @InvocableVariable(label='Disputed Amount' required=true)
        global Decimal disputedAmount;

        @InvocableVariable(label='Merchant Name' required=true)
        global String merchantName;

        @InvocableVariable(label='Transaction Date' required=true)
        global Date transactionDate;

        @InvocableVariable(label='Customer Reason Description')
        global String reasonDescription;
    }

    global class ActionOutput {
        @InvocableVariable(label='Dispute Output')
        global DisputeWrapper result;
    }

    @InvocableMethod(
        label='Create Dispute'
        description='Creates a Dispute and DisputeItem using standard FSC Transaction Dispute Management objects'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new DisputeWrapper();

            try {
                // Get AccountId from Contact
                Contact con = [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id = :input.contactId
                    LIMIT 1
                ];

                // Step 1 — Create parent Dispute record
                Dispute dispute = new Dispute(
                    AccountId           = con.AccountId,
                    Status              = 'Open',
                    FinancialAccountId  = input.financialAccountId,
                    Description         = input.reasonDescription,
                    ReceivedDate        = Date.today()
                );
                insert dispute;

                // Step 2 — Create DisputeItem linked to Dispute + Transaction
                DisputeItem disputeItem = new DisputeItem(
                    DisputeId                   = dispute.Id,
                    TransactionIdentifier       = input.transactionId,
                    DisputedAmount              = input.disputedAmount,
                    MerchantName                = input.merchantName,
                    TransactionDate             = input.transactionDate,
                    Status                      = 'Open'
                );
                insert disputeItem;

                // Fetch with auto-generated number
                dispute = [
                    SELECT Id, Name, Status
                    FROM Dispute
                    WHERE Id = :dispute.Id
                    LIMIT 1
                ];

                output.result.disputeId           = dispute.Id;
                output.result.disputeNumber       = dispute.Name;
                output.result.status              = dispute.Status;
                output.result.disputeItemId       = disputeItem.Id;
                output.result.disputedAmount      = input.disputedAmount;
                output.result.merchantName        = input.merchantName;
                output.result.transactionDate     = String.valueOf(input.transactionDate);
                output.result.financialAccountId  = input.financialAccountId;
                output.result.transactionId       = input.transactionId;

            } catch (Exception e) {
                output.result.error = 'Error creating dispute: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}