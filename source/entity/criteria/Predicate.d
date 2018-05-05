/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
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
    Predicate betweenValue(string key, string c1, string c2) {
        _str = " "~key~" BETWEEN "~c1~" AND "~c2;
        return this;
    }
    Predicate In(T...)(T args) {
        foreach(k,v; args) {
            if (k == 0) {
                _str ~= " " ~ v ~ " IN (";
            }
            else {
                _str ~= " \"" ~ v~"\"";
                if (k == args.length - 1) {
                    _str ~= ")";
                }
                else {
                    _str ~= ",";
                }
            }
        }
        return this;
    }

    override string toString()
    {
        return _str;
    }
}
