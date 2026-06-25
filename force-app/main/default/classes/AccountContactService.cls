/**
 * AccountContactService
 *
 * Provides @AuraEnabled methods to retrieve Account details and related
 * Contacts for display in Lightning components.
 *
 * Security: runs with sharing (respects org sharing model).
 * FLS:       enforced via WITH SECURITY_ENFORCED on all SOQL.
 * Errors:    all exceptions converted to AuraHandledException so LWC
 *            receives a clean, user-facing error message.
 */
public with sharing class AccountContactService {

    // ── Inner wrapper returned to the component ──────────────────────────────
    public class AccountContactWrapper {
        @AuraEnabled public Account       accountRecord { get; set; }
        @AuraEnabled public List<Contact> contacts      { get; set; }

        public AccountContactWrapper(Account acct, List<Contact> cons) {
            this.accountRecord = acct;
            this.contacts      = cons;
        }
    }

    // ── 1. Fetch Account + Contacts in a single call ─────────────────────────
    /**
     * Returns an AccountContactWrapper containing the Account record and its
     * related Contacts.
     *
     * @param accountId  Id of the Account to retrieve.
     * @return           AccountContactWrapper with accountRecord and contacts.
     * @throws AuraHandledException on invalid input or SOQL/security errors.
     */
    @AuraEnabled(cacheable=true)
    public static AccountContactWrapper getAccountWithContacts(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('accountId parameter is required.');
        }

        try {
            // Query Account — WITH SECURITY_ENFORCED enforces FLS
            List<Account> accounts = [
                SELECT Id, Name, Phone, Website,
                       BillingStreet, BillingCity, BillingState,
                       BillingPostalCode, BillingCountry,
                       Industry, Type, OwnerId, Owner.Name
                FROM   Account
                WHERE  Id = :accountId
                WITH   SECURITY_ENFORCED
                LIMIT  1
            ];

            if (accounts.isEmpty()) {
                throw new AuraHandledException(
                    'No Account found for Id: ' + accountId
                );
            }

            Account acct = accounts[0];

            // Query related Contacts — WITH SECURITY_ENFORCED enforces FLS
            List<Contact> contacts = [
                SELECT Id, FirstName, LastName, Email, Phone,
                       Title, Department, MobilePhone, MailingCity,
                       MailingState, MailingCountry
                FROM   Contact
                WHERE  AccountId = :accountId
                WITH   SECURITY_ENFORCED
                ORDER BY LastName ASC, FirstName ASC
            ];

            return new AccountContactWrapper(acct, contacts);

        } catch (AuraHandledException ahe) {
            // Re-throw explicitly thrown AuraHandledExceptions unchanged
            throw ahe;
        } catch (System.QueryException qe) {
            throw new AuraHandledException(
                'Query failed — you may lack access to required fields: ' + qe.getMessage()
            );
        } catch (Exception ex) {
            throw new AuraHandledException(
                'An unexpected error occurred: ' + ex.getMessage()
            );
        }
    }

    // ── 2. Fetch Account details only ────────────────────────────────────────
    /**
     * Returns a single Account record by Id.
     * Useful when the component only needs Account data without Contacts.
     *
     * @param accountId  Id of the Account to retrieve.
     * @return           Account SObject.
     * @throws AuraHandledException on invalid input or query errors.
     */
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('accountId parameter is required.');
        }

        try {
            List<Account> accounts = [
                SELECT Id, Name, Phone, Website,
                       BillingStreet, BillingCity, BillingState,
                       BillingPostalCode, BillingCountry,
                       Industry, Type, OwnerId, Owner.Name
                FROM   Account
                WHERE  Id = :accountId
                WITH   SECURITY_ENFORCED
                LIMIT  1
            ];

            if (accounts.isEmpty()) {
                throw new AuraHandledException(
                    'No Account found for Id: ' + accountId
                );
            }

            return accounts[0];

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (System.QueryException qe) {
            throw new AuraHandledException(
                'Query failed — you may lack access to required fields: ' + qe.getMessage()
            );
        } catch (Exception ex) {
            throw new AuraHandledException(
                'An unexpected error occurred: ' + ex.getMessage()
            );
        }
    }

    // ── 3. Fetch related Contacts only ───────────────────────────────────────
    /**
     * Returns the list of Contact records related to the given Account.
     *
     * @param accountId  Id of the parent Account.
     * @return           List<Contact> sorted by LastName, FirstName.
     * @throws AuraHandledException on invalid input or query errors.
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('accountId parameter is required.');
        }

        try {
            return [
                SELECT Id, FirstName, LastName, Email, Phone,
                       Title, Department, MobilePhone, MailingCity,
                       MailingState, MailingCountry
                FROM   Contact
                WHERE  AccountId = :accountId
                WITH   SECURITY_ENFORCED
                ORDER BY LastName ASC, FirstName ASC
            ];

        } catch (System.QueryException qe) {
            throw new AuraHandledException(
                'Query failed — you may lack access to required fields: ' + qe.getMessage()
            );
        } catch (Exception ex) {
            throw new AuraHandledException(
                'An unexpected error occurred: ' + ex.getMessage()
            );
        }
    }
}