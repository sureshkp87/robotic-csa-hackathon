global class DisputeWrapper implements Callable {

    @AuraEnabled global String disputeId;
    @AuraEnabled global String disputeNumber;
    @AuraEnabled global String status;
    @AuraEnabled global String disputeType;
    @AuraEnabled global String disputeSubtype;
    @AuraEnabled global String disputeItemId;
    @AuraEnabled global Decimal disputedAmount;
    @AuraEnabled global Decimal approvedAmount;
    @AuraEnabled global Decimal transactionAmount;
    @AuraEnabled global String merchantName;
    @AuraEnabled global String merchantCity;
    @AuraEnabled global String merchantCategory;
    @AuraEnabled global String transactionDate;
    @AuraEnabled global String transactionDescription;
    @AuraEnabled global String transactionId;
    @AuraEnabled global String provisionalCreditStatus;
    @AuraEnabled global Decimal approvedProvisionalCredit; // standard field
    @AuraEnabled global String provisionalCreditDate;
    @AuraEnabled global String cardLastFourDigit;
    @AuraEnabled global String cardBrand;
    @AuraEnabled global String financialAccountId;
    @AuraEnabled global String error;

    global DisputeWrapper() {
        this.error = null;
    }

    global Object call(String action, Map<String, Object> args) {
        return null;
    }
}