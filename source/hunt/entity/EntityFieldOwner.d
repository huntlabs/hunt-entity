module hunt.entity.EntityFieldOwner;


import hunt.entity;


class EntityFieldOwner : EntityFieldInfo {
    
    public this(string fileldName, string columnName, string tableName) {
        super(fileldName, columnName, tableName);
        _joinColumn = columnName;
    }

    override public string getSelectColumn() {
        return "";
    }

}


