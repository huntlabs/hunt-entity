module entity.entitysession;

import entity;

class EntitySession
{
	EntityManager manager;
	Transaction tran;

	this(EntityManager manager)
	{
		this.manager = manager;
		this.tran = manager.db.beginTransaction();
	}
	
	int persist(Object obj)
	{
		auto info = manager.findEntityForObject(obj);
		return info.persistFunc(obj,info,manager,this);
	}

	Object find(Object obj)
	{
		auto info = manager.findEntityForObject(obj);
		return info.findFunc(obj,info,manager,this);
	}

	Object find(T,F)(F value)
	{
		auto t = new T();
		auto info = manager.findEntityForObject(t);
		info.setPriKeyFunc(t,Variant(value));
		if(find(t) is null)
			return null;
		return cast(T)t;
	}

	int remove(Object obj)
	{
		auto info = manager.findEntityForObject(obj);
		return info.removeFunc(obj,info,manager,this);
	}
	
	int remove(T,F)(F value)
	{
		auto t = new T();
		auto info = manager.findEntityForObject(t);
		info.setPriKeyFunc(t,Variant(value));
		return remove(t);
	}

	int merge(Object obj)
	{
		auto info = manager.findEntityForObject(obj);
		return info.mergeFunc(obj,info,manager,this);
	}

	int execute(string sql)
	{
        manager.entityLog(sql);
		return tran.execute(sql);	
	}
    
    int execute(T)(T t)
    {
        string str;
        static if(is(T == SqlSyntax))
            str = t.toString();
        else static if(is(T == SqlBuilder))
            str = t.build().toString();
        else static if(is(T == CriteriaBuilder))
            str = t.toString();
        else
            str = t;
        return execute(str);
    }
    

	void rollback()
	{
		this.tran.rollback();	
	}

	void commit()
	{
		this.tran.commit();
	}
} 
