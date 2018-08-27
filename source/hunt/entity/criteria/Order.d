/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.entity.criteria.Order;

import hunt.entity;

class Order
{
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
