module Model.UserApp;

import hunt.entity;


@Table("UserApp")
class UserApp  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    int uid;
    int appid;

}
