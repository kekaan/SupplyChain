// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract SupplyChain {
    address public owner;
    
    struct Product {
        uint Id;
        string Name;
        uint Price;
    }

    struct Order{
        uint Id;
        uint ProductId;
        address Customer;
        string Location;
        string Destination;
        bool IsDelivered;
        bool IsDeliveryConfirmed;
    }

    mapping(uint => uint) private _productionStock;
    mapping(uint => Order) private _orders; 
    mapping(uint => Product) private _products;

    uint private _orderCount;
    uint private _productCount;
    string private constant _initialLocation = "Warehouse";
    
    event ProductAdded(uint indexed productId, string Name);
    event OrderPlaced(uint indexed productId, uint indexed orderId, address buyer);
    event ShipmentUpdated(uint indexed productId, string location);
    event ProductDelivered(uint indexed productId);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function addProduct(string memory Name, uint price) public onlyOwner {
        _productCount++;
        _products[_productCount] = Product(_productCount, Name, price);
        emit ProductAdded(_productCount, Name);
    }

    function updateProductionStock(uint productId, uint productCount) public onlyOwner {
        require(productId <= _productCount, "No such product");
        _productionStock[productId] = productCount;
    }
    
    function placeOrder(uint productId, string memory destination) public {
        require(productId <= _productCount, "Invalid product ID.");
        require(_productionStock[productId] > 0, "The product is out of stock");
        
        _productionStock[productId]--;
        _orderCount++;
        _orders[_orderCount] = Order(_orderCount, productId, msg.sender, _initialLocation, destination, false, false);

        emit OrderPlaced(productId, _orderCount, msg.sender);
    }
    
    function updateShipment(uint orderId, string memory location) public onlyOwner {
        require(orderId <= _orderCount, "Invalid order ID.");
        Order storage order = _orders[orderId];
        require(!order.IsDelivered, "Product has already been delivered.");
        
        order.Location = location;
        emit ShipmentUpdated(orderId, location);
    }
    
    function markDelivered(uint orderId) public onlyOwner {
        require(orderId <= _orderCount, "Invalid order ID.");
        Order storage order = _orders[orderId];
        require(!order.IsDelivered, "Product has already been delivered.");
        require(keccak256(bytes(order.Location)) == keccak256(bytes(order.Destination)), "The location of the order and the destination do not match");
        
        order.IsDelivered = true;
        emit ProductDelivered(orderId);
    }

    function confirmDelivery(uint orderId) public payable {
        require(orderId <= _orderCount, "Invalid order ID.");
        
        Order storage order = _orders[orderId];
        require(order.Customer == msg.sender, "It is not your order");

        Product storage product = _products[order.ProductId];
        require(msg.value == product.Price, "The transferred funds are not enough");

        order.IsDeliveryConfirmed = true;
    }
    
    function getAmountToPay(uint orderId) public view returns (uint)
    {
        require(orderId <= _orderCount, "Invalid order ID.");
        
        Order storage order = _orders[orderId];
        require(order.Customer == msg.sender, "It is not your order");

        Product storage product = _products[order.ProductId];
        return product.Price;
    }

    function get_products() public view returns (Product[] memory) {
        Product[] memory productList = new Product[](_productCount);
        for (uint i = 1; i <= _productCount; i++) {
            productList[i - 1] = _products[i];
        }
        return productList;
    }
}