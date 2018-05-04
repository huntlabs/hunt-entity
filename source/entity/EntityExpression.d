

module entity.EntityExpression;



class EntityExpression {

    private string _columnName;
    private string _columnSpecifier;
    private string _tableName;

    private string _fullColumn;
    private string _selectColumn;
    private string _columnAs;

    this(string columnName, string tableName) {
        _columnName = columnName;
        _tableName = tableName;
        _fullColumn = tableName ~ "." ~ columnName;
        _columnAs = tableName ~ "__as__" ~ columnName;
        _selectColumn = _fullColumn ~ " AS " ~ _columnAs;
    }

    public string getColumnName() {return _columnName;}
    public string getFullColumn() {return _fullColumn;}
    public string getColumnAs() {return _selectColumn;}
    public string getTableName() {return _tableName;}

    public string getSelectColumn() {
        return _fullColumn ~ " AS " ~ _columnAs;
    }

    //s: max min avg sum count
    public EntityExpression setColumnSpecifier(string s) {
        _fullColumn = s ~ "(" ~ _fullColumn ~ ")";
        if (s == "COUNT" || s == "count") {
            _columnAs = _tableName ~ "__as__count";
        }
        return this;
    }

    public EntityExpression setDistinct(bool b) {
        if (b)
            _fullColumn = "DISTINCT "~_fullColumn;
        return this;
    } 

}