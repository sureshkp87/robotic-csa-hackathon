global class DisputeTransactionWrapper implements Callable {

    @AuraEnabled global String transactionId;
    @AuraEnabled global String transactionName;
    @AuraEnabled global String description;
    @AuraEnabled global Decimal amount;
    @AuraEnabled global String transactionDate;
    @AuraEnabled global String postedDate;
    @AuraEnabled global String debitCreditIndicator;
    @AuraEnabled global String type;
    @AuraEnabled global String subType;
    @AuraEnabled global String status;
    @AuraEnabled global String transactionCode;
    @AuraEnabled global String transactionIdentifier;
    @AuraEnabled global String financialAccountId;
    @AuraEnabled global String financialAccountName;
    @AuraEnabled global String financialAccountNumber;
    @AuraEnabled global String error;

    global DisputeTransactionWrapper() {
        this.error = null;
    }

    global Object call(String action, Map<String, Object> args) {
        return null;
    }
}