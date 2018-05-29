module entity.EntityFieldOwner;


import entity;


class EntityFieldOwner : EntityFieldInfo {
    
    public this(string fileldName, string columnName, Variant fieldValue, string tableName, EntityFieldType fieldType = EntityFieldType.DEFAULT) {
        super(fileldName, columnName, fieldValue, tableName, EntityFieldType.OWNER);
        _joinColumn = columnName;
    }

    override public string getSelectColumn() {
        return "";
    }

}


