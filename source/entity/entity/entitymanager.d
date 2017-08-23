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
	}
    
	QueryBuilder createQueryBuilder()
    {
        return new QueryBuilder(config,db,dialect);
    }
	
	CriteriaBuilder createCriteriaBuilder(T)()
	{
		return new CriteriaBuilder(config,db,dialect,this,T.stringof,entityList,classMap);
	}

	void persist(Object obj)
	{
		auto info = findEntityForObject(obj);
		info.persistFunc(obj,info,this);
	}

	void find(Object obj)
	{
		auto info = findEntityForObject(obj);
		info.findFunc(obj,info,this);
	}

	int remove(Object obj)
	{
		auto info = findEntityForObject(obj);
		return info.removeFunc(obj,info,this);
	}

	void merge(Object obj)
	{
		auto info = findEntityForObject(obj);
		info.mergeFunc(obj,info,this);
	}

	int execute(QueryBuilder builder)
	{
		return db.execute(builder.toString);	
	}
	int execute(string sql)
	{
		return db.execute(sql);	
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

	T[] getResultList(T)(QueryBuilder builder)
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
