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
 
module hunt.entity.DefaultEntityManagerFactory;

import hunt.entity.EntityManagerFactory;
import std.exception;

__gshared private EntityManagerFactory _defaultEntityManagerFactory;

@property string defaultEntityManagerFactoryName()
{
    return "default";
}

@property EntityManagerFactory defaultEntityManagerFactory()
{
	if (_defaultEntityManagerFactory is null)
	{
		// throw error
		throw new Exception("EntityManagerFactory is null");
		// return null;
	}

	return _defaultEntityManagerFactory;
}

void setDefaultEntityManagerFactory(EntityManagerFactory factory)
{
	_defaultEntityManagerFactory = factory;
}
