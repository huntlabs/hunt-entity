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

module hunt.entity.eql.EqlCache;

import std.array;
import std.string;
import core.sync.rwmutex;
import std.digest.md;
import hunt.collection;
import hunt.logging;
import std.uni;

class EqlCacheManager
{

    string get(string eql)
    {
        synchronized (_mutex.reader)
        {
            auto key = cast(string)toLower(toHexString(md5Of(eql)));
            // logDebug(" Eql cache try hit eql ( %s , %s ) ".format(eql,key));
            if(_cacheMap.containsKey(key))
                return _cacheMap.get(key);
            else
                return null;
        }

    }

    void put(string eql, string parsedEql)
    {
        _mutex.writer.lock();
        scope (exit)
            _mutex.writer.unlock();

        auto key = cast(string)toLower(toHexString(md5Of(eql)));
        auto isHave = _cacheMap.containsKey(key);
        if (!isHave)
        {
            if(_cacheMap.size() >= MAX_TREE_MAP)
            {
                int cnt = 100;
                string[] keys;
                foreach(k , v; _cacheMap) {
                    if(cnt-- > 0)
                    {
                        keys ~= k;
                    }
                }
                foreach(k; keys)
                {
                    _cacheMap.remove(k);
                }
            }            

            _cacheMap.put(key , parsedEql);
            // logDebug(" Eql cache Map ( %s ) ".format(_cacheMap));
        }
    }

private:
    this()
    {
        _mutex = new ReadWriteMutex();
        _cacheMap = new HashMap!(string,string)();
    }

    ~this()
    {
        _mutex.destroy;
    }

    HashMap!(string, string) _cacheMap;

    ReadWriteMutex _mutex;

    enum MAX_TREE_MAP = 1000;
}

@property EqlCacheManager eqlCache()
{
    return _eqlcache;
}

shared static this()
{
    _eqlcache = new EqlCacheManager();
}

private:
__gshared EqlCacheManager _eqlcache;
