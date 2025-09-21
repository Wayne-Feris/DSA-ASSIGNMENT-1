import ballerina/http;
import ballerina/io;

public enum AssetStatus {
    ACTIVE = "ACTIVE",
    UNDER_REPAIR = "UNDER_REPAIR",
    DISPOSED = "DISPOSED"
}
public type Component record {
    string componentId;
    string name;
};
public type MaintenanceSchedule record {
    string scheduleId;
    string nextDueDate;
    string description;
};
public type Task record {
    string taskId;
    string description;
};
public type WorkOrder record {
    string workOrderId;
    string description;
    string status;
    map<Task> tasks;
};
public type Asset record {
    string assetTag;
    string name;
    string faculty;
    string department;
    AssetStatus status;
    string acquiredDate;
    map<Component> components;
    map<MaintenanceSchedule> schedules;
    map<WorkOrder> workOrders;
};
public function main() returns error? {
    io:println("=== Asset Management Demo ===\n");
    
    io:println("Testing connection to server...");
    http:Client|error clientResult = new ("http://localhost:9090");
    if clientResult is error {
        io:println("ERROR: Could not create HTTP client: " + clientResult.message());
        return;
    }
    http:Client assetClient = clientResult;
    
    Asset[]|error testResponse = assetClient->get("/assets");
    if testResponse is error {
        io:println("ERROR: Server is not responding: " + testResponse.message());
        io:println("Make sure your service.bal is running on port 9090");
        return;
    }
    io:println("✓ Connection successful! Server is running.\n");
    
    io:println("1. Creating assets...");
    Asset asset1 = {
        assetTag: "EQ-001",
        name: "3D Printer",
        faculty: "Computing & Informatics",
        department: "Software Engineering",
        status: ACTIVE,
        acquiredDate: "2024-03-10",
        components: {},
        schedules: {},
        workOrders: {}
    };
    Asset asset2 = {
        assetTag: "EQ-002",
        name: "Dell Server",
        faculty: "Computing & Informatics",
        department: "Information Technology",
        status: ACTIVE,
        acquiredDate: "2024-01-15",
        components: {},
        schedules: {},
        workOrders: {}
    };
    http:Response|error response1 = assetClient->post("/assets", asset1);
    if response1 is error {
        io:println("ERROR creating EQ-001: " + response1.message());
        return;
    }
    io:println("Created EQ-001: " + response1.statusCode.toString());
    
    http:Response|error response2 = assetClient->post("/assets", asset2);
    if response2 is error {
        io:println("ERROR creating EQ-002: " + response2.message());
        return;
    }
    io:println("Created EQ-002: " + response2.statusCode.toString());
    io:println();
    
    io:println("2. All assets:");
    Asset[]|error allAssets = assetClient->get("/assets");
    if allAssets is error {
        io:println("ERROR getting assets: " + allAssets.message());
        return;
    }
    foreach Asset asset in allAssets {
        io:println("- " + asset.assetTag + ": " + asset.name);
    }
    io:println();
    
    io:println("3. Assets for Computing & Informatics:");
    Asset[]|error ciAssets = assetClient->get("/assets/faculty/Computing%20%26%20Informatics");
    if ciAssets is error {
        io:println("ERROR getting faculty assets: " + ciAssets.message());
        return;
    }
    foreach Asset asset in ciAssets {
        io:println("- " + asset.assetTag + ": " + asset.name);
    }
    io:println();
    
    io:println("4. Updating EQ-001 to UNDER_REPAIR...");
    asset1.status = UNDER_REPAIR;
    http:Response|error updateResponse = assetClient->put("/assets/EQ-001", asset1);
    if updateResponse is error {
        io:println("ERROR updating asset: " + updateResponse.message());
        return;
    }
    io:println("Update status: " + updateResponse.statusCode.toString());
    io:println();
    
    io:println("5. Adding components...");
    Component component1 = {
        componentId: "COMP-001",
        name: "Extruder Head"
    };
    
    http:Response|error compResponse = assetClient->post("/assets/EQ-001/components", component1);
    if compResponse is error {
        io:println("ERROR adding component: " + compResponse.message());
        return;
    }
    io:println("Added component: " + compResponse.statusCode.toString());
    io:println();
    
    io:println("6. Adding schedules...");
    MaintenanceSchedule schedule1 = {
        scheduleId: "SCH-001",
        nextDueDate: "2025-08-01", 
        description: "Quarterly maintenance"
    };
    http:Response|error schResponse = assetClient->post("/assets/EQ-001/schedules", schedule1);
    if schResponse is error {
        io:println("ERROR adding schedule: " + schResponse.message());
        return;
    }
    io:println("Added schedule: " + schResponse.statusCode.toString());
    io:println();
    
    io:println("7. Checking overdue assets:");
    Asset[]|error overdueAssets = assetClient->get("/assets/overdue");
    if overdueAssets is error {
        io:println("ERROR getting overdue assets: " + overdueAssets.message());
        return;
    }
    foreach Asset asset in overdueAssets {
        io:println("- Overdue: " + asset.assetTag + ": " + asset.name);
    }
    io:println();
    
    io:println("8. Creating work order...");
    WorkOrder workOrder1 = {
        workOrderId: "WO-001",
        description: "Fix printer issue",
        status: "OPEN",
        tasks: {}
    };
    http:Response|error woResponse = assetClient->post("/assets/EQ-001/workorders", workOrder1);
    if woResponse is error {
        io:println("ERROR creating work order: " + woResponse.message());
        return;
    }
    io:println("Created work order: " + woResponse.statusCode.toString());
    io:println();
    
    io:println("9. Adding task to work order...");
    Task task1 = {
        taskId: "TASK-001",
        description: "Replace extruder head"
    };
    http:Response|error taskResponse = assetClient->post("/assets/EQ-001/workorders/WO-001/tasks", task1);
    if taskResponse is error {
        io:println("ERROR adding task: " + taskResponse.message());
        return;
    }
    io:println("Added task: " + taskResponse.statusCode.toString());
    io:println();
    
    io:println("10. Final asset state:");
    Asset|error finalAsset = assetClient->get("/assets/EQ-001");
    if finalAsset is error {
        io:println("ERROR getting final asset: " + finalAsset.message());
        return;
    }
    io:println("Asset: " + finalAsset.assetTag + " - " + finalAsset.name);
    io:println("Status: " + finalAsset.status.toString());
    io:println("Components: " + finalAsset.components.length().toString());
    io:println("Schedules: " + finalAsset.schedules.length().toString());
    io:println("Work Orders: " + finalAsset.workOrders.length().toString());
    io:println();
    
    io:println("=== Demo completed! ===");
}
