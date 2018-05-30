

module entity.EntityFieldObject;

import entity;

class EntityFieldObject(T : Object, F : Object) : EntityFieldInfo {

    protected T _value;
    protected EntityInfo!(T,F) _entityInfo;
    protected CriteriaBuilder _builder;
    private F _owner;



    this (CriteriaBuilder builder, string fileldName, string columnName, string tableName, T fieldValue, F owner, EntityFieldType fieldType) {
        super(fileldName, columnName, Variant(fieldValue), tableName, fieldType);
        _value = fieldValue;
        _builder = builder;
        _owner = owner;
        _entityInfo = new EntityInfo!(T,F)(builder, null, owner);
    }   

    public CriteriaBuilder getBuilder() {return _builder;}


    // public void setPrimaryValue(string value) {
    //     _entityInfo.setPrimaryValue(value);
    // }
 

 

}