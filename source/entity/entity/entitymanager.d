module entity.entity.entitymanager;

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
    
	SqlBuilder createSqlBuilder()
    {
        version(USE_MYSQL){
            return sqlFactory.createMySqlBuilder();
        }
        version(USE_POSTGRESQL){
            return sqlFactory.createPgSqlBuilder();
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
		return info.persistFunc(obj,info,this);
	}

	Object find(Object obj)
	{
		auto info = findEntityForObject(obj);
		return info.findFunc(obj,info,this);
	}

	int remove(Object obj)
	{
		auto info = findEntityForObject(obj);
		return info.removeFunc(obj,info,this);
	}

	int merge(Object obj)
	{
		auto info = findEntityForObject(obj);
		return info.mergeFunc(obj,info,this);
	}

    int execute(SqlSyntax syntax)
    {
		return execute(syntax.toString);	
    }
	int execute(SqlBuilder builder)
	{
		return execute(builder.build().toString);	
	}
	int execute(CriteriaBuilder builder)
	{
		return execute(builder.toString);	
	}
	int execute(string sql)
	{
		return db.execute(sql);	
	}
    
	T getResult(T)(string sql)
	{
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
            return result;
        }
		return null;
	}

	T[] getResultList(T)(string sql)
	{
		T[] result;
		auto stmt = db.prepare(sql);
		auto res = stmt.query();
		foreach(r;res){
			auto t = new T();
			auto entity = findEntityForObject(t);
			foreach(field;entity.fields){
				field.fieldValue = Variant(r[field.fieldName]);
				field.write(t);
			}
			result ~= t;
		}
		return result;
	}

	T[] getResultList(T)(SqlBuilder builder)
	{
		T[] result;
		auto stmt = db.prepare(builder.build.toString);
		auto res = stmt.query();
		foreach(r;res){
			auto t = new T();
			auto entity = findEntityForObject(t);
			foreach(field;entity.fields){
				field.fieldValue = Variant(r[field.fieldName]);
				field.write(t);
			}
			result ~= t;
		}
		return result;
	}
	T[] getResultList(T)(SqlSyntax syntax)
	{
		T[] result;
		auto stmt = db.prepare(syntax.toString);
		auto res = stmt.query();
		foreach(r;res){
			auto t = new T();
			auto entity = findEntityForObject(t);
			foreach(field;entity.fields){
				field.fieldValue = Variant(r[field.fieldName]);
				field.write(t);
			}
			result ~= t;
		}
		return result;
	}
	T[] getResultList(T)(CriteriaBuilder builder)
	{
		T[] result;
		auto stmt = db.prepare(builder.toString);
		auto res = stmt.query();
		foreach(r;res){
			auto t = new T();
			auto entity = findEntityForObject(t);
			foreach(field;entity.fields){
				field.fieldValue = Variant(r[field.fieldName]);
				field.write(t);
			}
			result ~= t;
		}
		return result;
	}

	EntityInfo findEntityForObject(Object obj)
	{
		if(!(obj.classinfo in classMap))
			throw new EntityException("Cannot find entity by class " ~ obj.classinfo.toString());	
		return classMap[obj.classinfo];
	}
}
