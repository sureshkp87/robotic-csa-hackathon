import { LightningElement, api, track } from 'lwc';

const ICON_MAP = {
    'Savings':     'standard:account',
    'Credit Card': 'standard:payment_gateway',
    'Checking':    'standard:currency',
    'Investment':  'standard:opportunity'
};

export default class FinancialAccountsCard extends LightningElement {

    // Agentforce binds the serialized IP output to this property
    @api outputPayload;

    @track accounts = [];

    connectedCallback() {
        this.parsePayload();
    }

    parsePayload() {
        try {
            const raw = typeof this.outputPayload === 'string'
                ? JSON.parse(this.outputPayload)
                : this.outputPayload;

            // Navigate to FinancialAccounts array in IP output
            const ipOutput = raw?.IntegrationProcedureOutput ?? raw;
            const list = ipOutput?.FinancialAccounts;

            if (!Array.isArray(list) || list.length === 0) return;

            this.accounts = list
                .filter(acct => acct.FinancialAccountId) // guard nulls
                .map(acct => ({
                    ...acct,
                    iconName:     ICON_MAP[acct.FinancialAccountType] ?? 'standard:account',
                    statusClass:  acct.Status === 'Active' ? 'slds-theme_success' : 'slds-theme_warning',
                    heldAwayLabel: acct.isHeldAway ? 'Yes' : 'No'
                }));

        } catch (e) {
            console.error('[FinancialAccountsCard] Failed to parse outputPayload:', e);
        }
    }

    get accountCount() {
        return String(this.accounts.length);
    }
}