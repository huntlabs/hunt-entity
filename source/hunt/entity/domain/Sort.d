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

module hunt.entity.domain.Sort;

import hunt.entity;
import std.traits;

public import hunt.entity.Constant;

class Sort
{
	Order[] _lst;

	this()
	{

	}

	this(string column ,  OrderBy order)
	{
		_lst ~= new Order(column , order);
	}

	Sort add( Order order)
	{
		_lst ~= order;
		return this;
	}

	Order[] list()
	{
		return _lst;
	}
}
