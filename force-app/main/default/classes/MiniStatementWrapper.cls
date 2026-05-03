global class MiniStatementWrapper implements Callable {

    @AuraEnabled global String financialAccountId;
    @AuraEnabled global String financialAccountName;
    @AuraEnabled global String financialAccountNumber;
    @AuraEnabled global String financialAccountType;
    @AuraEnabled global String currencyCode;
    @AuraEnabled global String error;
    @AuraEnabled global List<TransactionEntry> transactions;

    global MiniStatementWrapper() {
        this.transactions = new List<TransactionEntry>();
        this.error = null;
    }

    global Object call(String action, Map<String, Object> args) {
        return null;
    }

    global class TransactionEntry {
        @AuraEnabled global String transactionId;
        @AuraEnabled global String transactionName;
        @AuraEnabled global String transactionDate;
        @AuraEnabled global String postedDate;
        @AuraEnabled global String description;
        @AuraEnabled global Decimal amount;
        @AuraEnabled global String debitCreditIndicator;
        @AuraEnabled global String type;
        @AuraEnabled global String subType;
        @AuraEnabled global String status;
        @AuraEnabled global String transactionCode;
        @AuraEnabled global String transactionIdentifier;
        @AuraEnabled global String currencyCode;

        global TransactionEntry(FinancialAccountTransaction txn) {
            this.transactionId          = txn.Id;
            this.transactionName        = txn.Name;
            this.transactionDate        = txn.TransactionDate != null
                ? String.valueOf(txn.TransactionDate)
                : null;
            this.postedDate             = txn.PostedDate != null
                ? String.valueOf(txn.PostedDate)
                : null;
            this.description            = txn.Description;
            this.amount                 = txn.Amount;
            this.debitCreditIndicator   = txn.DebitCreditIndicator;
            this.type                   = txn.Type;
            this.subType                = txn.SubType;
            this.status                 = txn.Status;
            this.transactionCode        = txn.TransactionCode;
            this.transactionIdentifier  = txn.TransactionIdentifier;
            this.currencyCode           = txn.CurrencyIsoCode;
        }
    }
}