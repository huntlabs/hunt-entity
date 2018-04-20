
module entity.criteria.Predicate;

class Predicate {

    private string _key;
    private string _op;
    private string _value;

    string _str;

    this () {

    }

    Predicate addValue(string key,string op,string value) {
        _str ~= key ~ " " ~ op ~ " " ~ value;
        return this;
    }
    
    Predicate andValue(T...)(T args) {
        _str ~= " ( ";
        foreach(k,v;args) {
            _str ~= v.toString();
            if (k != args.length - 1)
                _str ~= " AND ";
        } 
        _str ~= " ) ";
        return this;
    }


    override string toString()
    {
        return _str;
    }
}