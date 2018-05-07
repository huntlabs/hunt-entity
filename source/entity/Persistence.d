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

class Persistence
{
	private static EntityManagerFactory[string] _connections;

    public static EntityManagerFactory createEntityManagerFactory(string name, DatabaseOption option)
	{
		auto factory = new EntityManagerFactory(name, option);
		this._connections[name] = factory;

		return factory;
	}

    public static EntityManagerFactory getEntityManagerFactory(string name)
	{
		return this._connections[name];
	}
}
