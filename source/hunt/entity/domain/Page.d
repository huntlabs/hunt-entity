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

	struct PageModel
	{
		int previous;
		int current;
		int next;
		int[] pages;
		int size;
		long totalElements;
		int totalPages;
	}

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

	PageModel getModel(int num = 5)
	{
		if(num < 2)
		{
			num = 3;
		}
		if(num%2 == 0)
		{
			num++;
		}
		PageModel pm;

		pm.current = this.getNumber() + 1;
		if (this.hasNextPage())
		{
			pm.next = pm.current + 1;
		}

		if (this.hasPreviousPage())
		{
			pm.previous = pm.current - 1;
		}

		pm.size = this.getSize();
		pm.totalPages = this.getTotalPages();
		if(pm.totalPages < pm.current)
		{
			pm.current = pm.totalPages;
		}
		pm.totalElements = this.getTotalElements();

		if(pm.totalPages <= (num*2+1))
		{
			for(int i = 1; i <= pm.totalPages; i++)
			{
				pm.pages ~= i;
			}
		}else{
			int half = cast(int)(num/2);
			int[] pages;
			int[] firsts;
			int[] lefts;
			int[] rights;
			int[] lasts;
			if(pm.current - num >= half)
			{
				for(int i = 1; i <= half; i++)
				{
					firsts ~= i;
				}
				if(firsts.length > 0)
				{
					firsts ~= 0;
				}
			}

			for(int i = pm.current - (num - cast(int)firsts.length); i < pm.current; i++)
			{
				if(i > 0)
				{
					lefts ~= i;
				}
			}

			if(pm.current + num < pm.totalPages)
			{
				lasts ~= 0;
				for(int i = (pm.totalPages - half) + 1; i <= pm.totalPages; i++)
				{
					lasts ~= i;
				}
			}

			for(int i = pm.current + 1; i <= pm.current + (num - cast(int)lasts.length); i++)
			{
				if(i <= pm.totalPages)
				{
					rights ~= i;
				}
			}
			if(pm.current <= half)
			{
				rights = [];
				for(int i = pm.current + 1; i <= num; i++)
				{
					rights ~= i;
				}
			}
			if(pm.totalPages - pm.current <= half)
			{
				lefts = [];
				for(int i = pm.totalPages - num + 1; i < pm.current; i++)
				{
					lefts ~= i;
				}
			}
			pm.pages ~= firsts;
			pm.pages ~= lefts;
			pm.pages ~= pm.current;
			pm.pages ~= rights;
			pm.pages ~= lasts;
		}
		return pm;
	}
}