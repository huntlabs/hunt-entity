module entity.entitymanager;

import entity;

class EntityManager
{
	string name;
	DatabaseConfig config;
	Database db;
	Dialect dialect;
	EntityInfo[string] entityList;
	EntityInfo[TypeInfo_Class] classMap;
    SqlFactory sqlFactory;

    bool logStatus = true;
	bool CacheStatus = true;


	this(string name,DatabaseConfig config,Database db,Dialect dialect,
			EntityInfo[string] entityList,
			EntityInfo[TypeInfo_Class] classMap)
	{
		this.name = name;
		this.config = config;
		this.dialect = dialect; 
		this.db = db;
		this.entityList = entityList;
		this.classMap = classMap;
        sqlFactory = new SqlFactory();
	}
    

    EntitySession createEntityTransaction()
    {
        return new EntitySession(this);
    }

	SqlBuilder createSqlBuilder()
    {
        version(USE_MYSQL){
            return sqlFactory.createMySqlBuilder();
        }
        version(USE_POSTGRESQL){
            return sqlFactory.createPostgresqlSqlBuilder();
        }
        version(USE_SQLITE){
            return sqlFactory.createSqliteBuilder();
        }
    }
	
	CriteriaBuilder createCriteriaBuilder(T)()
	{
		return new CriteriaBuilder(config,db,dialect,this,T.stringof,entityList,classMap);
	}

	int persist(Object obj)
	{
		auto info = findEntityForObject(obj);
		auto session = createEntityTransaction();
        int result = info.persistFunc(obj,info,this,session);
        session.commit();
        return result;
	}

	Object find(Object obj)
	{
		auto info = findEntityForObject(obj);
		auto session = createEntityTransaction();
		auto result = info.findFunc(obj,info,this,session);
        session.commit();
        return result;
	}

	Object find(T,F)(F value)
	{
		auto t = new T();
		auto info = findEntityForObject(t);
		info.setPriKeyFunc(t,Variant(value));
		if(find(t) is null)
			return null;
		return cast(T)t;
	}
	
	Object copy(Object obj)
	{
		auto info = findEntityForObject(obj);
		info.copyFunc(obj);
		return info;
	}

	string[] compare(Object objold,Object objnew)
	{
		auto info = findEntityForObject(objold);
		return info.compareFunc(objold,objnew);
	}


	int remove(Object obj)
	{
		auto info = findEntityForObject(obj);
		auto session = createEntityTransaction();
		int result = info.removeFunc(obj,info,this,session);
        session.commit();
        return result;
	}
	
	int remove(T,F)(F value)
	{
		auto t = new T();
		auto info = findEntityForObject(t);
		info.setPriKeyFunc(t,Variant(value));
		return remove(t);
	}

	int merge(Object obj)
	{
		auto info = findEntityForObject(obj);
		auto session = createEntityTransaction();
		int result = info.mergeFunc(obj,info,this,session);
        session.commit();
        return result;
	}

    int execute(SqlSyntax syntax)
    {
        entityLog(syntax.toString); 
		return execute(syntax.toString);	
    }
	int execute(SqlBuilder builder)
	{
        entityLog(builder.build().toString); 
		return execute(builder.build().toString);	
	}
	int execute(CriteriaBuilder builder)
	{
        entityLog(builder.toString);
		return execute(builder.toString);	
	}
	int execute(string sql)
	{
        entityLog(sql);
		return db.execute(sql);	
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

	T getResult(T,F)(F cb)
	{
        string sql;
        static if(is(F == CriteriaBuilder))
            sql = cb.toString;
        else
            sql = cb;
        entityLog(sql);
		auto stmt = db.prepare(sql);
		auto res = stmt.query();
        if(!res.empty()){
            auto r = res.front();
            auto result = new T();
            auto entity = findEntityForObject(result);
            foreach(field;entity.fields){
                field.fieldValue = Variant(r[field.fieldName]);
                field.write(result);
            }
            return this.copy(result);
        }
		return null;
	}

	T[] getResultList(T,F)(F ct)
	{
		T[] result;
        string sql;
        static if (is(F == SqlBuilder))
            sql = ct.build.toString;
        else static if (is(F == string))
            sql = ct;
        else
            sql = ct.toString;
        entityLog(sql);
		auto stmt = db.prepare(sql);
		auto res = stmt.query();
		foreach(r;res){
			auto t = new T();
			auto entity = findEntityForObject(t);
			foreach(field;entity.fields){
				field.fieldValue = Variant(r[field.fieldName]);
				field.write(t);
			}
			result ~= this.copy(t);
		}
		return result;
	}

	EntityInfo findEntityForObject(Object obj)
	{
		if(!(obj.classinfo in classMap))
			throw new EntityException("Cannot find entity by class " ~ obj.classinfo.toString());	
		return classMap[obj.classinfo];
	}

    void enableLog()
    {
        this.logStatus = true;
    }

    void disableLog()
    {
        this.logStatus = false;
    }
    
	void enableCache()
    {
        this.CacheStatus = true;
    }

    void disableCache()
    {
        this.CacheStatus = false;
    }

    void entityLog(T)(T value,string file = __FILE__, size_t line = __LINE__)
    {
        if(this.logStatus)log(file,":",line," ",value); 
    }
    
    EntityInfo opDispatch(string name)() 
    {
        return entityList.get(name,null);
    }
    EntityInfo opIndex(string name) 
    {
        return entityList.get(name,null);
    }
}
