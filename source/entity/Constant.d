

module entity.Constant;



//TableName
struct Table {
    string name;
}

//ColumnName
struct Column {
    string name;
}


enum {
    Auto = 0x1,
    AutoIncrement = 0x1,
    PrimaryKey = 0x2,
}


enum OrderBy {
    Asc = 0,
    Desc = 1,
}