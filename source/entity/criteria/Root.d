

module entity.criteria.Root;

import entity;

import std.traits;



class Root(T) {
    private EntityInfo!T _entityInfo;
    public this(Dialect dialect, T t = null) {
        _entityInfo = new EntityInfo!T(dialect, t);
    }

    public string getEntityClassName() {
        return _entityInfo.getEntityClassName();
    }
    public string getTableName() {
        return _entityInfo.getTableName();
    }
    public EntityInfo!T opDispatch(string name)() {
        if (getEntityClassName() != name)
            throw new EntityException("Cannot find entityinfo by name : " ~ name);	
        return _entityInfo;
    }
    public T deSerialize(Row row,ref long count) {
        return _entityInfo.deSerialize(row, count);
    }
    public EntityFieldInfo getPrimaryField() {
        return _entityInfo.getPrimaryField();
    }
    public EntityInfo!T getEntityInfo() {return _entityInfo;}

}
