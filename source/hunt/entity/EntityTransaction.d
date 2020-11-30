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

    private EntitySession _seesion;
    // private bool _isOnTrans;
    // private Transaction _tran;

    this(EntitySession entitySeesion) { 
        _seesion = entitySeesion;
    }
    
    void begin() {
        _seesion.beginTransaction();
    }

    void commit() {
        _seesion.commit();
    }

    void rollback() {
        _seesion.rollback();
    }
}