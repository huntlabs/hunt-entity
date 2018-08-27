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
 
module hunt.entity.EntityTransaction;

import hunt.entity;

class EntityTransaction {
    

    private EntityManager _entityManager;
    private bool _isOnTrans;
    private Transaction _tran;

    this(EntityManager entityManager) { 
        _entityManager = entityManager;
    }
    
    public void begin() {
        _entityManager.getSession().beginTransaction();
    }

    public void commit() {
        _entityManager.getSession().commit();
    }

    public void rollback() {
        _entityManager.getSession().rollback();
    }
}