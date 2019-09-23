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

module hunt.entity.Persistence;

import hunt.entity;

import hunt.entity.DefaultEntityManagerFactory;
import hunt.entity.EntityOption;

private __gshared EntityManagerFactory[string] _factories;

class Persistence
{

    public static EntityManagerFactory createEntityManagerFactory(EntityOption option)
	{
		return createEntityManagerFactory(defaultEntityManagerFactoryName(), option);
	}

    public static EntityManagerFactory createEntityManagerFactory(string name, EntityOption option)
	{
		if (name in _factories)
			return _factories[name];
		
		auto factory = new EntityManagerFactory(name, option);
		_factories[name] = factory;
		if (defaultEntityManagerFactoryName() == name)
		{
			setDefaultEntityManagerFactory(factory);
		}
		return factory;
	}

    public static EntityManagerFactory getEntityManagerFactory(string name = defaultEntityManagerFactoryName())
	{
		return _factories[name];
	}
}
