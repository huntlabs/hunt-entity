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

import entity.DefaultEntityManagerFactory;


class Persistence
{
	private static string DEFAULT_NAME = "default";

	private static EntityManagerFactory[string] _factories;

    public static EntityManagerFactory createEntityManagerFactory(DatabaseOption option, string tablePrefix = "")
	{
		return createEntityManagerFactory(DEFAULT_NAME, option, tablePrefix);
	}

    public static EntityManagerFactory createEntityManagerFactory(string name, DatabaseOption option, string tablePrefix = "")
	{
		if (name in _factories)
			return _factories[name];
		
		auto factory = new EntityManagerFactory(name, option, tablePrefix);
		this._factories[name] = factory;
		if (DEFAULT_NAME == name)
		{
			setDefaultEntityManagerFactory(factory);
		}
		return factory;
	}

    public static EntityManagerFactory getEntityManagerFactory(string name = DEFAULT_NAME)
	{
		return this._factories[name];
	}
}
