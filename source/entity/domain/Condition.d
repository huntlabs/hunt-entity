module entity.domain.Condition;

import entity;
import std.format;

import std.array;

class Condition
{
    this(A ...)(A  args)
    {
        auto strings = appender!string();
		formattedWrite(strings, args);
		_str = strings.data;
    }


    Predicate toPredicate()
    {
        auto p = new Predicate();
        p._str = _str;
        return p;
    }
     
    private string _str;   
}