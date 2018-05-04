


module entity.EntityFieldInfo;

import entity;

class EntityFieldInfo : EntityExpression{

    private string _fileldName;
    private Variant _fieldValue;
    protected string _joinColumn;
    
    

    public this(string fileldName, string columnName, Variant fieldValue, string tableName) {
        super(columnName, tableName);
        _fileldName = fileldName;
        _fieldValue = fieldValue;
        
    }
    
    // need override those functions
    // public R deSerialize(R)(string data){};
    // public void assertType(T)() {}

    
    public Variant getFieldValue() {return _fieldValue;}
    public string getFileldName() {return _fileldName;}
    public string getJoinColumn() {return _joinColumn;}

    

}