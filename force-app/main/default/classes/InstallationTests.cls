//Hello
//Hello Again
/* 
 * This class can be safely deleted from your org. 
 * It was only used to ensure 100% test coverage
 * for the managed package installation.
 * Welcome to JenkinsSFDXProject123 Hello
 */

@IsTest
private class InstallationTests {
    static testmethod void testMaintenanceRequest() {
        MaintenanceRequestHelper.updateWorkOrders();
    }
    static testmethod void testWarehouseSync() {
        WarehouseCalloutService.runWarehouseEquipmentSync();
    }    
}