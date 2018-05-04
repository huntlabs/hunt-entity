module entity.EntityFieldOneToMany;

import entity;


class EntityFieldOneToMany(T) : EntityFieldInfo {
    
    private OneToMany _mode;
    private T _value; 
    this(string fileldName, string columnName, string joinColumn, string tableName, T fieldValue, OneToMany mode) {
        super(fileldName, columnName, Variant(fieldValue), tableName);
        _mode = mode;
        _joinColumn = joinColumn;
        _value = fieldValue;
    }
    

}