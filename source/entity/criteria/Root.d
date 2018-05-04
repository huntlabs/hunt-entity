

module entity.criteria.Root;

import entity;

import std.traits;





class Root(T) {
    private EntityInfo!T _entityInfo;
    private Dialect _dialect;
    JoinSqlBuild[] _joins;

    public this(Dialect dialect, T t = null) {
        _dialect = dialect;
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
    public EntityFieldInfo get(string field) {
        return _entityInfo.getSingleField(field);
    }
    public T deSerialize(Row row, ref long count) {
        return _entityInfo.deSerialize(row, count);
    }
    public EntityFieldInfo getPrimaryField() {
        return _entityInfo.getPrimaryField();
    }

    public EntityInfo!T getEntityInfo() {return _entityInfo;}

    public JoinSqlBuild[] getJoins() {return _joins;}

    public Join!(T,P) join(P)(EntityFieldInfo info, JoinType joinType = JoinType.INNER) {

        Join!(T,P) ret = new Join!(T,P)(_dialect, info, this, joinType);
        JoinSqlBuild data;
        data.tableName = ret.getTableName();
        data.joinWhere = ret.getJoinOnString();
        data.joinType = joinType;
        data.columnNames = ret.getAllSelectColumn();
        _joins ~= data;

        return ret;
    }
    
    public string[] getAllSelectColumn() {
        string[] ret;
        foreach(value; _entityInfo.getFields()) {
            if (cast(EntityFieldNormal)value)
                ret ~= value.getSelectColumn();
        }
        return ret;
    }


}
