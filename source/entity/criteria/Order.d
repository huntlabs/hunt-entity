
module entity.criteria.Order;

import entity;

class Order {

    private OrderBy _by;
    private string _column;

    private enum string[OrderBy] OrderMap = [
        OrderBy.ASC : "ASC", 
        OrderBy.DESC : "DESC",
    ];

    this(string column, OrderBy by) {
        _column = column;
        _by = by;
    }

    public Order reverse() {
        if (_by == OrderBy.ASC) 
            _by = OrderBy.DESC;
        else 
            _by = OrderBy.ASC;
        return this;
    }

    public string getColumn() {return _column;}

    public string getOrderType() {
        return OrderMap[_by];
    }

}