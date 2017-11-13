module entity.entity.entityinfo;

import entity;

class EntityInfo
{
	string name;
	string tableName;
	FieldInfo[string] fields;
	string[] fieldsColumn;
	string primaryKey;

    alias int function(Object,EntityInfo,EntityManager,EntitySession) PersistFunc;
    alias int function(Object,EntityInfo,EntityManager,EntitySession) RemoveFunc;
    alias int function(Object,EntityInfo,EntityManager,EntitySession) MergeFunc;
    alias Object function(Object,EntityInfo,EntityManager,EntitySession) FindFunc;
    alias Object function(Object,Variant) SetPriKeyFunc;
    alias Variant function(Object) ReadPriKeyValueFunc;

    PersistFunc persistFunc;
    RemoveFunc removeFunc;
    MergeFunc mergeFunc;
    FindFunc findFunc;
	SetPriKeyFunc setPriKeyFunc;
	ReadPriKeyValueFunc readPriKeyValueFunc;

	this(string name,string tableName,string primaryKey,FieldInfo[string] fields,
     PersistFunc persist,RemoveFunc remove,MergeFunc merge,FindFunc find,SetPriKeyFunc setPriKey,
	 ReadPriKeyValueFunc readPriKeyValue)
	{
		this.name = name;
		this.tableName = tableName;
		this.primaryKey = primaryKey;
		this.fields = fields;

        this.persistFunc = persist;
        this.removeFunc = remove;
        this.mergeFunc = merge;
        this.findFunc = find;
		this.setPriKeyFunc = setPriKey;
		this.readPriKeyValueFunc = readPriKeyValue;
	}

	string[] getAllFields()
	{
		if(!fieldsColumn.length){
			foreach(k,v;fields){
				fieldsColumn ~= k;
			}
		}
		return fieldsColumn;
	}

	string getPrimaryKey()
	{
		return primaryKey;
	}

	T getPrimaryKeyValue(T)(Object obj)
	{
		return cast(T)*readPriKeyValueFunc(obj).peek!T;	
	}

	void setPrimaryKey(T)(Object obj,T value)
	{
		setPriKeyFunc(obj,Variant(value));
	}

    FieldInfo opDispatch(string name)() 
    {
        return fields.get(name,null);
    }
    FieldInfo opIndex(string name) 
    {
        return fields.get(name,null);
    }
}
