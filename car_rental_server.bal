import ballerina/grpc;
import ballerina/io;
type FilterRequest record {
    string filter;
};
type PlateRequest record {
    string plate;
};
type ReservationRequest record {
    string customer_id;
};
map<Car> cars = {};
map<User> users = {};
CartItem[] cart = [];
int reservationCounter = 0;
function generateReservationId() returns string {
    reservationCounter += 1;
    return "RES" + reservationCounter.toString();
}
@grpc:ServiceDescriptor { descMap: getDescriptorMap()}
service "CarRental" on new grpc:Listener(9090) {

   remote function add_car(Car car) returns CarResponse|error {
        if cars.hasKey(car.plate) {
            return {success: false, message: "Car already exists", car_id: ""};
        }
        cars[car.plate] = car;
        io:println("Added car: " + car.plate);
        return {success: true, message: "Car added", car_id: car.plate};
    }
    remote function create_users(stream<User, grpc:Error?> userStream) returns SimpleResponse|error {
        int count = 0;
        error? result = userStream.forEach(function(User user) {
            users[user.id] = user;
            count += 1;
            io:println("Created user: " + user.name);
        });
        
        if result is error {
            return {success: false, message: "Error creating users"};
        }
        return {success: true, message: count.toString() + " users created"};
    }
    remote function update_car(Car car) returns SimpleResponse|error {
        if !cars.hasKey(car.plate) {
            return {success: false, message: "Car not found"};
        }
        cars[car.plate] = car;
        io:println("Updated car: " + car.plate);
        return {success: true, message: "Car updated"};
    }
    remote function remove_car(PlateRequest request) returns CarList|error {
        if cars.hasKey(request.plate) {
            _ = cars.remove(request.plate);
            io:println("Removed car: " + request.plate);
        }
        return {cars: cars.toArray()};
    }
    remote function list_available_cars(FilterRequest request) returns stream<Car, error?>|error {
        Car[] availableCars = [];
        foreach Car car in cars {
            if car.status == "AVAILABLE" {
                if request.filter == "" || 
                   car.make.includes(request.filter) || 
                   car.year.toString() == request.filter {
                    availableCars.push(car);
                }
            }
        }
        io:println("Listed " + availableCars.length().toString() + " cars");
        return availableCars.toStream();
    }
    remote function search_car(PlateRequest request) returns Car|error {
        if !cars.hasKey(request.plate) {
            return error grpc:NotFoundError("Car not found");
        }
        Car car = cars.get(request.plate);
        if car.status != "AVAILABLE" {
            return error grpc:FailedPreconditionError("Car not available");
        }
         return car;
    }
    remote function add_to_cart(CartItem item) returns SimpleResponse|error {
        if !cars.hasKey(item.plate) {
            return {success: false, message: "Car not found"};
        }
         Car car = cars.get(item.plate);
        if car.status != "AVAILABLE" {
            return {success: false, message: "Car not available"};
        }
        cart.push(item);
        io:println("Added to cart: " + item.plate);
        return {success: true, message: "Added to cart"};
    }
    remote function place_reservation(ReservationRequest request) returns ReservationResponse|error {
       
       CartItem[] customerItems = [];
        foreach CartItem item in cart {
            if item.customer_id == request.customer_id {
                customerItems.push(item);
            }
        }
         if customerItems.length() == 0 {
            return {
                success: false,
                message: "Cart is empty",
                reservation_id: "",
                total_price: 0.0
            };
        }
        float totalPrice = 0.0;
        foreach CartItem item in customerItems {
            Car car = cars.get(item.plate);
            totalPrice += car.daily_price * 3.0; 
        }
         string reservationId = generateReservationId();
        foreach CartItem item in customerItems {
            Car car = cars.get(item.plate);
            car.status = "UNAVAILABLE";
            cars[item.plate] = car;
            io:println("Reserved car: " + item.plate);
        }
         CartItem[] remainingCart = [];
        foreach CartItem item in cart {
            if item.customer_id != request.customer_id {
                remainingCart.push(item);
            }
        }
        cart = remainingCart;
        return {
            success: true,
            message: "Reservation confirmed",
            reservation_id: reservationId,
            total_price: totalPrice
        };
    }
}
function getDescriptorMap() returns map<anydata> {
    return {};
}
public function Rent() {
    io:println("Car Rental Server started on port 9090");
     cars["Sample"] = {
        plate: "N123-456W",
        make: "Toyota",
        model: "Hilux",
        year: 2023,
        daily_price: 5000.0,
        mileage: 10000.0,
        status: "AVAILABLE"
    };
     users["admin1"] = {id: "admin1", name: "Paul", role: "ADMIN"};
    users["customer1"] = {id: "customer1", name: "Luke", role: "CUSTOMER"};
    io:println("Server ready with sample data");
}
