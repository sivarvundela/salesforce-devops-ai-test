// Generated Apex class to satisfy the component's dependency
public with sharing class AccountHierarchyService {
    
    @AuraEnabled
    public static List<Account> getAccountHierarchy(String accountId) {
        // Placeholder implementation - in a real scenario, this would query the actual account hierarchy
        return new List<Account> {
            new Account(
                Id = accountId,
                Name = 'Test Account',
                BillingStreet = '123 Test St',
                BillingCity = 'Test City',
                BillingState = 'Test State',
                BillingPostalCode = '12345',
                BillingCountry = 'Test Country'
            )
        };
    }
}