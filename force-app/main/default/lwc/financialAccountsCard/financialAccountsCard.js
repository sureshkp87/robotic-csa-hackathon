import { LightningElement, api, track } from 'lwc';

const ICON_MAP = {
    'Savings':     'standard:account',
    'Credit Card': 'standard:payment_gateway',
    'Checking':    'standard:currency',
    'Investment':  'standard:opportunity'
};

export default class FinancialAccountsCard extends LightningElement {

    // Agentforce injects FAOutputWrapper fields directly via @api
    @api financialAccounts;  // List<FAOutputWrapper.FinancialAccountData>
    @api error;

    @track _accounts = [];

    connectedCallback() {
        this.buildAccounts();
    }

    buildAccounts() {
        try {
            const raw = Array.isArray(this.financialAccounts)
                ? this.financialAccounts
                : JSON.parse(this.financialAccounts ?? '[]');

            this._accounts = raw
                .filter(acct => acct.financialAccountId)
                .map(acct => ({
                    ...acct,
                    iconName: ICON_MAP[acct.financialAccountType] ?? 'standard:account'
                }));

        } catch (e) {
            console.error('[FinancialAccountsCard] Failed to parse financialAccounts:', e);
        }
    }

    get accounts() {
        return this._accounts;
    }

    get accountCount() {
        return this._accounts.length;
    }

    get hasAccounts() {
        return this._accounts.length > 0 && !this.error;
    }

    get hasError() {
        return !!this.error;
    }
}