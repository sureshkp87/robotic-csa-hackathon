global class FAOutputWrapper implements Callable{

    @AuraEnabled global List<FinancialAccountData> financialAccounts;
    @AuraEnabled global String error;

    global FAOutputWrapper() {
        this.financialAccounts = new List<FinancialAccountData>();
        this.error = null;
    }
	// Required by Callable interface
    global Object call(String action, Map<String, Object> args) {
        return null;
    }
    global class FinancialAccountData {
        @AuraEnabled global String financialAccountId;
        @AuraEnabled global String financialAccountName;
        @AuraEnabled global String financialAccountNumber;
        @AuraEnabled global String financialAccountType;
        @AuraEnabled global String status;
        @AuraEnabled global String role;
        @AuraEnabled global Boolean isHeldAway;

        global FinancialAccountData(
            FinancialAccount fa,
            String role
        ) {
            this.financialAccountId     = fa.Id;
            this.financialAccountName   = fa.Name;
            this.financialAccountNumber = fa.FinancialAccountNumber;
            this.financialAccountType   = fa.Type;           // corrected
            this.status                 = fa.Status;
            this.role                   = role;
            this.isHeldAway             = fa.IsHeldAway != null
                                            ? fa.IsHeldAway
                                            : false;
        }
    }
}