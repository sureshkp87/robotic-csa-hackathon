global without sharing class AIBillExtractAction {

    global class ActionInput {
        @InvocableVariable(label='Messaging Id' required=true)
        global Id messagingSessionId;
        
        @InvocableVariable(label='Dispute Id' required=true)
        global Id disputeId;
        
        @InvocableVariable(label='Dispute Item Id' required=true)
        global Id disputeItemId;
    }

    global class ActionOutput {
        @InvocableVariable(label='AI Extract Output')
        global DisputeWrapper result;
    }

    @InvocableMethod(
        label='Extract Bill Details from Image'
        description='Saves bill image as Salesforce File on Dispute and extracts amount and date using AI'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();
            output.result = new DisputeWrapper();

            try {
                // ─────────────────────────────────────────
                // Step 1 — Save image as ContentVersion
                // linked to Dispute record
                // ─────────────────────────────────────────
                /*
				list<ContentDocumentLink> lstCDL = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink 
                                                  WHERE LinkedEntityId = :input.messagingSessionId
                                                  ORDER BY SystemModstamp Desc limit 1];
                list<ContentVersion> lstCV = [SELECT Id, ContentDocumentId,IsLatest,PublishStatus FROM ContentVersion 
                                				WHERE ContentDocumentId=: lstCDL[0].ContentDocumentId AND isLatest = TRUE AND PublishStatus = 'P'];
				*/                
// ─────────────────────────────────────────
                // Step 2 — Call your AI extraction
                // Replace this block with your own
                // Einstein Prompt / Apex implementation
                // ─────────────────────────────────────────
                Map<String, Object> extracted =
                    extractDetailsFromImage('069bm00000IsDM5AAN');//(lstCV[0].ContentDocumentId);

                Decimal aiAmount  = extracted.get('amount') != null
                    ? Decimal.valueOf(String.valueOf(extracted.get('amount')))
                    : null;
                String aiDateStr  = (String) extracted.get('date');
                String aiMerchant = (String) extracted.get('merchant');

                // ─────────────────────────────────────────
                // Step 3 — Update DisputeItem with
                // extracted details — standard fields only
                // ─────────────────────────────────────────
                DisputeItem di = new DisputeItem(
                    Id     = input.disputeItemId
                );

                if (aiAmount != null) {
                    di.TransactionAmount = aiAmount;
                }
                if (String.isNotBlank(aiDateStr)) {
                    di.TransactionDate = Date.valueOf(aiDateStr);
                }
                if (String.isNotBlank(aiMerchant)) {
                    di.MerchantName = aiMerchant;
                }

                // Mark evidence as submitted via MerchantDetails field
                di.MerchantDetails = 'Evidence submitted via image upload. ' +
                    'Extracted amount: ' + aiAmount +
                    ', Date: ' + aiDateStr;

                update di;

                // ─────────────────────────────────────────
                // Step 4 — Return updated Dispute details
                // ─────────────────────────────────────────
                Dispute d = [
                    SELECT Id, Name, Status, DisputeType,
                           DisputedAmount, ApprovedAmount,
                           FinancialAccountId,
                           (SELECT Id, Status,
                                   DisputedAmount,
                                   TransactionAmount,
                                   TransactionDate,
                                   TransactionDescription,
                                   MerchantName,
                                   MerchantDetails,
                                   MerchantCity,
                                   MerchantCategory,
                                   ProvisionalCreditStatus,
                                   ProvisionalCreditDate,
                                   ApprovedProvisionalCredit,
                                   CardLastFourDigit,
                                   CardBrand
                            FROM RelatedDispute
                            WHERE Id = :input.disputeItemId
                            LIMIT 1)
                    FROM Dispute
                    WHERE Id = :input.disputeId
                    LIMIT 1
                ];

                output.result.disputeId          = d.Id;
                output.result.disputeNumber      = d.Name;
                output.result.status             = d.Status;
                output.result.disputeType        = d.DisputeType;
                output.result.disputedAmount     = d.DisputedAmount;
                output.result.approvedAmount     = d.ApprovedAmount;
                output.result.financialAccountId = d.FinancialAccountId;

                if (!d.RelatedDispute.isEmpty()) {
                    DisputeItem updatedDi            = d.RelatedDispute[0];
                    output.result.disputeItemId      = updatedDi.Id;
                    output.result.transactionAmount  = updatedDi.TransactionAmount;
                    output.result.transactionDate    = String.valueOf(
                        updatedDi.TransactionDate);
                    output.result.merchantName       = updatedDi.MerchantName;
                    output.result.merchantCity       = updatedDi.MerchantCity;
                    output.result.merchantCategory   = updatedDi.MerchantCategory;
                    output.result.provisionalCreditStatus =
                        updatedDi.ProvisionalCreditStatus;
                    output.result.provisionalCreditDate =
                        updatedDi.ProvisionalCreditDate != null
                            ? String.valueOf(updatedDi.ProvisionalCreditDate)
                            : null;
                    output.result.approvedProvisionalCredit =
                        updatedDi.ApprovedProvisionalCredit;
                    output.result.cardLastFourDigit  = updatedDi.CardLastFourDigit;
                    output.result.cardBrand          = updatedDi.CardBrand;
                }

            } catch (Exception e) {
                output.result.error =
                    'Error processing bill image: ' + e.getMessage();
            }

            outputs.add(output);
        }

        return outputs;
    }

    // ─────────────────────────────────────────────────────
    // Replace this method with your own Einstein Prompt
    // or Apex AI implementation.
    // Expected return: Map with keys 'amount', 'date', 'merchant'
    // ─────────────────────────────────────────────────────
    global static Map<String, Object> extractDetailsFromImage(
        String contentId
    ) {
        // ---- PLUG IN YOUR IMPLEMENTATION HERE ----
        // Option A: Einstein Prompt Template via ConnectApi
        // Option B: Custom HTTP callout to your AI service
        // Option C: Any Apex-based extraction logic
        //
        // Must return a Map with these keys:
        // {
        //   'amount'   : Decimal or String number,
        //   'date'     : String in 'YYYY-MM-DD' format,
        //   'merchant' : String merchant name
        // }
        // ------------------------------------------
		// 1. Prepare the input file as a map with its ID
        Map<String, String> fileInputMap = new Map<String, String>();
        fileInputMap.put('id', contentId); // Your ContentDocument Id
        
        // 2. Wrap the input map
        ConnectApi.WrappedValue fileWrappedValue = new ConnectApi.WrappedValue();
        fileWrappedValue.value = fileInputMap;
        
        // 3. Map it to the prompt's defined input (note the 'Input:' prefix)
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:FileInput', fileWrappedValue); 
        
        // 4. Configure the generation input object
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        promptInput.inputParams = inputParams;
        promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        promptInput.isPreview = false;
        
        // 5. Execute the template
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
        ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('0hfbm00000KgOGvAAN', promptInput);
        system.debug('============response 1111============'+response);
        // 6. Get the result text
        String resultText = response.generations[0].text;
        system.debug('============response============'+resultText);
        // Placeholder — replace with real implementation
        return new Map<String, Object>{
            'amount'   => 720,
            'date'     => '2026-4-29',
            'merchant' => 'Swiggy - Food order'
        };
    }
}