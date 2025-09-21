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
map<Asset> assetDatabase = {};
public function main() returns error? {
    io:println("Asset Management Service started on http://localhost:9090");
    io:println("Try: curl http://localhost:9090/assets");
}
service /assets on new http:Listener(9090) {
    resource function post .(@http:Payload Asset asset) returns http:Created|http:Conflict {
        if assetDatabase.hasKey(asset.assetTag) { 
            return http:CONFLICT; 
        }
        assetDatabase[asset.assetTag] = asset;
        return http:CREATED;
    }
    resource function get .() returns Asset[] {
        Asset[] result = [];
        foreach Asset a in assetDatabase {
            result.push(a);
        }
        return result;
    }
    resource function get [string assetTag]() returns Asset|http:NotFound {
        if assetDatabase.hasKey(assetTag) {
            return assetDatabase.get(assetTag);
        }
        return http:NOT_FOUND;
    }
    resource function put [string assetTag](@http:Payload Asset asset) returns http:Ok|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        assetDatabase[assetTag] = asset;
        return http:OK;
    }
    resource function delete [string assetTag]() returns http:Ok|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        _ = assetDatabase.remove(assetTag);
        return http:OK;
    }
    resource function get faculty/[string facultyName]() returns Asset[] {
        Asset[] result = [];
        foreach Asset a in assetDatabase {
            if a.faculty == facultyName { 
                result.push(a); 
            }
        }
        return result;
    }
    resource function get overdue() returns Asset[] {
        Asset[] result = [];
        string today = "2025-09-21";
        foreach Asset a in assetDatabase {
            foreach MaintenanceSchedule s in a.schedules {
                if s.nextDueDate < today { 
                    result.push(a); 
                    break; 
                }
            }
        }
        return result;
    }
    resource function post [string assetTag]/components(@http:Payload Component component) returns http:Created|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        currentAsset.components[component.componentId] = component;
        return http:CREATED;
    }
    resource function delete [string assetTag]/components/[string componentId]() returns http:Ok|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        if !currentAsset.components.hasKey(componentId) { 
            return http:NOT_FOUND; 
        }
        _ = currentAsset.components.remove(componentId);
        return http:OK;
    }
    resource function post [string assetTag]/schedules(@http:Payload MaintenanceSchedule schedule) returns http:Created|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        currentAsset.schedules[schedule.scheduleId] = schedule;
        return http:CREATED;
    }
    resource function delete [string assetTag]/schedules/[string scheduleId]() returns http:Ok|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        if !currentAsset.schedules.hasKey(scheduleId) { 
            return http:NOT_FOUND; 
        }
        _ = currentAsset.schedules.remove(scheduleId);
        return http:OK;
    }
    resource function post [string assetTag]/workorders(@http:Payload WorkOrder workOrder) returns http:Created|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        currentAsset.workOrders[workOrder.workOrderId] = workOrder;
        return http:CREATED;
    }
    resource function put [string assetTag]/workorders/[string workOrderId](@http:Payload WorkOrder workOrder) returns http:Ok|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        if !currentAsset.workOrders.hasKey(workOrderId) { 
            return http:NOT_FOUND; 
        }
        currentAsset.workOrders[workOrderId] = workOrder;
        return http:OK;
    }
    resource function post [string assetTag]/workorders/[string workOrderId]/tasks(@http:Payload Task task) returns http:Created|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        if !currentAsset.workOrders.hasKey(workOrderId) { 
            return http:NOT_FOUND; 
        }
        WorkOrder currentWorkOrder = currentAsset.workOrders.get(workOrderId);
        currentWorkOrder.tasks[task.taskId] = task;
        return http:CREATED;
    }
    resource function delete [string assetTag]/workorders/[string workOrderId]/tasks/[string taskId]() returns http:Ok|http:NotFound {
        if !assetDatabase.hasKey(assetTag) { 
            return http:NOT_FOUND; 
        }
        Asset currentAsset = assetDatabase.get(assetTag);
        if !currentAsset.workOrders.hasKey(workOrderId) { 
            return http:NOT_FOUND; 
        }
        WorkOrder currentWorkOrder = currentAsset.workOrders.get(workOrderId);
        if !currentWorkOrder.tasks.hasKey(taskId) { 
            return http:NOT_FOUND; 
        }
        _ = currentWorkOrder.tasks.remove(taskId);
        return http:OK;
    }
}
