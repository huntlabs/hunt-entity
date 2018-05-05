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
 
module entity.repository.CrudRepository;

public import entity.repository.Repository;

abstract class CrudRepository(T, ID) : Repository!(T, ID)
{
    public long count()
    {
        return 0;
    }

    public void remove()
    {
    }

    public void deleteAll()
    {
    }
    
    public void deleteAll(T[] entities)
    {
    }

    public void deleteById(ID id)
    {
    }
    
    public bool existsById(ID id)
    {
    }

    public T[] findAll()
    {
        return [];
    }

    public T[] findAllById(ID[] ids)
    {
        return [];
    }

    public T findById(ID id)
    {
        return null;
    }

    public T save(T entity)
    {
        return null;
    }

    public T[] saveAll(T[] entities)
    {
        return [];
    }
}
