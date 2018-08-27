

module hunt.entity.EntityFieldObject;

import hunt.entity;

class EntityFieldObject(T : Object, F : Object) : EntityFieldInfo {

    protected T _value;
    private F _owner;
    protected EntityInfo!(T,F) _entityInfo;
    protected EntityManager _manager;

    this (EntityManager manager,string fileldName, string columnName, string tableName, T fieldValue, F owner) {
        super(fileldName, columnName, tableName);
        _manager = manager;
        _value = fieldValue;
        _owner = owner;
        _entityInfo = new EntityInfo!(T,F)(_manager, fieldValue, owner);
    }   
}