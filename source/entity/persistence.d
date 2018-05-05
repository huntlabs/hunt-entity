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

class Persistence {
    public static EntityManagerFactory createEntityManagerFactory(string name, DatabaseConfig config) {
		return new EntityManagerFactory(name,config);
	}
}