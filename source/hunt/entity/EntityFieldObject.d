

module hunt.entity.EntityFieldObject;

import hunt.entity;

interface IEntityFieldObject {
    LazyData getLazyData(Row row);

    FetchType fetchType();
}


class EntityFieldObject(T : Object, F : Object) : EntityFieldInfo, IEntityFieldObject {

    protected T _value;
    protected F _owner;
    protected EntityInfo!(T,F) _entityInfo;
    protected EntityManager _manager;

    this (EntityManager manager,string fieldName, string columnName, string tableName, T fieldValue, F owner) {
        super(fieldName, columnName, tableName);
        _manager = manager;
        _value = fieldValue;
        _owner = owner;
        _entityInfo = new EntityInfo!(T,F)(_manager, fieldValue, owner);
        _typeInfo = typeid(T);
    }   

    override bool isAggregateType() {
        return true;
    }
    
    FetchType fetchType() {
        return FetchType.LAZY;
    }

    LazyData getLazyData(Row row) {
        return null;
    }
}