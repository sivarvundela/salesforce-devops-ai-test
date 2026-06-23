@IsTest
public class AccountHierarchyControllerTest {
    @TestSetup
    static void setup() {
        Account parentAcc = new Account(Name = 'Parent Account', Phone = '123-456-7890', Industry = 'Technology', BillingStreet = '123 Main St', BillingCity = 'San Francisco', BillingState = 'CA', BillingPostalCode = '94105');
        insert parentAcc;
        
        Account childAcc = new Account(Name = 'Child Account', ParentId = parentAcc.Id, Phone = '234-567-8901', Industry = 'Manufacturing', ShippingStreet = '456 Market St', ShippingCity = 'San Francisco', ShippingState = 'CA', ShippingPostalCode = '94105');
        insert childAcc;
        
        Account grandChildAcc = new Account(Name = 'Grandchild Account', ParentId = childAcc.Id, Phone = '345-678-9012', Industry = 'Finance');
        insert grandChildAcc;
        
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Parent Contact', Email = 'parent@test.com', Title = 'CEO', AccountId = parentAcc.Id),
            new Contact(LastName = 'Child Contact', Email = 'child@test.com', Title = 'Manager', AccountId = childAcc.Id)
        };
        insert contacts;
    }
    
    @IsTest
    static void testGetHierarchy() {
        Account grandChild = [SELECT Id FROM Account WHERE Name = 'Grandchild Account' LIMIT 1];
        Account parent = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1];
        
        Test.startTest();
        List<AccountHierarchyController.HierarchyNode> resultFromGrandchild = AccountHierarchyController.getHierarchy(grandChild.Id);
        List<AccountHierarchyController.HierarchyNode> resultFromParent = AccountHierarchyController.getHierarchy(parent.Id);
        List<AccountHierarchyController.HierarchyNode> resultNull = AccountHierarchyController.getHierarchy(null);
        Test.stopTest();
        
        System.assertNotEquals(0, resultFromGrandchild.size(), 'Hierarchy should be successfully retrieved.');
        System.assertEquals('Parent Account', resultFromGrandchild[0].name, 'Root account should be the ultimate parent.');
        System.assertNotEquals(0, resultFromParent.size(), 'Hierarchy should return results starting from parent.');
        System.assertEquals(0, resultNull.size(), 'Null check should return empty hierarchy safely.');
    }
    
    @IsTest
    static void testBulkHierarchy() {
        Account parent = [SELECT Id FROM Account WHERE Name = 'Parent Account' LIMIT 1];
        List<Account> bulkChildren = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            bulkChildren.add(new Account(Name = 'Bulk Child ' + i, ParentId = parent.Id));
        }
        
        Test.startTest();
        insert bulkChildren;
        List<AccountHierarchyController.HierarchyNode> result = AccountHierarchyController.getHierarchy(parent.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, result.size(), 'Bulk execution should not fail limits and return hierarchy.');
    }
}