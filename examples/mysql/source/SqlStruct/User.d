
module SqlStruct.User;
import SqlStruct.Blog;

import entity;


@Table("user")
class User {
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;

    string name;

    double money;
    string email;
    
    bool status;

    @OneToMany("user")
    Blog[] blogs;


}