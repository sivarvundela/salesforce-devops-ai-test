public with sharing class AccountHierarchyController {
    
    public class HierarchyNode {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String details { get; set; }
        @AuraEnabled public List<HierarchyNode> children { get; set; }
        
        public HierarchyNode(String id, String name, String type, String details) {
            this.id = id;
            this.name = name;
            this.type = type;
            this.details = details;
            this.children = new List<HierarchyNode>();
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<HierarchyNode> getHierarchy(Id recordId) {
        if (recordId == null) {
            return new List<HierarchyNode>();
        }
        
        Id ultimateParentId = findUltimateParent(recordId);
        
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        List<Account> level0 = [SELECT Id, Name, ParentId, Phone, Website, Industry, 
                                       BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                       ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry 
                                FROM Account 
                                WHERE Id = :ultimateParentId 
                                WITH SECURITY_ENFORCED];
        if (level0.isEmpty()) {
            return new List<HierarchyNode>();
        }
        accountsMap.putAll(level0);
        
        // Query down level 1
        List<Account> level1 = [SELECT Id, Name, ParentId, Phone, Website, Industry, 
                                       BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                       ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry 
                                FROM Account 
                                WHERE ParentId = :ultimateParentId 
                                WITH SECURITY_ENFORCED];
        if (!level1.isEmpty()) {
            accountsMap.putAll(level1);
            Set<Id> level1Ids = (new Map<Id, Account>(level1)).keySet();
            
            // Query down level 2
            List<Account> level2 = [SELECT Id, Name, ParentId, Phone, Website, Industry, 
                                           BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                           ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry 
                                    FROM Account 
                                    WHERE ParentId IN :level1Ids 
                                    WITH SECURITY_ENFORCED];
            if (!level2.isEmpty()) {
                accountsMap.putAll(level2);
                Set<Id> level2Ids = (new Map<Id, Account>(level2)).keySet();
                
                // Query down level 3
                List<Account> level3 = [SELECT Id, Name, ParentId, Phone, Website, Industry, 
                                               BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, 
                                               ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry 
                                        FROM Account 
                                        WHERE ParentId IN :level2Ids 
                                        WITH SECURITY_ENFORCED];
                if (!level3.isEmpty()) {
                    accountsMap.putAll(level3);
                }
            }
        }
        
        // Query Related Contacts
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact con : [SELECT Id, Name, Email, Phone, Title, AccountId 
                             FROM Contact 
                             WHERE AccountId IN :accountsMap.keySet() 
                             WITH SECURITY_ENFORCED]) { 
            if (!contactsByAccountId.containsKey(con.AccountId)) {
                contactsByAccountId.put(con.AccountId, new List<Contact>());
            }
            contactsByAccountId.get(con.AccountId).add(con);
        }
        
        // Query ContactPointAddress records dynamically to secure safe deployments across various org configurations
        Map<Id, List<SObject>> addressesByAccountId = new Map<Id, List<SObject>>();
        if (Schema.getGlobalDescribe().containsKey('contactpointaddress')) {
            try {
                Set<Id> accIds = accountsMap.keySet();
                String query = 'SELECT Id, Name, AddressType, Street, City, State, PostalCode, Country, ParentId FROM ContactPointAddress WHERE ParentId IN :accIds';
                List<SObject> cpas = Database.query(query);
                for (SObject cpa : cpas) {
                    Id parentId = (Id)cpa.get('ParentId');
                    if (!addressesByAccountId.containsKey(parentId)) {
                        addressesByAccountId.put(parentId, new List<SObject>());
                    }
                    addressesByAccountId.get(parentId).add(cpa);
                }
            } catch (Exception e) {
                // Gracefully fallback if ContactPointAddress execution encounters errors
            }
        }
        
        // Build node structures
        Map<Id, HierarchyNode> accountNodes = new Map<Id, HierarchyNode>();
        for (Account acc : accountsMap.values()) {
            String details = 'Phone: ' + (acc.Phone != null ? acc.Phone : 'N/A') + ' | Industry: ' + (acc.Industry != null ? acc.Industry : 'N/A');
            accountNodes.put(acc.Id, new HierarchyNode(acc.Id, acc.Name, 'Account', details));
        }
        
        // Attach child records to each node
        for (Id accId : accountsMap.keySet()) {
            HierarchyNode accNode = accountNodes.get(accId);
            Account acc = accountsMap.get(accId);
            
            // 1. Map Related Contacts
            if (contactsByAccountId.containsKey(accId)) {
                for (Contact con : contactsByAccountId.get(accId)) {
                    String conDetails = 'Email: ' + (con.Email != null ? con.Email : 'N/A') + ' | Title: ' + (con.Title != null ? con.Title : 'N/A');
                    accNode.children.add(new HierarchyNode(con.Id, con.Name, 'Contact', conDetails));
                } 
            }
            
            // 2. Map Dynamic Contact Point Addresses if any exist
            if (addressesByAccountId.containsKey(accId)) {
                for (SObject cpa : addressesByAccountId.get(accId)) {
                    String name = (String)cpa.get('Name');
                    String type = (String)cpa.get('AddressType');
                    String street = (String)cpa.get('Street');
                    String city = (String)cpa.get('City');
                    String state = (String)cpa.get('State');
                    String zip = (String)cpa.get('PostalCode');
                    String addrDetails = (street != null ? street + ', ' : '') + 
                                         (city != null ? city + ', ' : '') + 
                                         (state != null ? state + ' ' : '') + 
                                         (zip != null ? zip : '');
                    accNode.children.add(new HierarchyNode((Id)cpa.get('Id'), name + ' (' + (type != null ? type : 'Billing') + ')', 'Address', addrDetails));
                }
            }
            
            // 3. Render Virtual Address nodes from Standard Address fields to guarantee Address presence 
            if (acc.BillingStreet != null || acc.BillingCity != null) {
                String billingDetails = (acc.BillingStreet != null ? acc.BillingStreet + ', ' : '') + 
                                        (acc.BillingCity != null ? acc.BillingCity + ', ' : '') + 
                                        (acc.BillingState != null ? acc.BillingState + ' ' : '') + 
                                        (acc.BillingPostalCode != null ? acc.BillingPostalCode : '');
                accNode.children.add(new HierarchyNode(acc.Id + '_billing', 'Billing Address', 'Address', billingDetails));
            }
            if (acc.ShippingStreet != null || acc.ShippingCity != null) {
                String shippingDetails = (acc.ShippingStreet != null ? acc.ShippingStreet + ', ' : '') + 
                                         (acc.ShippingCity != null ? acc.ShippingCity + ', ' : '') + 
                                         (acc.ShippingState != null ? acc.ShippingState + ' ' : '') + 
                                         (acc.ShippingPostalCode != null ? acc.ShippingPostalCode : '');
                accNode.children.add(new HierarchyNode(acc.Id + '_shipping', 'Shipping Address', 'Address', shippingDetails));
            }
        }
        
        // Link Parent-Child Account Nodes to output the tree roots
        List<HierarchyNode> rootNodes = new List<HierarchyNode>();
        for (Account acc : accountsMap.values()) {
            HierarchyNode node = accountNodes.get(acc.Id);
            if (acc.ParentId != null && accountsMap.containsKey(acc.ParentId)) {
                accountNodes.get(acc.ParentId).children.add(node); 
            } else {
                rootNodes.add(node);
            }
        }
        
        return rootNodes;
    }
    
    private static Id findUltimateParent(Id recordId) {
        Id currentId = recordId;
        for (Integer i = 0; i < 5; i++) {
            List<Account> accs = [SELECT ParentId FROM Account WHERE Id = :currentId WITH SECURITY_ENFORCED LIMIT 1];
            if (!accs.isEmpty() && accs[0].ParentId != null) {
                currentId = accs[0].ParentId;
            } else {
                break;
            }
        }
        return currentId;
    }
}