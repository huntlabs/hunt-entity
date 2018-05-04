module entity.EntityFieldManyToMany;

import entity;


class EntityFieldManyToMany(T) : EntityFieldInfo {
    
    private ManyToMany _mode;
    private T _value;
    this(string fileldName, string columnName, string joinColumn, string tableName, T fieldValue, ManyToMany mode) {
        super(fileldName, /*tableName~"."~columnName*/columnName, Variant(fieldValue), tableName);
        _mode = mode;
        _joinColumn = joinColumn;
        _value = fieldValue;
    }

}