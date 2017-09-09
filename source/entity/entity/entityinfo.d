module entity.entity.entityinfo;

import entity;

class EntityInfo
{
	string name;
	string tableName;
	FieldInfo[string] fields;
	string[] fieldsColumn;
	string primaryKey;

    alias int function(Object,EntityInfo,EntityManager) PersistFunc;
    alias int function(Object,EntityInfo,EntityManager) RemoveFunc;
    alias int function(Object,EntityInfo,EntityManager) MergeFunc;
    alias Object function(Object,EntityInfo,EntityManager) FindFunc;
    alias Object function(Object,Variant) SetPriKeyFunc;

    PersistFunc persistFunc;
    RemoveFunc removeFunc;
    MergeFunc mergeFunc;
    FindFunc findFunc;
	SetPriKeyFunc setPriKeyFunc;

	this(string name,string tableName,string primaryKey,FieldInfo[string] fields,
     PersistFunc persist,RemoveFunc remove,MergeFunc merge,FindFunc find,SetPriKeyFunc setPriKey)
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

	void setPrimaryKey(Object obj,T value)
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
