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

module hunt.entity.domain.Pageable;

import hunt.entity.domain.Sort;

class Pageable
{
	int 	_page;
	int 	_size;
	Sort 	_sort;

	this(int page , int size)
	{
		this(page , size , new Sort());
	}

	this(int page , int size , string column , OrderBy by )
	{
		this(page , size , new Sort(column , by));
	}

	this(int page , int size , Sort sort)
	{
		_page = page;
		_size = size;
		_sort = sort;
	}

	int getPageNumber() 
	{
		return _page;
	}  

	int getPageSize()
	{
		return _size;
	}

	int getOffset()
	{
		return _page * _size;
	}

	Sort getSort()
	{
		return _sort;
	}
}
