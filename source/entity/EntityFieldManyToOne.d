
module entity.EntityFieldManyToOne;

import entity;

class EntityFieldManyToOne(T) : EntityFieldInfo {
    
    private ManyToOne _mode;
    private T _value;
    private EntityInfo!T _entityInfo;

    // private Root!T _root;
    this( string fileldName, string columnName, string tableName, T fieldValue, ManyToOne mode) {
        super(fileldName, columnName, Variant(fieldValue), tableName);
        _mode = mode;
        _joinColumn = columnName;
        _value = fieldValue;
        // _root = new 
    }

    public void deSerialize(Dialect dialect, Row row, ref T ret) {
        if (_entityInfo is null)
            _entityInfo = new EntityInfo!T(dialect);

        long count;
        ret = _entityInfo.deSerialize(row, count);
    }
}