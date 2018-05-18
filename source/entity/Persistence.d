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
 
module entity.Persistence;

import entity;


import entity.EntityManagerFactory;

private EntityManagerFactory _defaultEntityManagerFactory;

@property EntityManagerFactory defaultEntityManagerFactory()
{
	if (null == _defaultEntityManagerFactory)
	{
		// error
		return null;
	}

	return _defaultEntityManagerFactory;
}

set setDefaultEntityManagerFactory(EntityManagerFactory factory)
{

}

class Persistence
{
	private static EntityManagerFactory[string] _factories;

    public static EntityManagerFactory createEntityManagerFactory(DatabaseOption option)
	{
		createEntityManagerFactory("default", option);
	}

    public static EntityManagerFactory createEntityManagerFactory(string name, DatabaseOption option)
	{
		auto factory = new EntityManagerFactory(name, option);
		this._factories[name] = factory;

		if ("default" == name)
		{
			setDefaultEntityManagerFactory(factory);
		}

		return factory;
	}

    public static EntityManagerFactory getEntityManagerFactory(string name)
	{
		return this._factories[name];
	}
}
