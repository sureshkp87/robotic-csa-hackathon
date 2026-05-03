global class CheckDisputeStatusAction {

    global class ActionInput {
        @InvocableVariable(label='Contact Id' required=true)
        global Id contactId;

        @InvocableVariable(label='Dispute Number')
        global String disputeNumber;
    }

    global class ActionOutput {
        @InvocableVariable(label='Dispute Status Output')
        global DisputeWrapper result;
    }

    @InvocableMethod(
        label='Check Dispute Status'
        description='Returns current status and stage of a Dispute using standard FSC Dispute object'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new DisputeWrapper();

            try {
                Contact con = [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id = :input.contactId
                    LIMIT 1
                ];

                List<Dispute> disputes;

                if (String.isNotBlank(input.disputeNumber)) {
                    disputes = [
                        SELECT
                            Id,
                            Name,
                            Status,
                            DisputeType,
                            DisputeSubtype,
                            DisputedAmount,
                            ApprovedAmount,
                            FinancialAccountId,
                            Description,
                            ReceivedDate,
                            (
                                SELECT
                                    Id,
                                    Status,
                                    DisputedAmount,
                                    TransactionAmount,
                                    TransactionDate,
                                    TransactionDescription,
                                    MerchantName,
                                    MerchantCity,
                                    MerchantCategory,
                                    CardLastFourDigit,
                                    CardBrand,
                                    ProvisionalCreditStatus,
                                    ProvisionalCreditDate,
                                    ApprovedProvisionalCredit,
                                    ProvisionalCreditApproverId
                                FROM RelatedDispute
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            )
                        FROM Dispute
                        WHERE AccountId = :con.AccountId
                          AND Name = :input.disputeNumber
                        LIMIT 1
                    ];
                } else {
                    disputes = [
                        SELECT
                            Id,
                            Name,
                            Status,
                            DisputeType,
                            DisputeSubtype,
                            DisputedAmount,
                            ApprovedAmount,
                            FinancialAccountId,
                            Description,
                            ReceivedDate,
                            (
                                SELECT
                                    Id,
                                    Status,
                                    DisputedAmount,
                                    TransactionAmount,
                                    TransactionDate,
                                    TransactionDescription,
                                    MerchantName,
                                    MerchantCity,
                                    MerchantCategory,
                                    CardLastFourDigit,
                                    CardBrand,
                                    ProvisionalCreditStatus,
                                    ProvisionalCreditDate,
                                    ApprovedProvisionalCredit,
                                    ProvisionalCreditApproverId
                                FROM RelatedDispute
                                ORDER BY CreatedDate DESC
                                LIMIT 1
                            )
                        FROM Dispute
                        WHERE AccountId = :con.AccountId
                          AND Status != 'Closed'
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                }

                if (disputes.isEmpty()) {
                    output.result.error = 'No active dispute found for your account.';
                    outputs.add(output);
                    continue;
                }

                Dispute d = disputes[0];
                output.result.disputeId          = d.Id;
                output.result.disputeNumber      = d.Name;
                output.result.status             = d.Status;
                output.result.disputeType        = d.DisputeType;
                output.result.disputeSubtype     = d.DisputeSubtype;
                output.result.disputedAmount     = d.DisputedAmount;
                output.result.approvedAmount     = d.ApprovedAmount;
                output.result.financialAccountId = d.FinancialAccountId;

                if (!d.RelatedDispute.isEmpty()) {
                    DisputeItem di = d.RelatedDispute[0];
                    output.result.disputeItemId              = di.Id;
                    output.result.transactionAmount          = di.TransactionAmount;
                    output.result.merchantName               = di.MerchantName;
                    output.result.merchantCity               = di.MerchantCity;
                    output.result.merchantCategory           = di.MerchantCategory;
                    output.result.transactionDate            = String.valueOf(di.TransactionDate);
                    output.result.transactionDescription     = di.TransactionDescription;
                    output.result.cardLastFourDigit          = di.CardLastFourDigit;
                    output.result.cardBrand                  = di.CardBrand;

                    // Correct ProvisionalCreditStatus values:
                    // Initiated, In Progress, Completed, Not Applicable
                    output.result.provisionalCreditStatus    = di.ProvisionalCreditStatus;
                    output.result.provisionalCreditDate      = di.ProvisionalCreditDate != null
                        ? String.valueOf(di.ProvisionalCreditDate)
                        : null;
                    output.result.approvedProvisionalCredit  = di.ApprovedProvisionalCredit;
                }

            } catch (Exception e) {
                output.result.error = 'Error fetching dispute status: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }
}