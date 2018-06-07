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
 
module entity.repository.EntityRepository;

import entity;
import entity.repository.CrudRepository;

public import entity.domain;

class EntityRepository (T, ID) : CrudRepository!(T, ID)
{
	static string tableName()
	{
		return getUDAs!(getSymbolsByUDA!(T, Table)[0], Table)[0].name;
	}

	static string initObjects()
	{
		return `		auto em = this.createEntityManager();
		CriteriaBuilder builder = em.getCriteriaBuilder();	
		auto criteriaQuery = builder.createQuery!T;
		Root!T root = criteriaQuery.from();`;
	}

	alias count =  CrudRepository!(T, ID).count;
	alias findAll = CrudRepository!(T, ID).findAll;

	long count(Specification!T specification)
	{
		mixin(initObjects);

		criteriaQuery.select(builder.count(root)).where(specification.toPredicate(
				root , criteriaQuery , builder));
		
		Long result = cast(Long)(em.createQuery(criteriaQuery).getSingleResult());

		em.close();

		return result.longValue();
	}

	T find(ID id)
	{
		return this.findById(id);
	}

	T[] findAll(Sort sort)
	{
		mixin(initObjects);

		//sort
		foreach(o ; sort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~ "." ~ o.getColumn() , o.getOrderType());

		//all
		criteriaQuery.select(root);

		TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
		auto res = typedQuery.getResultList();
		em.close();
		return res;
	}

	T[] findAll(Specification!T specification)
	{
		mixin(initObjects);

		//specification
		criteriaQuery.select(root).where(specification.toPredicate(
				root , criteriaQuery , builder));

		TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
		auto res = typedQuery.getResultList();
		em.close();
		return res;
	}

	T[] findAll(Specification!T specification , Sort sort)
	{
		mixin(initObjects);

		//sort
		foreach(o ; sort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~ "." ~ o.getColumn() , o.getOrderType());

		//specification
		criteriaQuery.select(root).where(specification.toPredicate(
				root , criteriaQuery , builder));

		TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
		auto res = typedQuery.getResultList();
		em.close();
		return res;
	}


	Page!T findAll(Pageable pageable)
	{
		mixin(initObjects);

		//sort
		foreach(o ; pageable.getSort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~ "." ~ o.getColumn() , o.getOrderType());

		//all
		criteriaQuery.select(root);

		//page
		TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
				.setMaxResults(pageable.getPageSize());
		auto res = typedQuery.getResultList();
		auto page = new Page!T(res , pageable , super.count());
		em.close();
		return page;
	}

	Page!T findAll(Specification!T specification, Pageable pageable)
	{
		mixin(initObjects);

		//sort
		foreach(o ; pageable.getSort.list)
			criteriaQuery.getSqlBuilder().orderBy(tableName ~"." ~ o.getColumn() , o.getOrderType());

		//specification
		criteriaQuery.select(root).where(specification.toPredicate(
				root , criteriaQuery , builder));
				
		//page
		TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
			.setMaxResults(pageable.getPageSize());
		auto res = typedQuery.getResultList();
		auto page = new Page!T(res , pageable , count(specification));

		em.close();

		return page;
	}
}

