
module entity.criteria.Order;

import entity;

class Order {

    private OrderBy _by;
    private string _colume;

    private enum string[OrderBy] OrderMap = [
        OrderBy.Asc : "ASC", 
        OrderBy.Desc : "DESC",
    ];

    this(string colume, OrderBy by) {
        _colume = colume;
        _by = by;
    }

    public Order reverse() {
        if (_by == OrderBy.Asc) 
            _by = OrderBy.Desc;
        else 
            _by = OrderBy.Asc;
        return this;
    }

    public string getColume() {return _colume;}

    public string getOrderType() {
        return OrderMap[_by];
    }

}