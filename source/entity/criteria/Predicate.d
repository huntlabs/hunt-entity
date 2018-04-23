
module entity.criteria.Predicate;

class Predicate {

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

    Predicate orValue(T...)(T args) {
        _str ~= " ( ";
        foreach(k,v;args) {
            _str ~= v.toString();
            if (k != args.length - 1)
                _str ~= " OR ";
        } 
        _str ~= " ) ";
        return this;
    }  

    


    override string toString()
    {
        return _str;
    }
}