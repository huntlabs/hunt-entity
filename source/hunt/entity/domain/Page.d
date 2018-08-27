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

module hunt.entity.domain.Page;

import hunt.entity.domain.Pageable;
import hunt.entity.domain.Sort;

class Page(T)
{
	T[] 		_content;
	Pageable	_pageable;
	long		_total;


	this(T []content , 
		Pageable pageable , 
		long total)
	{
		_content = content;
		_pageable = pageable;
		_total = total;
	}

	int getNumber()
	{
		return _pageable.getPageNumber();
	}
	
	int getSize()             
	{
		return _pageable.getPageSize();
	}

	int getTotalPages()
	{
		return cast(int)(_total / getSize() + (_total % getSize() == 0 ? 0 : 1));
	}
	
	int getNumberOfElements()
	{
		return cast(int)_content.length;
	}
	
	long getTotalElements()
	{
		return _total;
	}
	
	bool hasPreviousPage()
	{
		return getNumber() > 0;
	}
	
	bool isFirstPage()
	{
		return getNumber() == 0;
	}
	
	bool hasNextPage()
	{
		return getNumber() < getTotalPages() - 1;
	}
	
	bool isLastPage()
	{
		return getNumber() == getTotalPages() - 1;
	}

	T[] getContent()
	{
		return _content;
	}
	
	bool hasContent()
	{
		return _content.length > 0 ;
	}
	
	Sort getSort()
	{
		return _pageable.getSort();
	}
}