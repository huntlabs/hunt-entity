module hunt.entity.EntityFieldOwner;


import hunt.entity;


class EntityFieldOwner : EntityFieldInfo {
    
    public this(string fieldName, string columnName, string tableName) {
        super(fieldName, columnName, tableName);
        _joinColumn = columnName;
    }

    override public string getSelectColumn() {
        return "";
    }
    
    override bool isAggregateType() {
        return true;
    }
}


