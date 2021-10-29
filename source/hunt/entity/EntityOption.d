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

module hunt.entity.EntityOption;

class EntityOption
{
    struct DatabaseOptions
    {
        string driver = "postgresql";
        string host = "localhost";
        ushort port = 5432;
        string database = "test";
        string username = "root";
        string password = "";
        string charset = "utf8";
        string prefix = "";

        string url()
        {
            import std.format;

            return format("%s://%s:%s@%s:%d/%s?prefix=%s&charset=%s", driver, username, password, host, port, database, prefix, charset);
        }
    }

    struct DatabasePoolOptions
    {
        int minIdle = 5;
        int idleTimeout = 30000;
        int maxPoolSize = 20;
        int minPoolSize = 5;
        int maxLifetime = 2000000;
        int connectionTimeout = 30000;
        int maxConnection = 20;
        int minConnection = 5;
        int maxWaitQueueSize = -1;
    }

    DatabaseOptions database;
    DatabasePoolOptions pool;
}
