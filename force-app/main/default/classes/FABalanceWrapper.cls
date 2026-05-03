global class FABalanceWrapper {

    @AuraEnabled global String financialAccountId;
    @AuraEnabled global String financialAccountName;
    @AuraEnabled global String financialAccountNumber;
    @AuraEnabled global String financialAccountType;
    @AuraEnabled global String status;
    @AuraEnabled global String currencyCode;
    @AuraEnabled global String asOfDate;
    @AuraEnabled global String error;

    @AuraEnabled global List<BalanceEntry> balances;

    global FABalanceWrapper() {
        this.balances = new List<BalanceEntry>();
        this.error = null;
    }

    global class BalanceEntry {
        @AuraEnabled global String balanceType;
        @AuraEnabled global Decimal amount;
        @AuraEnabled global String balanceAsOfDate;

        global BalanceEntry(FinancialAccountBalance fab) {
            this.balanceType     = fab.Type;
            this.amount          = fab.Amount;
            this.balanceAsOfDate = fab.BalanceAsOfDate != null
                ? String.valueOf(fab.BalanceAsOfDate)
                : null;
        }
    }
}