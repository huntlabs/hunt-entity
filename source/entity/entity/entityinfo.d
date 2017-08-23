module entity.entity.entityinfo;

import entity;

class EntityInfo
{
	string name;
	string tableName;
	FieldInfo[string] fields;
	string[] fieldsColumn;

    alias Object function(Object,EntityInfo,EntityManager) PersistFunc;
    alias int function(Object,EntityInfo,EntityManager) RemoveFunc;
    alias Object function(Object,EntityInfo,EntityManager) MergeFunc;
    alias Object function(Object,EntityInfo,EntityManager) FindFunc;

    PersistFunc persistFunc;
    RemoveFunc removeFunc;
    MergeFunc mergeFunc;
    FindFunc findFunc;

	this(string name,string tableName,FieldInfo[string] fields,
     PersistFunc persist,RemoveFunc remove,MergeFunc merge,FindFunc find)
	{
		this.name = name;
		this.tableName = tableName;
		this.fields = fields;

        this.persistFunc = persist;
        this.removeFunc = remove;
        this.mergeFunc = merge;
        this.findFunc = find;
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

    FieldInfo opDispatch(string name)() 
    {
        return fields.get(name,null);
    }
    FieldInfo opIndex(string name) 
    {
        return fields.get(name,null);
    }
}
