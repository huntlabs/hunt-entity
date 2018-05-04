module entity.EntityFieldOneToOne;

import entity;


class EntityFieldOneToOne(T) : EntityFieldInfo {
    
    private OneToOne _mode;
    this(string fileldName, string columnName, string joinColumn, string tableName, T fieldValue, OneToOne mode) {
        super(fileldName, columnName, Variant(fieldValue), tableName);
        _mode = mode;
        _joinColumn = joinColumn;
        _value = fieldValue;
    }


}